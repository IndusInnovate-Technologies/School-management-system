"""
Serializer mixins for automatic school_id handling
"""
from rest_framework import serializers
from .utils import get_user_school_id


class SchoolIdMixin:
    """
    Mixin to automatically handle school_id in serializers.
    
    This mixin:
    1. Adds school_id as a read-only field (visible in API responses)
    2. Auto-populates school_id from logged-in user during creation
    3. Makes school_id always read-only for all users (fetched from schools table)
    
    Usage:
        class MySerializer(SchoolIdMixin, serializers.ModelSerializer):
            class Meta:
                model = MyModel
                fields = [..., 'school_id']
    """
    
    school_id = serializers.CharField(
        read_only=True,
        help_text='School ID (auto-populated from logged-in user)'
    )
    
    def __init__(self, *args, **kwargs):
        """Override to make school_id always read-only"""
        super().__init__(*args, **kwargs)
        
        # school_id is always read-only for all users (fetched from schools table)
        # Safely access the field - it may not exist if fields = '__all__' excludes the mixin's field
        # or when the model has a school ForeignKey that creates its own school_id field
        try:
            self.fields['school_id'].read_only = True
        except KeyError:
            # Field doesn't exist - this is OK, it means the serializer is using
            # the model's school_id field (from ForeignKey) instead of the mixin's field
            pass
    
    def create(self, validated_data):
        """Auto-populate school_id from logged-in user"""
        request = self.context.get('request') if hasattr(self, 'context') else None
        
        if request and hasattr(request, 'user'):
            school_id = get_user_school_id(request.user)
            
            # Only auto-populate if user is not super admin
            if school_id:
                if hasattr(request.user, 'role') and request.user.role:
                    if request.user.role.name != 'super_admin':
                        # Auto-populate school_id for non-super-admin users
                        validated_data['school_id'] = school_id
                else:
                    # No role means auto-populate
                    validated_data['school_id'] = school_id
        
        return super().create(validated_data)

