"""
Custom authentication backend to use password_hash when password field is null
"""
from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model


class PasswordHashBackend(ModelBackend):
    """
    Custom authentication backend that:
    1. Checks password_hash field if password field is null (for initial login)
    2. Falls back to password field if password_hash is None (for users who created password)
    """
    def authenticate(self, request, username=None, password=None, **kwargs):
        UserModel = get_user_model()
        
        if username is None:
            username = kwargs.get(UserModel.USERNAME_FIELD)
        
        if username is None or password is None:
            return None
        
        try:
            # Try to get user by username or email
            if '@' in username:
                user = UserModel.objects.get(email=username)
            else:
                user = UserModel.objects.get(username=username)
        except UserModel.DoesNotExist:
            # Run the default password hasher once to reduce the timing
            # difference between an existing and a non-existing user
            UserModel().set_password(password)
            return None
        
        # Check if user can authenticate
        if not self.user_can_authenticate(user):
            return None
        
        # Check if user has created their own password
        if user.has_custom_password:
            # User has created password, check against password field
            if user.check_password(password):
                return user
        else:
            # User hasn't created password yet, check password_hash field
            if user.password_hash and user.password_hash == password:
                return user
        
        return None

