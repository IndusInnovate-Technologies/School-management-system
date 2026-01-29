import os
import django
import sys

# Add the project directory to sys.path so backend module can be found
sys.path.append(os.getcwd())

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User, Role

email = 'rakesh@gmail.com'
password = 'Rakesh@123'
role_name = 'teacher'

try:
    try:
        user = User.objects.get(email=email)
        print(f"User {email} found.")
    except User.DoesNotExist:
        user = None

    if user:
        if not user.is_active:
            user.is_active = True
            print("Setting user to active.")

        # Check/Set role
        if not user.role or user.role.name != role_name:
            role, _ = Role.objects.get_or_create(name=role_name)
            user.role = role
            print(f"Updated role to {role_name}.")

        user.set_password(password)
        user.updated_password = password
        user.has_custom_password = True
        user.save()
        print("Password reset to 'Rakesh@123'.")
    else:
        print(f"User {email} not found. Creating...")
        role, _ = Role.objects.get_or_create(name=role_name)
        user = User.objects.create_user(
            username='rakesh',
            email=email,
            password=password,
            role=role
        )
        user.is_active = True
        user.updated_password = password
        user.has_custom_password = True
        user.save()
        print("User created successfully.")

except Exception as e:
    print(f"Error: {e}")
