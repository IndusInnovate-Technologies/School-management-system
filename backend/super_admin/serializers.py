"""
Serializers for super_admin app
"""
from rest_framework import serializers
from .models import School, SchoolStats, Activity, SupportTicket, TicketReply, TicketAttachment
from main_login.serializers import UserSerializer


class SchoolStatsSerializer(serializers.ModelSerializer):
    """Serializer for School Statistics"""
    # Real-time counts calculated from database
    total_students = serializers.SerializerMethodField()
    total_teachers = serializers.SerializerMethodField()
    total_buses = serializers.SerializerMethodField()
    
    class Meta:
        model = SchoolStats
        fields = ['total_students', 'total_teachers', 'total_buses', 'total_revenue', 'updated_at']
    
    def get_total_students(self, obj):
        """Get real-time student count from database"""
        try:
            if obj and hasattr(obj, 'school') and obj.school:
                return obj.school.students.count()
        except Exception:
            pass
        return 0
    
    def get_total_teachers(self, obj):
        """Get real-time teacher count from database"""
        try:
            if obj and hasattr(obj, 'school') and obj.school:
                from management_admin.models import Teacher
                return Teacher.objects.filter(school_id=obj.school.school_id).count()
        except Exception:
            pass
        return 0
    
    def get_total_buses(self, obj):
        """Get real-time bus count from database"""
        try:
            if obj and hasattr(obj, 'school') and obj.school:
                return obj.school.buses.count()
        except Exception:
            pass
        return 0


class SchoolSerializer(serializers.ModelSerializer):
    """Serializer for School model"""
    stats = serializers.SerializerMethodField()
    generated_password = serializers.SerializerMethodField()
    user_id = serializers.UUIDField(source='user.user_id', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    logo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = School
        fields = [
            'school_id', 'school_name', 'location', 'statecode', 'districtcode', 'registration_number',
            'email', 'phone', 'address', 'principal_name', 'established_year', 'status',
            'license_expiry', 'logo', 'logo_url', 'user', 'user_id', 'username', 'stats', 'generated_password',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['school_id', 'user', 'user_id', 'username', 'created_at', 'updated_at', 'logo_url']
    
    def validate(self, data):
        """Validate that required fields for school_id generation are provided"""
        # Only validate on create (when school_id is not set)
        if not self.instance:  # This is a create operation
            statecode = data.get('statecode', '').strip() if data.get('statecode') else ''
            districtcode = data.get('districtcode', '').strip() if data.get('districtcode') else ''
            registration_number = data.get('registration_number', '').strip() if data.get('registration_number') else ''
            
            if not statecode:
                raise serializers.ValidationError({'statecode': 'State code is required to generate school_id'})
            if not districtcode:
                raise serializers.ValidationError({'districtcode': 'District code is required to generate school_id'})
            if not registration_number:
                raise serializers.ValidationError({'registration_number': 'Registration number is required to generate school_id'})
        
        return data
    
    def get_stats(self, obj):
        """Get or create SchoolStats and serialize it"""
        try:
            stats, created = SchoolStats.objects.get_or_create(school=obj)
            return SchoolStatsSerializer(stats).data
        except Exception:
            # Return default stats if there's an error
            return {
                'total_students': 0,
                'total_teachers': 0,
                'total_buses': 0,
                'total_revenue': '0.00',
                'updated_at': None
            }
    
    def get_generated_password(self, obj):
        """Get generated password from context (only available during creation)"""
        return self.context.get('generated_password', None)

    def get_logo_url(self, obj):
        """Get full URL for logo"""
        if obj.logo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.logo.url)
            return obj.logo.url
        return None


class ActivitySerializer(serializers.ModelSerializer):
    """Serializer for Activity model"""
    user = UserSerializer(read_only=True)
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    
    class Meta:
        model = Activity
        fields = [
            'id', 'user', 'school', 'school_name', 'activity_type',
            'description', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class TicketAttachmentSerializer(serializers.ModelSerializer):
    """Serializer for TicketAttachment model"""
    class Meta:
        model = TicketAttachment
        fields = ['id', 'file', 'created_at']


class TicketReplySerializer(serializers.ModelSerializer):
    """Serializer for TicketReply model"""
    sender_name = serializers.ReadOnlyField(source='sender.get_full_name')

    class Meta:
        model = TicketReply
        fields = [
            'id', 'ticket', 'sender', 'sender_name', 'sender_role',
            'message', 'attachment', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class SupportTicketSerializer(serializers.ModelSerializer):
    """Serializer for SupportTicket model"""
    school_name = serializers.ReadOnlyField(source='school.school_name')
    principal_name = serializers.ReadOnlyField(source='school.principal_name')
    school_email = serializers.ReadOnlyField(source='school.email')
    user_name = serializers.ReadOnlyField(source='user.get_full_name')
    replies = TicketReplySerializer(many=True, read_only=True)
    attachments = TicketAttachmentSerializer(many=True, read_only=True)

    class Meta:
        model = SupportTicket
        fields = '__all__'
        read_only_fields = ['ticket_id', 'school', 'created_at', 'updated_at']

