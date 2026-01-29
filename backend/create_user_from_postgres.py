"""
Script to help create Django users from PostgreSQL data
If you created users directly in PostgreSQL, this script helps convert them to Django users
Run with: python create_user_from_postgres.py
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.db import connection
from main_login.models import Role

User = get_user_model()

def import_user_from_postgres(email, username=None, password=None, role_name=None, first_name=None, last_name=None):
    """
    Import a user that was created directly in PostgreSQL
    
    Note: If you created users directly in PostgreSQL with plain text passwords,
    Django won't be able to authenticate them because Django uses hashed passwords.
    This function will create a proper Django user with a hashed password.
    """
    try:
        # Get or create role if provided
        role = None
        if role_name:
            role, created = Role.objects.get_or_create(
                name=role_name,
                defaults={'description': f'{role_name.replace("_", " ").title()} role'}
            )
            if created:
                print(f"[OK] Created role: {role_name}")
        
        # Check if user already exists
        try:
            user = User.objects.get(email=email)
            print(f"[SKIP] User already exists: {email}")
            if password:
                user.set_password(password)
                user.save()
                print(f"[UPDATE] Updated password for: {email}")
            if role:
                user.role = role
                user.save()
                print(f"[UPDATE] Updated role for: {email}")
            return user
        except User.DoesNotExist:
            pass
        
        # Create new user
        user = User.objects.create_user(
            email=email,
            username=username or email.split('@')[0],
            password=password or 'changeme123',  # Default password if not provided
            first_name=first_name or '',
            last_name=last_name or '',
            role=role,
            is_active=True,
            is_verified=True
        )
        
        print(f"[OK] Created user: {email}")
        print(f"     Username: {user.username}")
        print(f"     Password: {password or 'changeme123'} (CHANGE THIS!)")
        print(f"     Role: {role.name if role else 'None'}")
        
        return user
        
    except Exception as e:
        print(f"[ERROR] Failed to create user {email}: {e}")
        return None

def list_users_from_postgres():
    """List all users from PostgreSQL users table"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT email, username, first_name, last_name, is_active 
                FROM users 
                ORDER BY email;
            """)
            users = cursor.fetchall()
            
            if users:
                print("\n[INFO] Users found in PostgreSQL:")
                print("-" * 80)
                for user in users:
                    email, username, first_name, last_name, is_active = user
                    print(f"Email: {email}")
                    print(f"  Username: {username}")
                    print(f"  Name: {first_name} {last_name}")
                    print(f"  Active: {is_active}")
                    print()
                return users
            else:
                print("[INFO] No users found in PostgreSQL users table")
                return []
    except Exception as e:
        print(f"[ERROR] Failed to query PostgreSQL: {e}")
        return []

if __name__ == "__main__":
    print("=" * 80)
    print("Django User Import from PostgreSQL")
    print("=" * 80)
    print("\nThis script helps you create Django users properly.")
    print("If you created users directly in PostgreSQL, Django can't authenticate them")
    print("because Django uses hashed passwords.\n")
    
    # List existing users
    print("Checking PostgreSQL for existing users...")
    postgres_users = list_users_from_postgres()
    
    print("\n" + "=" * 80)
    print("To create a user manually, use:")
    print("=" * 80)
    print("""
# Example 1: Create a super admin
import_user_from_postgres(
    email='admin@school.com',
    username='admin',
    password='admin123',
    role_name='super_admin',
    first_name='Super',
    last_name='Admin'
)

# Example 2: Create a management admin
import_user_from_postgres(
    email='management@school.com',
    username='management',
    password='management123',
    role_name='management_admin'
)

# Example 3: Create a teacher
import_user_from_postgres(
    email='teacher@school.com',
    username='teacher',
    password='teacher123',
    role_name='teacher'
)

# Example 4: Create a parent
import_user_from_postgres(
    email='parent@school.com',
    username='parent',
    password='parent123',
    role_name='student_parent'
)
    """)
    
    print("\n" + "=" * 80)
    print("Or use the management command:")
    print("=" * 80)
    print("python manage.py create_dummy_users")
    print("=" * 80)

