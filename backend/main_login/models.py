"""
Models for main_login app - User, Role, and Authentication
"""

import uuid
import random
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models


# -------------------------
# ROLE MODEL
# -------------------------

class Role(models.Model):
    """User roles in the system"""
    
    ROLE_CHOICES = [
        ('super_admin', 'Super Admin'),
        ('management_admin', 'Management Admin'),
        ('teacher', 'Teacher'),
        ('student_parent', 'Student/Parent'),
        ('financial', 'Financial Staff'),
        ('driver', 'Driver'),
    ]
    
    name = models.CharField(max_length=50, choices=ROLE_CHOICES, unique=True)
    description = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.get_name_display()
    
    class Meta:
        db_table = 'roles'
        verbose_name = 'Role'
        verbose_name_plural = 'Roles'


# -------------------------
# FINANCIAL DETAILS MODEL
# -------------------------

class FinancialDetails(models.Model):
    """Separate table for financial staff details"""
    financial_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # User credentials
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255, help_text="Hashed password")
    
    # Personal details
    full_name = models.CharField(max_length=300)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    
    # School association
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True)
    
    # Metadata
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.full_name} ({self.email})"
    
    class Meta:
        db_table = 'financial_details'
        verbose_name = 'Financial Detail'
        verbose_name_plural = 'Financial Details'



# -------------------------
# USER MANAGER
# -------------------------

class UserManager(BaseUserManager):
    """Custom manager to handle user creation"""

    def generate_6_digit_password(self):
        """Generate temporary login PIN"""
        return str(random.randint(100000, 999999))

    def create_user(self, email, username, password=None, **extra_fields):
        """Create normal user with OTP login first"""

        if not email:
            raise ValueError("Email is required")

        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)

        # If no password provided → generate temporary 6-digit PIN
        if password:
            if len(password) == 6 and password.isdigit():
                user.password_hash = password
                user.set_password(password)
            else:
                user.set_password(password)
                user.updated_password = password
                user.has_custom_password = True
        else:
            user.password_hash = self.generate_6_digit_password()
            user.set_password(user.password_hash)

        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password, **extra_fields):
        """Create superuser (must set permanent password directly)"""

        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if len(password) < 6:
            raise ValueError("Superuser must have a secure password (not temporary PIN).")

        user = self.model(email=self.normalize_email(email), username=username, **extra_fields)
        user.set_password(password)
        # Store the user's created password (plain text) in updated_password field
        user.updated_password = password
        user.has_custom_password = True  # permanent password
        user.save(using=self._db)

        return user



# -------------------------
# USER MODEL
# -------------------------

class User(AbstractBaseUser, PermissionsMixin):
    """Custom User model with temporary password system"""

    # Database columns based on shared sheet order
    user_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.CharField(max_length=150, unique=True)
    email = models.EmailField(unique=True)

    mobile = models.CharField(max_length=20, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)

    # 🔥 Temporary login password (exactly 8 characters)
    password_hash = models.CharField(max_length=8, null=True, blank=True, help_text="Temporary login 8-character password")

    # 🔥 Flag to indicate whether user has set a real password
    has_custom_password = models.BooleanField(default=False, help_text="True once user sets their permanent password")
    
    # 🔥 User's own created password (plain text) - stored when has_custom_password is True
    updated_password = models.CharField(max_length=255, null=True, blank=True, help_text="User's custom created password (plain text)")

    # 🔥 OTP for password reset
    reset_otp = models.CharField(max_length=6, null=True, blank=True, help_text="OTP for password reset")

    first_name = models.CharField(max_length=150, null=True, blank=True)
    last_name = models.CharField(max_length=150, null=True, blank=True)

    profile_photo_id = models.UUIDField(null=True, blank=True)

    role = models.ForeignKey(
        Role,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='role_id',
        related_name='users'
    )
    
    # School ID for filtering (read-only, auto-populated from related models)
    school_id = models.CharField(
        max_length=100,
        db_index=True,
        null=True,
        blank=True,
        editable=False,
        help_text='School ID for filtering (read-only, auto-populated from related models)'
    )

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Authentication settings
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = UserManager()

    # ---------------------
    # AUTH LOGIC
    # ---------------------

    def set_new_password(self, raw_password):
        """
        Called when user creates permanent password after first login.
        When has_custom_password becomes True, the old password is replaced with the new password.
        The new password (plain text) is stored in updated_password field in the database.
        """
        # Set the new password (this replaces the old password in Django's password field)
        self.set_password(raw_password)
        
        # Store the user's own created password (plain text) in updated_password field
        # This field will contain the actual password the user created
        self.updated_password = raw_password
        
        # Mark that user now has a custom password
        # When has_custom_password is True, the password has been updated
        self.has_custom_password = True
        
        # Remove temporary PIN/hash since user now has a custom password
        self.password_hash = None
        
        # Save to database - new password (plain text) is now stored in updated_password field
        self.save()

    def needs_password_creation(self):
        """Returns True if user must set new password after first login"""
        return not self.has_custom_password
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id from related models if not set"""
        # Only auto-populate if school_id is not already set
        if not self.school_id:
            from .utils import get_user_school_id
            school_id = get_user_school_id(self)
            if school_id:
                self.school_id = school_id
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.username} ({self.email})"

    @property
    def role_name(self):
        return self.role.name if self.role else None

    class Meta:
        db_table = 'users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'


# -------------------------
# FCM DEVICE (Push Notifications)
# -------------------------

class FCMDevice(models.Model):
    """Stores FCM registration tokens for push notifications (Android/iOS)"""
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='fcm_devices'
    )
    token = models.CharField(max_length=255, unique=True, db_index=True)
    platform = models.CharField(
        max_length=10,
        choices=[('android', 'Android'), ('ios', 'iOS')],
        default='android'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'fcm_devices'
        verbose_name = 'FCM Device'
        verbose_name_plural = 'FCM Devices'
        indexes = [
            models.Index(fields=['user']),
        ]

    def __str__(self):
        return f"{self.user.username} ({self.platform})"


class UserNotificationSeen(models.Model):
    """Tracks when a user last viewed push notifications (for unread count)."""
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='notification_seen'
    )
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_notification_seen'
        verbose_name = 'User Notification Seen'
        verbose_name_plural = 'User Notification Seen'
