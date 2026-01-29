class FinancialUserViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet to list and create financial users"""
    queryset = User.objects.filter(role__name='financial', is_active=True)
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None
    
    def get_serializer_class(self):
        """Use UserRegistrationSerializer for create action"""
        if self.action == 'create':
            from main_login.serializers import UserRegistrationSerializer
            return UserRegistrationSerializer
        return UserSerializer

    def perform_create(self, serializer):
        """Force role to be 'financial' and set school_id"""
        school_id = self.get_school_id()
        serializer.save(role='financial', school_id=school_id)
    
    def get_queryset(self):
        """Override to ensure fresh data and filter by school"""
        queryset = User.objects.filter(role__name='financial', is_active=True)
        
        if not self.request.user.is_authenticated:
            return queryset.none()
            
        # Check if user is super admin
        if hasattr(self.request.user, 'role') and self.request.user.role:
            if self.request.user.role.name == 'super_admin':
                return queryset
        
        # Get school_id from mixin
        school_id = self.get_school_id()
        if school_id:
            return queryset.filter(school_id=school_id)
            
        return queryset.none()
