import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from student_parent.models import Communication, ChatMessage
from django.utils import timezone

User = get_user_model()

class TeacherStudentChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        # Extract room_id from URL and URL-decode it
        from urllib.parse import unquote
        raw_room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_id = unquote(raw_room_id)  # Decode URL-encoded characters like %40 (@)
        
        # Determine chat_type from URL path
        url_path = self.scope.get('path', '')
        if 'teacher-student' in url_path:
            chat_type = 'teacher-student'
        elif 'teacher-parent' in url_path:
            chat_type = 'teacher-parent'
        elif 'group' in url_path:
            chat_type = 'group'
        else:
            chat_type = 'teacher-student'  # default
        
        # For group chats, use group_<room_id> format
        if chat_type == 'group':
            self.group_name = f'group_{self.room_id}'
        else:
            self.group_name = f'{chat_type}_{self.room_id}'
        
        # Get authenticated user
        self.user = self.scope.get('user')
        
        if not self.user or not self.user.is_authenticated:
            await self.close()
            return
        
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        
        # Subscribe to personal channel for global updates (like WhatsApp)
        if self.user and self.user.is_authenticated:
            self.personal_group_name = f'user_{self.user.user_id}'
            await self.channel_layer.group_add(self.personal_group_name, self.channel_name)
            
        await self.accept()
        
        # Send connection confirmation
        await self.send(text_data=json.dumps({
            'type': 'connection',
            'message': 'Connected to chat',
            'user': self.user.username
        }))

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)
        if hasattr(self, 'personal_group_name'):
             await self.channel_layer.group_discard(self.personal_group_name, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None):
        if not self.user or not self.user.is_authenticated:
            return
            
        try:
            data = json.loads(text_data or '{}')
            message_text = data.get('message', '').strip()
            recipient_username = data.get('recipient', '').strip()
            
            if not message_text:
                return
            
            # If recipient is provided, save to database
            recipient = None
            group = None
            chat_message = None
            
            # Check if this is a group message
            group_id = data.get('group_id', '').strip()
            if group_id:
                # Group message
                group = await self.get_group_by_id(group_id)
                if group:
                    chat_message = await self.save_group_message(self.user, group, message_text)
                else:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f'Group not found: {group_id}')
            elif recipient_username:
                # 1-to-1 message
                recipient = await self.get_user_by_username(recipient_username)
                if recipient:
                    chat_message = await self.save_message(self.user, recipient, message_text)
                else:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f'Recipient not found: {recipient_username}')
            
            # Get sender's display name (first_name + last_name or username)
            # Always use the authenticated user's info, ignore sender from frontend
            sender_name = self.user.username
            if self.user.first_name or self.user.last_name:
                sender_name = f"{self.user.first_name or ''} {self.user.last_name or ''}".strip()
                if not sender_name:  # If stripped result is empty, use username
                    sender_name = self.user.username
            
            # Broadcast to group/personal channels
            broadcast_payload = {
                'type': 'chat.message',
                'sender': sender_name,
                'sender_username': self.user.username,
                'sender_id': str(self.user.user_id),
                'message': message_text,
                'timestamp': data.get('timestamp', timezone.now().isoformat()),
                'message_id': str(chat_message.message_id) if chat_message else '',
            }
            
            # 1. Send to the current room (for people explicitly watching this chat)
            await self.channel_layer.group_send(self.group_name, broadcast_payload)
            
            # 2. Add group or recipient info for personal broadcast
            if group:
                broadcast_payload['group_id'] = str(group.group_id)
                broadcast_payload['group_name'] = group.name
                
                # Fetch all members to broadcast to their personal channels
                members_ids = await self.get_group_member_ids(group)
                for member_id in members_ids:
                    # Don't send back to sender via personal channel (redundant)
                    if member_id != self.user.user_id:
                        await self.channel_layer.group_send(f'user_{member_id}', broadcast_payload)
                        
            else:
                broadcast_payload['recipient'] = recipient_username or ''
                broadcast_payload['recipient_id'] = str(recipient.user_id) if recipient else ''
                
                # Send to recipient's personal channel
                if recipient:
                    await self.channel_layer.group_send(f'user_{recipient.user_id}', broadcast_payload)
                
                # Send to sender's personal channel (for multi-device sync)
                await self.channel_layer.group_send(f'user_{self.user.user_id}', broadcast_payload)

        except json.JSONDecodeError:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': 'Invalid message format'
            }))
        except Exception as e:
            await self.send(text_data=json.dumps({
                'type': 'error',
                'message': str(e)
            }))

    async def chat_message(self, event):
        """Send message to WebSocket"""
        payload = {
            'type': 'message',
            'sender': event['sender'],
            'sender_name': event.get('sender_name', event['sender']),
            'sender_username': event.get('sender_username', event['sender']),
            'sender_id': event.get('sender_id'),
            'message': event['message'],
            'message_type': event.get('message_type', 'text'),
            'timestamp': event.get('timestamp', ''),
            'message_id': event.get('message_id', ''),
            'attachment_url': event.get('attachment_url'),
            'attachment_name': event.get('attachment_name'),
            'replied_to_id': event.get('replied_to_id'),
            'replied_to_sender_name': event.get('replied_to_sender_name'),
            'replied_to_text': event.get('replied_to_text'),
        }
        
        # Add group or recipient info
        if 'group_id' in event:
            payload['group_id'] = event['group_id']
            payload['group_name'] = event.get('group_name', '')
        else:
            payload['recipient'] = event.get('recipient', '')
            payload['recipient_id'] = event.get('recipient_id', '')
        
        await self.send(text_data=json.dumps(payload))

    async def chat_message_edited(self, event):
        """Handle message edited broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'message_edited',
            'message_id': event['message_id'],
            'message': event['message'],
            'timestamp': event['timestamp'],
            'sender_id': event['sender_id'],
        }))

    async def chat_message_deleted(self, event):
        """Handle message deleted broadcast"""
        await self.send(text_data=json.dumps({
            'type': 'message_deleted',
            'message_id': event['message_id'],
            'sender_id': event['sender_id'],
        }))

    async def chat_messages_read(self, event):
        """Handle read receipt broadcast (WhatsApp-like double tick) - notify sender that messages were read"""
        payload = {
            'type': 'chat.messages_read',
            'read_by_user_id': event.get('read_by_user_id', ''),
        }
        if event.get('group_id'):
            payload['group_id'] = event['group_id']
        await self.send(text_data=json.dumps(payload))

    async def chat_group_updated(self, event):
        """Handle group name/members update so participants see changes (like WhatsApp)"""
        await self.send(text_data=json.dumps({
            'type': 'chat.group_updated',
            'group_id': event.get('group_id', ''),
            'group_name': event.get('group_name', ''),
            'updated_type': event.get('updated_type', ''),
            'member_ids': event.get('member_ids', []),
        }))

    @database_sync_to_async
    def get_user_by_username(self, username_or_name):
        """Get user by username, email, or name (first_name + last_name)"""
        try:
            # First try username
            try:
                return User.objects.get(username=username_or_name)
            except User.DoesNotExist:
                pass
            
            # Then try email
            try:
                return User.objects.get(email=username_or_name)
            except User.DoesNotExist:
                pass
            
            # Finally try by name (first_name + last_name)
            # Split name into parts
            name_parts = username_or_name.split('_')  # Handle normalized names
            if len(name_parts) >= 2:
                # Try to find by first_name and last_name
                first_name = name_parts[0].capitalize()
                last_name = name_parts[1].capitalize()
                user = User.objects.filter(
                    first_name__iexact=first_name,
                    last_name__iexact=last_name
                ).first()
                if user:
                    return user
            
            # If name has space, try splitting by space
            if ' ' in username_or_name:
                name_parts = username_or_name.split(' ', 2)
                if len(name_parts) >= 2:
                    first_name = name_parts[0].strip().capitalize()
                    last_name = name_parts[1].strip().capitalize()
                    user = User.objects.filter(
                        first_name__iexact=first_name,
                        last_name__iexact=last_name
                    ).first()
                    if user:
                        return user
            
            return None
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f'Error looking up user by {username_or_name}: {str(e)}')
            return None

    @database_sync_to_async
    def save_message(self, sender, recipient, message):
        """Save message to ChatMessage model for real-time chat (WhatsApp/Telegram-like)"""
        from main_login.utils import get_user_school_id
        
        # Get school_id for both sender and recipient
        sender_school_id = get_user_school_id(sender)
        recipient_school_id = get_user_school_id(recipient)
        
        # Validate that sender and recipient have matching school_id
        if sender_school_id and recipient_school_id:
            if sender_school_id != recipient_school_id:
                raise ValueError(
                    f'Cannot send message: Sender and recipient must belong to the same school. '
                    f'Sender school: {sender_school_id}, Recipient school: {recipient_school_id}'
                )
        
        # Save message to ChatMessage model (designed for real-time chat)
        chat_message = ChatMessage.objects.create(
            sender=sender,
            recipient=recipient,
            message_type='text',
            message_text=message,
            is_read=False
        )
        
        # Also save to Communication model for backward compatibility
        try:
            Communication.objects.create(
                sender=sender,
                recipient=recipient,
                subject=f'Chat: {sender.username} to {recipient.username}',
                message=message,
                is_read=False
            )
        except Exception as e:
            # If Communication save fails, log but don't fail the chat message
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f'Failed to save to Communication model: {str(e)}')
        
        return chat_message
    
    @database_sync_to_async
    def get_group_by_id(self, group_id):
        """Get group by ID"""
        try:
            from student_parent.models import ChatGroup
            return ChatGroup.objects.get(group_id=group_id)
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f'Error looking up group by {group_id}: {str(e)}')
            return None
    
    @database_sync_to_async
    def save_group_message(self, sender, group, message):
        """Save group message to ChatMessage model"""
        chat_message = ChatMessage.objects.create(
            sender=sender,
            group=group,
            message_type='text',
            message_text=message,
            is_read=False
        )
        return chat_message

    @database_sync_to_async
    def get_group_member_ids(self, group):
        """Get all member user IDs for a group"""
        return list(group.members.values_list('id', flat=True))
        return chat_message