"""
Import users from database with proper Django password hashing
This script imports the users shown in the database table
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from main_login.models import Role

User = get_user_model()

def import_user(email, username, password, role_name, first_name, last_name):
    """Import a user with proper Django password hashing"""
    try:
        # Get or create role
        role, role_created = Role.objects.get_or_create(
            name=role_name,
            defaults={'description': f'{role_name.replace("_", " ").title()} role'}
        )
        if role_created:
            print(f"[OK] Created role: {role_name}")
        
        # Check if user exists
        try:
            user = User.objects.get(email=email)
            print(f"[INFO] User already exists: {email}")
            
            # Update user information
            user.username = username
            user.first_name = first_name
            user.last_name = last_name
            user.role = role
            user.is_active = True  # Make sure user is active
            user.is_verified = True
            
            # Set password (this will hash it properly)
            user.set_password(password)
            user.save()
            
            print(f"[UPDATE] Updated user: {email}")
            print(f"  Username: {user.username}")
            print(f"  Password: {password} (hashed)")
            print(f"  Role: {user.role.name}")
            print(f"  Active: {user.is_active}")
            
            return user
            
        except User.DoesNotExist:
            # Create new user
            user = User.objects.create_user(
                email=email,
                username=username,
                password=password,  # Django will hash this automatically
                first_name=first_name,
                last_name=last_name,
                role=role,
                is_active=True,
                is_verified=True
            )
            
            print(f"[OK] Created user: {email}")
            print(f"  Username: {user.username}")
            print(f"  Password: {password} (hashed)")
            print(f"  Role: {user.role.name}")
            print(f"  Active: {user.is_active}")
            
            return user
            
    except Exception as e:
        print(f"[ERROR] Failed to import user {email}: {e}")
        import traceback
        traceback.print_exc()
        return None

def test_login(email, password):
    """Test if user can login"""
    from django.contrib.auth import authenticate
    
    user = authenticate(username=email, password=password)
    
    if user:
        print(f"\n[SUCCESS] Login test passed!")
        print(f"  Email: {user.email}")
        print(f"  Username: {user.username}")
        print(f"  Role: {user.role.name if user.role else 'None'}")
        print(f"  Active: {user.is_active}")
        return True
    else:
        print(f"\n[ERROR] Login test failed!")
        print("  Check if password is correct")
        return False

if __name__ == "__main__":
    print("=" * 100)
    print("Importing Database Users to Django")
    print("=" * 100)
    
    # Import sushil (teacher)
    print("\n[1/2] Importing sushil (teacher)...")
    print("-" * 100)
    sushil = import_user(
        email='sushil@gmail.com',
        username='sushil',
        password='sushil12345',
        role_name='teacher',  # Map 'teacher' to 'teacher'
        first_name='sushil',
        last_name='rao'
    )
    
    if sushil:
        print("\n[TEST] Testing login for sushil...")
        test_login('sushil@gmail.com', 'sushil12345')
    
    # Import sairam (student)
    print("\n[2/2] Importing sairam (student)...")
    print("-" * 100)
    sairam = import_user(
        email='sairam@gmail.com',
        username='sairam',
        password='sai12345',  # Using password (not password2)
        role_name='student_parent',  # Map 'student' to 'student_parent'
        first_name='sai',
        last_name='ram B'
    )
    
    if sairam:
        print("\n[TEST] Testing login for sairam...")
        test_login('sairam@gmail.com', 'sai12345')
    
    print("\n" + "=" * 100)
    print("Import Complete!")
    print("=" * 100)
    print("\n[INFO] Users can now login with:")
    print("\nTeacher Login:")
    print("  Email: sushil@gmail.com")
    print("  Password: sushil12345")
    print("  Role: teacher")
    print("\nStudent Login:")
    print("  Email: sairam@gmail.com")
    print("  Password: sai12345")
    print("  Role: parent (for student_parent)")
    print("\n[INFO] Login endpoint: POST /api/auth/role-login/")
    print("=" * 100)

