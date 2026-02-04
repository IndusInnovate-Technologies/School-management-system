"""
Models for student_parent app - API layer for App 4
"""
import uuid
from django.db import models
from django.core.exceptions import ValidationError
from main_login.models import User
from management_admin.models import Student
from teacher.models import Class, Attendance, Assignment, Exam, Grade, Timetable, StudyMaterial


class Parent(models.Model):
    """Parent model"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='parent_profile')
    students = models.ManyToManyField(Student, related_name='parents')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    phone = models.CharField(max_length=20)
    address = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id and school_name from first student's school"""
        # Only check students if parent already exists (has pk) to avoid accessing related objects before save
        if self.pk and self.students.exists():
            first_student = self.students.first()
            if first_student and first_student.school:
                if not self.school_id or self.school_id != first_student.school.school_id:
                    self.school_id = first_student.school.school_id
                if not self.school_name or self.school_name != first_student.school.school_name:
                    self.school_name = first_student.school.school_name
        super().save(*args, **kwargs)
    
    def __str__(self):
        # Use first_name + last_name if available, otherwise use username or email
        if self.user.first_name and self.user.last_name:
            return f"{self.user.first_name} {self.user.last_name}"
        elif self.user.first_name:
            return self.user.first_name
        else:
            return self.user.username or self.user.email
    
    class Meta:
        db_table = 'parents'
        verbose_name = 'Parent'
        verbose_name_plural = 'Parents'
        ordering = ['-created_at']


class Notification(models.Model):
    """Notification model for students/parents"""
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(
        max_length=50,
        choices=[
            ('attendance', 'Attendance'),
            ('assignment', 'Assignment'),
            ('exam', 'Exam'),
            ('grade', 'Grade'),
            ('general', 'General'),
        ],
        default='general'
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id from recipient's school"""
        if not self.school_id and self.recipient:
            # Try to get school_id from recipient's student profile
            try:
                student = Student.objects.filter(user=self.recipient).first()
                if student and student.school:
                    self.school_id = student.school.school_id
            except Exception:
                pass
            # Try to get school_id from recipient's parent profile
            if not self.school_id:
                try:
                    parent = Parent.objects.filter(user=self.recipient).first()
                    if parent and parent.students.exists():
                        first_student = parent.students.first()
                        if first_student and first_student.school:
                            self.school_id = first_student.school.school_id
                except Exception:
                    pass
        super().save(*args, **kwargs)
    
    class Meta:
        db_table = 'notifications'
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'
        ordering = ['-created_at']


class Fee(models.Model):
    """Fee model"""
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='fees')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_date = models.DateField()
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('paid', 'Paid'),
            ('overdue', 'Overdue'),
        ],
        default='pending'
    )
    payment_date = models.DateField(null=True, blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id from student's school"""
        if self.student and self.student.school and not self.school_id:
            self.school_id = self.student.school.school_id
        super().save(*args, **kwargs)
    
    class Meta:
        db_table = 'fees'
        verbose_name = 'Fee'
        verbose_name_plural = 'Fees'
        ordering = ['-due_date']


class Communication(models.Model):
    """Communication model between teachers and parents/students"""
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_messages'
    )
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_messages'
    )
    subject = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id from sender or recipient's school and validate matching school_id"""
        from main_login.utils import get_user_school_id
        from django.core.exceptions import ValidationError
        
        # Get school_id for both sender and recipient
        sender_school_id = get_user_school_id(self.sender)
        recipient_school_id = get_user_school_id(self.recipient)
        
        # Validate that sender and recipient have matching school_id
        if sender_school_id and recipient_school_id:
            if sender_school_id != recipient_school_id:
                raise ValidationError(
                    f'Cannot send message: Sender and recipient must belong to the same school. '
                    f'Sender school: {sender_school_id}, Recipient school: {recipient_school_id}'
                )
            # Use the matching school_id
            self.school_id = sender_school_id
        elif sender_school_id:
            # If only sender has school_id, use it
            self.school_id = sender_school_id
        elif recipient_school_id:
            # If only recipient has school_id, use it
            self.school_id = recipient_school_id
        else:
            # If neither has school_id, try to populate from sender
            if not self.school_id:
                # Try to get school_id from sender's school
                if self.sender:
                    try:
                        from management_admin.models import Teacher
                        teacher = Teacher.objects.filter(user=self.sender).first()
                        if teacher:
                            if teacher.school_id:
                                self.school_id = teacher.school_id
                            elif teacher.department and teacher.department.school:
                                self.school_id = teacher.department.school.school_id
                    except Exception:
                        pass
                # If not found, try recipient
                if not self.school_id and self.recipient:
                    try:
                        student = Student.objects.filter(user=self.recipient).first()
                        if student and student.school:
                            self.school_id = student.school.school_id
                    except Exception:
                        pass
                    # Try parent
                    if not self.school_id:
                        try:
                            parent = Parent.objects.filter(user=self.recipient).first()
                            if parent:
                                if parent.school_id:
                                    self.school_id = parent.school_id
                                elif parent.students.exists():
                                    first_student = parent.students.first()
                                    if first_student and first_student.school:
                                        self.school_id = first_student.school.school_id
                        except Exception:
                            pass
        super().save(*args, **kwargs)
    
    class Meta:
        db_table = 'communications'
        verbose_name = 'Communication'
        verbose_name_plural = 'Communications'
        ordering = ['-created_at']


