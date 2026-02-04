"""
Serializers for student_parent app
"""
from rest_framework import serializers
from .models import Parent, Notification, Fee, Communication, ChatMessage, ChatGroup
from main_login.serializer_mixins import SchoolIdMixin
from main_login.serializers import UserSerializer
from management_admin.serializers import TeacherSerializer, StudentSerializer, DepartmentSerializer
from teacher.serializers import ProjectSerializer
from teacher.models import StudentProject, Project


class ParentSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Parent model"""
    user = UserSerializer(read_only=True)
    students = StudentSerializer(many=True, read_only=True)
    school_id = serializers.SerializerMethodField()
    school_name = serializers.SerializerMethodField()
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Parent
        fields = [
            'id', 'school_id', 'school_name', 'logo_url', 'user', 'students', 'phone', 'address',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_school_id(self, obj):
        """Get school_id from model or compute from students"""
        # First try to get from model field
        if obj.school_id:
            return obj.school_id
        
        # If not available, try to get from first student's school
        # Use select_related to optimize database queries
        students = obj.students.all().select_related('school')
        for student in students:
            if student and student.school:
                # Log for debugging
                import logging
                logger = logging.getLogger(__name__)
                logger.debug(f"Parent {obj.id}: Found school_id {student.school.school_id} from student {student.email}")
                return student.school.school_id
        
        # Log warning if no school found
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Parent {obj.id}: No school_id found. Students count: {obj.students.count()}")
        return None
    
    def get_school_name(self, obj):
        """Get school_name from model or compute from students"""
        # First try to get from model field
        if obj.school_name:
            return obj.school_name
        
        # If not available, try to get from first student's school
        # Use select_related to optimize database queries
        students = obj.students.all().select_related('school')
        for student in students:
            if student and student.school:
                import logging
                logger = logging.getLogger(__name__)
                logger.debug(f"Parent {obj.id}: Found school_name {student.school.school_name} from student {student.email}")
                return student.school.school_name
        
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"Parent {obj.id}: No school_name found. Students count: {obj.students.count()}")
        return None

    def get_logo_url(self, obj):
        """Get school logo URL directly in profile"""
        # Try to find school via students
        from super_admin.models import School
        
        # Priority 1: Direct school_id on parent
        if obj.school_id:
            school = School.objects.filter(school_id=obj.school_id).first()
            if school and school.logo:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(school.logo.url)
                return school.logo.url
        
        # Priority 2: From students
        students = obj.students.all().select_related('school')
        for student in students:
            if student and student.school and student.school.logo:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(student.school.logo.url)
                return student.school.logo.url
        return None


class NotificationSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Notification model"""
    recipient = UserSerializer(read_only=True)
    
    class Meta:
        model = Notification
        fields = [
            'id', 'school_id', 'recipient', 'title', 'message', 'notification_type',
            'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class FeeSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Fee model"""
    student = StudentSerializer(read_only=True)
    
    class Meta:
        model = Fee
        fields = [
            'id', 'school_id', 'student', 'amount', 'due_date', 'status',
            'payment_date', 'description', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CommunicationSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Communication model"""
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    
    class Meta:
        model = Communication
        fields = [
            'id', 'school_id', 'sender', 'recipient', 'subject', 'message',
            'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class ChatGroupSummarySerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Simplified serializer for ChatGroup to avoid circular dependencies"""
    class Meta:
        model = ChatGroup
        fields = ['group_id', 'name', 'class_name', 'grade', 'school_id', 'school_name']


class ChatGroupSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for ChatGroup model"""
    created_by = UserSerializer(read_only=True)
    members = UserSerializer(many=True, read_only=True)
    member_ids = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False
    )
    member_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    created_by_name = serializers.ReadOnlyField(source='created_by.username')

    
    class Meta:
        model = ChatGroup
        fields = [
            'group_id', 'name', 'description', 'created_by', 'created_by_name', 'members', 'member_ids',
            'member_count', 'last_message', 'unread_count', 'school_id', 'school_name', 'class_name', 'grade',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['group_id', 'school_id', 'school_name', 'created_at', 'updated_at']
    
    def get_member_count(self, obj):
        """Get count of members in the group"""
        return obj.members.count()
    
    def get_last_message(self, obj):
        """Get the latest message in this group"""
        # Use prefetched messages to avoid additional queries
        messages = [msg for msg in obj.messages.all() if not msg.is_deleted]
        if messages:
            # Messages are already ordered by -created_at from prefetch
            last_msg = messages[0]
            # Return simplified data to avoid nested serialization overhead
            sender_name = f"{last_msg.sender.first_name} {last_msg.sender.last_name}".strip() if last_msg.sender else "Unknown"
            if not sender_name or sender_name == "Unknown":
                sender_name = last_msg.sender.username if last_msg.sender else "Unknown"
            
            return {
                'message_id': str(last_msg.message_id),
                'sender_name': sender_name,
                'message_text': last_msg.message_text,
                'message_type': last_msg.message_type,
                'created_at': last_msg.created_at.isoformat() if last_msg.created_at else None,
            }
        return None

    def get_unread_count(self, obj):
        """Get unread message count for the current user in this group"""
        request = self.context.get('request')
        if not request or not request.user:
            return 0
        
        # Use prefetched messages to avoid additional queries
        # Filter in Python instead of database for better performance with prefetch
        unread_count = sum(
            1 for msg in obj.messages.all()
            if not msg.is_deleted and not msg.is_read and msg.sender_id != request.user.user_id
        )
        return unread_count
    
    def create(self, validated_data):
        """Create group and add members"""
        import logging
        logger = logging.getLogger(__name__)
        
        member_ids = validated_data.pop('member_ids', [])
        logger.info(f"ChatGroupSerializer.create - Creating group with {len(member_ids)} member_ids: {member_ids}")
        
        group = ChatGroup.objects.create(**validated_data)
        logger.info(f"ChatGroupSerializer.create - Group created: {group.name} (ID: {group.group_id})")
        
        # Add members
        if member_ids:
            from main_login.models import User
            members = User.objects.filter(user_id__in=member_ids)
            member_count = members.count()
            logger.info(f"ChatGroupSerializer.create - Found {member_count} users from {len(member_ids)} IDs")
            
            group.members.set(members)
            logger.info(f"ChatGroupSerializer.create - Members set. Current member count: {group.members.count()}")
            
            # Log each member
            for member in group.members.all():
                logger.info(f"  - Member: {member.username} (ID: {member.user_id})")
        else:
            logger.warning(f"ChatGroupSerializer.create - No member_ids provided!")
        
        return group


class ChatMessageSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for ChatMessage model"""
    sender = UserSerializer(read_only=True)
    recipient = UserSerializer(read_only=True)
    group = ChatGroupSummarySerializer(read_only=True)
    group_id = serializers.UUIDField(write_only=True, required=False, allow_null=True)
    attachment_url = serializers.SerializerMethodField()
    attachment_size_mb = serializers.SerializerMethodField()
    sender_name = serializers.SerializerMethodField()
    replied_to_id = serializers.SerializerMethodField()
    replied_to_sender_name = serializers.SerializerMethodField()
    replied_to_text = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatMessage
        fields = [
            'message_id', 'school_id', 'school_name', 'sender', 'recipient', 'group', 'group_id',
            'sender_name', 'replied_to', 'replied_to_id', 'replied_to_sender_name', 'replied_to_text',
            'message_type', 'message_text', 'attachment', 'attachment_url',
            'attachment_name', 'attachment_size', 'attachment_size_mb',
            'attachment_type', 'is_read', 'read_at', 'is_deleted', 'deleted_at',
            'is_edited', 'edited_at',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'message_id', 'school_id', 'school_name', 'created_at', 'updated_at',
            'attachment_url', 'attachment_size_mb', 'read_at', 'deleted_at',
            'is_edited', 'edited_at'
        ]
    
    def get_attachment_url(self, obj):
        """Get the full URL for the attachment"""
        if obj.attachment:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.attachment.url)
            return obj.attachment.url
        return None
    
    def get_attachment_size_mb(self, obj):
        """Get file size in MB for display"""
        if obj.attachment_size:
            return round(obj.attachment_size / (1024 * 1024), 2)
        return None
    
    def get_sender_name(self, obj):
        """Display name for sender (for groups and reply display)"""
        if not obj.sender:
            return None
        name = f"{obj.sender.first_name or ''} {obj.sender.last_name or ''}".strip()
        return name or obj.sender.username
    
    def get_replied_to_id(self, obj):
        if not obj.replied_to:
            return None
        return str(obj.replied_to.message_id)
    
    def get_replied_to_sender_name(self, obj):
        if not obj.replied_to or not obj.replied_to.sender:
            return None
        s = obj.replied_to.sender
        name = f"{s.first_name or ''} {s.last_name or ''}".strip()
        return name or s.username
    
    def get_replied_to_text(self, obj):
        if not obj.replied_to:
            return None
        if obj.replied_to.is_deleted:
            return 'This message was deleted'
        return obj.replied_to.message_text or (f"[{obj.replied_to.attachment_name}]" if obj.replied_to.attachment_name else '[Attachment]')
    
    def validate(self, data):
        """Validate message content based on message type. Attachment may be in request.FILES (multipart)."""
        message_type = data.get('message_type', 'text')
        message_text = data.get('message_text')
        # Multipart: file is often in request.FILES, not in request.data
        request = self.context.get('request')
        attachment = data.get('attachment') or (request.FILES.get('attachment') if request else None)

        # Allow empty message_text when attachment is present (image/file-only messages)
        if message_type == 'text' and not message_text and not attachment and not self.instance:
            raise serializers.ValidationError({
                'message_text': 'Text messages must have message_text content'
            })

        if message_type in ['image', 'file', 'video'] and not attachment and not self.instance:
            raise serializers.ValidationError({
                'attachment': f'{message_type.capitalize()} messages must have an attachment'
            })

        return data

    def to_representation(self, instance):
        """Handle deleted message text placeholder"""
        ret = super().to_representation(instance)
        if instance.is_deleted:
            ret['message_text'] = 'This message was deleted'
            ret['attachment'] = None
            ret['attachment_url'] = None
            ret['attachment_name'] = None
        return ret


class StudentProjectViewSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for Student to view Projects - avoids nested serializer UUID issues.
    Uses SerializerMethodFields to fetch related data directly instead of nested serializers.
    """
    school_id = serializers.CharField(read_only=True)  # Explicit CharField to avoid UUID validation
    teacher_name = serializers.SerializerMethodField()
    teacher_email = serializers.SerializerMethodField()
    class_name = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    progress = serializers.SerializerMethodField()
    grade = serializers.SerializerMethodField()
    submission_date = serializers.SerializerMethodField()
    feedback = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = [
            'id', 'school_id', 'title', 'subject', 'description', 
            'due_date', 'file', 'created_at', 'updated_at',
            'teacher_name', 'teacher_email', 'class_name',
            'status', 'progress', 'grade', 'submission_date', 'feedback'
        ]
        read_only_fields = ['id', 'school_id', 'created_at', 'updated_at']

    def get_teacher_name(self, obj):
        """Get teacher name from related teacher object"""
        try:
            if obj.teacher:
                return obj.teacher.name
        except Exception:
            pass
        return None
    
    def get_teacher_email(self, obj):
        """Get teacher email from related user"""
        try:
            if obj.teacher and obj.teacher.user:
                return obj.teacher.user.email
        except Exception:
            pass
        return None
    
    def get_class_name(self, obj):
        """Get class name from related class object"""
        try:
            if obj.class_obj:
                return f"{obj.class_obj.name} - {obj.class_obj.section}" if obj.class_obj.section else obj.class_obj.name
        except Exception:
            pass
        return None

    def _get_student_project(self, project):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
            
        try:
            # Try to get student profile from user
            from management_admin.models import Student
            student = Student.objects.filter(user=request.user).first()
            
            if not student:
                return None
                
            # Get StudentProject record
            return StudentProject.objects.filter(
                project=project,
                student=student
            ).first()
        except Exception:
            return None

    def get_status(self, obj):
        sp = self._get_student_project(obj)
        return sp.status if sp else 'pending'
    
    def get_progress(self, obj):
        """Get student's project progress"""
        sp = self._get_student_project(obj)
        return sp.progress if sp else 0

    def get_grade(self, obj):
        sp = self._get_student_project(obj)
        return sp.grade if sp else None

    def get_submission_date(self, obj):
        sp = self._get_student_project(obj)
        return sp.submission_date if sp else None
        
    def get_feedback(self, obj):
        sp = self._get_student_project(obj)
        return sp.feedback if sp else None
