"""
ViewSet mixins for automatic school-based data filtering
"""
from rest_framework.response import Response
from rest_framework import status
from .utils import get_user_school_id


class SchoolFilterMixin:
    """
    Mixin to automatically filter querysets by school_id based on logged-in user.
    
    This mixin should be added to ViewSets that need school-based data isolation.
    It automatically filters all queries to only return data for the logged-in user's school.
    
    Usage:
        class MyViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
            queryset = MyModel.objects.all()
            ...
    
    The mixin:
    1. Overrides get_queryset() to filter by school_id
    2. Overrides create() to automatically set school_id on new objects
    3. Provides get_school_id() method to get current user's school_id
    """
    
    # Field name to use for filtering (can be overridden in subclasses)
    school_id_field = 'school_id'
    
    def get_school_id(self):
        """Get the school_id for the current logged-in user"""
        return get_user_school_id(self.request.user)
    
    def get_queryset(self):
        """
        Filter queryset by school_id if user is not super admin.
        Super admins can see all data.
        
        This method works with ViewSets that override get_queryset() by:
        1. First calling super().get_queryset() to get the base queryset (which may already be filtered)
        2. Then applying school_id filtering on top of that
        """
        # Get base queryset (may already be filtered by subclass)
        queryset = super().get_queryset()
        
        # Check if user is super admin (should see all data)
        if hasattr(self.request.user, 'role') and self.request.user.role:
            if self.request.user.role.name == 'super_admin':
                return queryset
        
        # Get school_id for current user
        school_id = self.get_school_id()
        
        if not school_id:
            # If no school_id found, return empty queryset
            # This prevents users without school access from seeing any data
            return queryset.none()
        
        # Filter by school_id
        # Handle both direct school_id field and ForeignKey to School
        filter_kwargs = {}
        
        # Check if model has direct school_id field
        if hasattr(queryset.model, self.school_id_field):
            filter_kwargs[self.school_id_field] = school_id
        # Check if model has ForeignKey to School (Django creates school_id field automatically)
        elif hasattr(queryset.model, 'school'):
            filter_kwargs['school__school_id'] = school_id
        # Check if model has school ForeignKey with different name
        elif hasattr(queryset.model, '_meta'):
            # Look for any ForeignKey to School model
            from super_admin.models import School
            for field in queryset.model._meta.get_fields():
                if hasattr(field, 'related_model') and field.related_model == School:
                    filter_kwargs[f'{field.name}__school_id'] = school_id
                    break
        
        if filter_kwargs:
            # Apply school_id filter on top of existing filters
            return queryset.filter(**filter_kwargs)
        
        # If no school_id field found, return queryset as-is (for models without school filtering)
        return queryset
    
    def perform_create(self, serializer):
        """
        Automatically set school_id when creating new objects.
        """
        school_id = self.get_school_id()
        
        # Check if user is super admin
        if hasattr(self.request.user, 'role') and self.request.user.role:
            if self.request.user.role.name == 'super_admin':
                # Super admin can set school_id manually or leave it
                super().perform_create(serializer)
                return
        
        # For non-super-admin users, automatically set school_id
        if school_id:
            # Check if serializer has school_id field
            if 'school_id' in serializer.fields:
                serializer.save(school_id=school_id)
            # Check if serializer has school ForeignKey
            elif 'school' in serializer.fields:
                from super_admin.models import School
                try:
                    school = School.objects.get(school_id=school_id)
                    serializer.save(school=school)
                except School.DoesNotExist:
                    serializer.save()
            else:
                # Let serializer handle it (might auto-populate from related objects)
                serializer.save()
        else:
            # No school_id found - this shouldn't happen for authenticated users
            # but handle gracefully
            serializer.save()
    
    def create(self, request, *args, **kwargs):
        """
        Override create to provide better error messages when school_id is missing.
        """
        school_id = self.get_school_id()
        
        # Check if user is super admin
        if hasattr(request.user, 'role') and request.user.role:
            if request.user.role.name == 'super_admin':
                return super().create(request, *args, **kwargs)
        
        # For non-super-admin users, check if school_id is available
        if not school_id:
            return Response(
                {
                    'success': False,
                    'message': 'No school associated with your account. Please contact administrator.',
                    'error': 'School not found'
                },
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().create(request, *args, **kwargs)