class ChatGroup(models.Model):
    """Group model for group chat functionality"""
    group_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_groups'
    )
    members = models.ManyToManyField(
        User,
        related_name='chat_groups'
    )
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True)
    school_name = models.CharField(max_length=255, null=True, blank=True)
    
    # Optional filtering fields
    class_name = models.CharField(max_length=50, blank=True, null=True)
    grade = models.CharField(max_length=50, blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name

    class Meta:
        db_table = 'chat_groups'
        verbose_name = 'Chat Group'
        verbose_name_plural = 'Chat Groups'
        ordering = ['-created_at']


class ChatMessage(models.Model):
    """Chat message model for real-time messaging with support for text, images, and files"""
    
    MESSAGE_TYPE_CHOICES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('file', 'File'),
        ('video', 'Video'),
        ('system', 'System'),
    ]
    
    message_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_chat_messages',
        help_text='User who sent the message'
    )
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_chat_messages',
        null=True,
        blank=True,
        help_text='User who receives the message (null for group messages)'
    )
    group = models.ForeignKey(
        ChatGroup,
        on_delete=models.CASCADE,
        related_name='messages',
        null=True,
        blank=True,
        help_text='Group that receives the message (null for 1-to-1 messages)'
    )
    
    # Descriptive label for database visibility
    conversation_label = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text='Human-readable label showing who is chatting (e.g., "Hari (Class 5-B) ↔ Sushil (Class 6-A)" or "Group: Study Group")'
    )
    
    # Reply functionality
    replied_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='replies',
        help_text='Message this is replying to (null if not a reply)'
    )
    school_id = models.CharField(
        max_length=100, 
        db_index=True, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School ID for filtering (read-only, fetched from users table)'
    )
    school_name = models.CharField(
        max_length=255, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School name (read-only, auto-populated from schools table)'
    )
    
    # Message content
    message_type = models.CharField(
        max_length=20,
        choices=MESSAGE_TYPE_CHOICES,
        default='text',
        help_text='Type of message: text, image, file, or video'
    )
    message_text = models.TextField(
        null=True,
        blank=True,
        help_text='Text content of the message (required for text messages)'
    )
    
    # File/Image attachment
    attachment = models.FileField(
        upload_to='chat_attachments/%Y/%m/%d/',
        null=True,
        blank=True,
        help_text='Attached file, image, or video'
    )
    attachment_name = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        help_text='Original filename of the attachment'
    )
    attachment_size = models.IntegerField(
        null=True,
        blank=True,
        help_text='File size in bytes'
    )
    attachment_type = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text='MIME type of the attachment (e.g., image/jpeg, application/pdf)'
    )
    
    # Message metadata
    is_read = models.BooleanField(
        default=False,
        help_text='Whether the recipient has read this message'
    )
    read_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when the message was read'
    )
    is_deleted = models.BooleanField(
        default=False,
        help_text='Soft delete flag - message is marked as deleted but kept in database'
    )
    deleted_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when the message was deleted'
    )
    is_edited = models.BooleanField(
        default=False,
        help_text='Flag to indicate if the message has been edited'
    )
    edited_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when the message was last edited'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id, school_name, and attachment metadata"""
        from main_login.utils import get_user_school_id, get_user_school
        
        # Validate message content based on type
        if self.message_type == 'text' and not self.message_text:
            raise ValidationError('Text messages must have message_text content')
        
        if self.message_type in ['image', 'file', 'video'] and not self.attachment:
            raise ValidationError(f'{self.message_type.capitalize()} messages must have an attachment')
        
        # Validate destination
        if not self.recipient and not self.group:
            raise ValidationError('Message must have either a recipient or a group')
        
        # Get school_id from sender
        sender_school_id = get_user_school_id(self.sender)
        
        # If group message, use group's school_id
        if self.group:
            if self.group.school_id:
                self.school_id = self.group.school_id
            else:
                self.school_id = sender_school_id
        # If 1-to-1 message, validate matching school_id
        elif self.recipient:
            recipient_school_id = get_user_school_id(self.recipient)
            if sender_school_id and recipient_school_id:
                if sender_school_id != recipient_school_id:
                    raise ValidationError(
                        f'Cannot send message: Sender and recipient must belong to the same school. '
                        f'Sender school: {sender_school_id}, Recipient school: {recipient_school_id}'
                    )
                self.school_id = sender_school_id
            elif sender_school_id:
                self.school_id = sender_school_id
            elif recipient_school_id:
                self.school_id = recipient_school_id
        
        # Get school name
        school = get_user_school(self.sender)
        if school:
            self.school_name = school.school_name
        
        # Auto-populate conversation_label for database visibility
        if self.group:
            # Group message
            self.conversation_label = f"Group: {self.group.name}"
        elif self.recipient:
            # 1-to-1 message - get participant details
            sender_name = f"{self.sender.first_name} {self.sender.last_name}".strip() or self.sender.username
            recipient_name = f"{self.recipient.first_name} {self.recipient.last_name}".strip() or self.recipient.username
            
            # Try to get class and section info
            sender_class_info = ""
            recipient_class_info = ""
            
            try:
                # Check if sender is a student
                from management_admin.models import Student
                student = Student.objects.filter(user=self.sender).first()
                if student and student.class_obj:
                    sender_class_info = f" ({student.class_obj.name}-{student.class_obj.section})"
            except:
                pass
            
            try:
                # Check if recipient is a student
                from management_admin.models import Student
                student = Student.objects.filter(user=self.recipient).first()
                if student and student.class_obj:
                    recipient_class_info = f" ({student.class_obj.name}-{student.class_obj.section})"
            except:
                pass
            
            self.conversation_label = f"{sender_name}{sender_class_info} ↔ {recipient_name}{recipient_class_info}"
        
        # Auto-populate attachment metadata if attachment is provided
        if self.attachment:
            import os
            import mimetypes
            
            if not self.attachment_name:
                self.attachment_name = os.path.basename(self.attachment.name)
            
            if not self.attachment_size:
                try:
                    self.attachment_size = self.attachment.size
                except:
                    pass
            
            if not self.attachment_type:
                # Try to detect MIME type
                mime_type, _ = mimetypes.guess_type(self.attachment.name)
                if mime_type:
                    self.attachment_type = mime_type
                else:
                    # Fallback based on file extension
                    ext = os.path.splitext(self.attachment.name)[1].lower()
                    if ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp']:
                        self.attachment_type = 'image/' + ext.lstrip('.')
                    elif ext in ['.pdf']:
                        self.attachment_type = 'application/pdf'
                    elif ext in ['.doc', '.docx']:
                        self.attachment_type = 'application/msword'
                    elif ext in ['.mp4', '.avi', '.mov']:
                        self.attachment_type = 'video/' + ext.lstrip('.')
                    else:
                        self.attachment_type = 'application/octet-stream'
        
        super().save(*args, **kwargs)
    
    def mark_as_read(self):
        """Mark the message as read"""
        if not self.is_read:
            from django.utils import timezone
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    def soft_delete(self):
        """Soft delete the message"""
        if not self.is_deleted:
            from django.utils import timezone
            self.is_deleted = True
            self.deleted_at = timezone.now()
            self.save(update_fields=['is_deleted', 'deleted_at'])
    
    @property
    def attachment_url(self):
        """Get the URL for the attachment if it exists"""
        if self.attachment:
            return self.attachment.url
        return None
    
    @property
    def is_image(self):
        """Check if the message contains an image"""
        return self.message_type == 'image' or (
            self.attachment_type and self.attachment_type.startswith('image/')
        )
    
    @property
    def is_video(self):
        """Check if the message contains a video"""
        return self.message_type == 'video' or (
            self.attachment_type and self.attachment_type.startswith('video/')
        )
    
    @property
    def is_file(self):
        """Check if the message contains a file (non-image, non-video)"""
        return self.message_type == 'file' or (
            self.attachment_type and 
            not self.attachment_type.startswith('image/') and 
            not self.attachment_type.startswith('video/')
        )
    
    def __str__(self):
        sender_name = f"{self.sender.first_name} {self.sender.last_name}".strip() or self.sender.username
        recipient_name = f"{self.recipient.first_name} {self.recipient.last_name}".strip() or self.recipient.username
        
        if self.message_type == 'text':
            preview = (self.message_text[:50] + '...') if self.message_text and len(self.message_text) > 50 else (self.message_text or '')
        else:
            preview = f"[{self.get_message_type_display()}] {self.attachment_name or 'No file'}"
        
        return f"{sender_name} -> {recipient_name}: {preview}"
    
    class Meta:
        db_table = 'chat_messages'
        verbose_name = 'Chat Message'
        verbose_name_plural = 'Chat Messages'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['sender', 'recipient', 'created_at']),
            models.Index(fields=['school_id', 'created_at']),
            models.Index(fields=['is_read', 'created_at']),
        ]

