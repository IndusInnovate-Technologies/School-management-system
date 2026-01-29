"""
Serializers for main_login app
"""
from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.hashers import make_password
from .models import User, Role, FinancialDetails


class RoleSerializer(serializers.ModelSerializer):
    """Serializer for Role model"""
    class Meta:
        model = Role
        fields = ['id', 'name', 'description']


class FinancialDetailsSerializer(serializers.ModelSerializer):
    """Serializer for FinancialDetails model"""
    password2 = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = FinancialDetails
        fields = ['email', 'password', 'password2', 'full_name', 'phone', 
                  'address', 'date_of_birth', 'gender', 'school_id']
        extra_kwargs = {
            'password': {'write_only': True}
        }
    
    def validate_email(self, value):
        """Check if email already exists"""
        if FinancialDetails.objects.filter(email=value).exists():
            raise serializers.ValidationError("A financial user with this email already exists. Please use a different email address.")
        return value
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        password = validated_data.pop('password')
        
        # Create financial detail instance
        financial_detail = FinancialDetails(**validated_data)
        # Hash the password before saving
        financial_detail.password = make_password(password)
        financial_detail.save()
        return financial_detail


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password2 = serializers.CharField(write_only=True, required=True)
    role = serializers.CharField(write_only=True, required=False)
    school_id = serializers.CharField(required=False)
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password2', 'mobile', 'address', 'date_of_birth', 'gender', 'role', 'first_name', 'last_name', 'school_id']
        extra_kwargs = {
            'email': {'required': True},
            'username': {'required': True},
        }
    
    def validate_email(self, value):
        """Check if email already exists"""
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists. Please use a different email address.")
        return value
    
    def validate_username(self, value):
        """Check if username already exists"""
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken. Please use a different username.")
        return value
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        role_name = validated_data.pop('role', None)
        password = validated_data.pop('password')
        
        user = User.objects.create_user(
            password=password,
            **validated_data
        )
        
        if role_name:
            try:
                role = Role.objects.get(name=role_name)
                user.role = role
                user.save()
            except Role.DoesNotExist:
                pass
        
        return user


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True)
    role = serializers.CharField(required=False)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        role = attrs.get('role')
        
        if email and password:
            user = authenticate(username=email, password=password)
            
            if not user:
                raise serializers.ValidationError('Invalid email or password.')
            
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled.')
            
            # Note: Role validation is handled in the view (role_login) for role-specific logins
            # This allows the view to provide more detailed error messages about role mismatches
            
            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError('Must include "email" and "password".')


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    role = RoleSerializer(read_only=True, allow_null=True)
    role_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'user_id', 'username', 'email', 'first_name', 'last_name',
            'mobile', 'address', 'date_of_birth', 'gender', 'role', 'role_name', 'is_active',
            'created_at', 'updated_at', 'profile_photo_id', 'has_custom_password', 'updated_password'
        ]
        read_only_fields = ['user_id', 'created_at', 'updated_at', 'updated_password']
    
    def get_role_name(self, obj):
        """Get role name from the User model property"""
        try:
            return obj.role_name
        except Exception:
            return None


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password"""
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(
        required=True,
        validators=[validate_password]
    )
    new_password2 = serializers.CharField(required=True)
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs


class CreatePasswordSerializer(serializers.Serializer):
    """Serializer for creating user password (first time)"""
    password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password],
        help_text='New password'
    )
    password2 = serializers.CharField(
        required=True,
        write_only=True,
        help_text='Confirm new password'
    )
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

