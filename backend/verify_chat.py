
import os
import django
import sys

# Setup Django
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User
from student_parent.models import ChatMessage, ChatGroup
from student_parent.serializers import ChatMessageSerializer
from rest_framework.test import APIRequestFactory

def verify_chat():
    print("--- Verifying Chat Backend ---")
    
    # 1. List Users
    users = User.objects.all()[:5]
    if len(users) < 2:
        print("Not enough users to test chat.")
        return

    sender = users[0]
    recipient = users[1]
    
    print(f"Sender: {sender.username} (ID: {sender.user_id})")
    print(f"Recipient: {recipient.username} (ID: {recipient.user_id})")
    
    # 2. Test Serializer Validation
    print("\n--- Testing Serializer Validation ---")
    data = {
        'message_text': 'Test message from script',
        'message_type': 'text',
        'recipient': recipient.username # This is how frontend sends it to ViewSet logic, but Serializer expects ID or Object if passed directly?
        # Actually ViewSet handles recipient lookup. Serializer takes 'recipient' as ReadOnly field usually?
        # Let's check serializer fields.
    }
    
    # In ViewSet perform_create:
    # 1. Recipient lookup happened manually.
    # 2. serializer.save(sender=..., recipient=...) is called.
    
    # So we should simulate ViewSet logic:
    serializer = ChatMessageSerializer(data=data)
    if serializer.is_valid():
        print("Serializer is valid.")
        try:
            # Simulate perform_create
            instance = serializer.save(
                sender=sender,
                recipient=recipient,
                group=None,
                message_type='text'
            )
            print(f"Message Saved! ID: {instance.message_id}")
            print(f"Text: {instance.message_text}")
        except Exception as e:
            print(f"Error saving message: {e}")
    else:
        print(f"Serializer Invalid: {serializer.errors}")

    # 3. Verify Database
    print("\n--- Verifying Database ---")
    msg = ChatMessage.objects.filter(sender=sender, recipient=recipient).last()
    if msg:
        print(f"Found message in DB: {msg.message_text} at {msg.created_at}")
    else:
        print("Message NOT found in DB!")

if __name__ == '__main__':
    verify_chat()
