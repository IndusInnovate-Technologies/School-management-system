"""
Script to create a super_admin user with email and password.
Run with: python create_super_admin.py
"""
import os
import sys
import django
import getpass

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from main_login.models import Role

User = get_user_model()


def create_super_admin():
    """Create a super_admin user by prompting for email and password in terminal"""
    
    print("=" * 80)
    print("Create Super Admin User")
    print("=" * 80)
    print()
    
    # Prompt for email
    while True:
        email = input("Enter email address for super admin: ").strip()
        if email:
            # Basic email validation
            if '@' in email and '.' in email.split('@')[1]:
                break
            else:
                print("❌ Invalid email format. Please try again.")
        else:
            print("❌ Email cannot be empty. Please try again.")
    
    # Check if user already exists
    try:
        existing_user = User.objects.get(email=email)
        print(f"\n⚠️  User with email '{email}' already exists.")
        response = input("Do you want to update this user to super_admin? (yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            print("❌ Operation cancelled.")
            return
        user = existing_user
        update_existing = True
    except User.DoesNotExist:
        user = None
        update_existing = False
    
    # Prompt for password
    while True:
        password = getpass.getpass("Enter password for super admin: ")
        if password:
            password_confirm = getpass.getpass("Confirm password: ")
            if password == password_confirm:
                break
            else:
                print("❌ Passwords do not match. Please try again.")
        else:
            print("❌ Password cannot be empty. Please try again.")
    
    # Get or create super_admin role and ensure it has id=1
    from django.db import connection
    
    role = None
    try:
        # First, try to get super_admin role
        role = Role.objects.get(name='super_admin')
        print(f"\n[OK] Found Super Admin role (id={role.id})")
        
        # If it doesn't have id=1, we need to ensure it does
        if role.id != 1:
            # Check if id=1 is available
            try:
                role_with_id_1 = Role.objects.get(pk=1)
                print(f"\n⚠️  Role id=1 is already taken by '{role_with_id_1.name}'")
                print(f"    Using Super Admin role with id={role.id}")
            except Role.DoesNotExist:
                # id=1 is available, update super_admin to have id=1
                with connection.cursor() as cursor:
                    # Get the current max id to avoid conflicts
                    cursor.execute("SELECT MAX(id) FROM roles")
                    max_id = cursor.fetchone()[0] or 0
                    if max_id >= 1:
                        # Temporarily set super_admin to a high id
                        temp_id = max_id + 1
                        cursor.execute(
                            "UPDATE roles SET id = %s WHERE id = %s",
                            [temp_id, role.id]
                        )
                        # Now set it to id=1
                        cursor.execute(
                            "UPDATE roles SET id = 1 WHERE id = %s",
                            [temp_id]
                        )
                        # Refresh the role object
                        role = Role.objects.get(pk=1)
                        print(f"\n[OK] Updated Super Admin role to have id=1")
    except Role.DoesNotExist:
        # Super_admin role doesn't exist, create it
        # Check if id=1 is available
        try:
            role_with_id_1 = Role.objects.get(pk=1)
            # id=1 is taken, create super_admin normally
            role = Role.objects.create(
                name='super_admin',
                description='Super Admin role'
            )
            print(f"\n[OK] Created Super Admin role (id={role.id})")
            print(f"⚠️  Note: Role id=1 is taken by '{role_with_id_1.name}'")
        except Role.DoesNotExist:
            # id=1 is available, create super_admin with id=1
            with connection.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO roles (id, name, description, created_at, updated_at) VALUES (1, %s, %s, NOW(), NOW())",
                    ['super_admin', 'Super Admin role']
                )
            role = Role.objects.get(pk=1)
            print(f"\n[OK] Created Super Admin role with id=1")
    
    # Generate username from email if not exists
    username = email.split('@')[0]
    if update_existing:
        # Keep existing username if updating
        username = user.username
    else:
        # Ensure username is unique
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f'{base_username}{counter}'
            counter += 1
    
    try:
        if update_existing:
            # Update existing user
            user.email = email
            user.username = username
            user.role = role
            user.is_active = True
            # Set custom password
            user.set_new_password(password)
            print(f"\n[OK] Updated user: {username} ({email})")
        else:
            # Create new user
            user = User.objects.create(
                email=email,
                username=username,
                role=role,
                is_active=True,
                has_custom_password=False,  # Will be set to True by create_custom_password
            )
            # Set custom password
            user.set_new_password(password)
            print(f"\n[OK] Created user: {username} ({email})")
        
        # Print success message
        print("\n" + "=" * 80)
        print("✅ SUPER ADMIN CREATED SUCCESSFULLY!")
        print("=" * 80)
        print(f"Email: {email}")
        print(f"Username: {username}")
        print(f"Role: Super Admin (role_id: {role.id})")
        print("=" * 80)
        print("\n✅ You can now login with these credentials.")
        
    except Exception as e:
        print(f"\n❌ [ERROR] Failed to create super admin: {e}")
        import traceback
        traceback.print_exc()
        return None


if __name__ == "__main__":
    try:
        create_super_admin()
    except KeyboardInterrupt:
        print("\n\n❌ Operation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ [ERROR] An unexpected error occurred: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

