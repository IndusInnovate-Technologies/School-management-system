"""
Test script to verify PostgreSQL database connection and query users
Run with: python test_db_connection.py
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection
from main_login.models import User, Role

def test_connection():
    """Test database connection"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            print("[OK] PostgreSQL Connection Successful!")
            print(f"   Database Version: {version.split(',')[0]}")
            return True
    except Exception as e:
        print(f"[ERROR] Database Connection Failed: {e}")
        return False

def test_tables():
    """Test if tables exist and can be queried"""
    try:
        # Check if tables exist
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name IN ('users', 'roles', 'user_sessions')
                ORDER BY table_name;
            """)
            tables = cursor.fetchall()
            print(f"\n[OK] Found {len(tables)} tables:")
            for table in tables:
                print(f"   - {table[0]}")
        return True
    except Exception as e:
        print(f"[ERROR] Table Check Failed: {e}")
        return False

def test_users():
    """Test querying users from database"""
    try:
        user_count = User.objects.count()
        role_count = Role.objects.count()
        
        print(f"\n[OK] User Data:")
        print(f"   Total Users: {user_count}")
        print(f"   Total Roles: {role_count}")
        
        if user_count > 0:
            print(f"\n   Users in database:")
            for user in User.objects.all()[:10]:
                role_name = user.role.name if user.role else "No Role"
                print(f"   - Email: {user.email}, Username: {user.username}, Role: {role_name}, Active: {user.is_active}")
        else:
            print("   [WARNING] No users found in database!")
            print("   [TIP] Run migrations: python manage.py migrate")
            print("   [TIP] Create a user: python manage.py createsuperuser")
        
        if role_count > 0:
            print(f"\n   Roles in database:")
            for role in Role.objects.all():
                user_count_for_role = User.objects.filter(role=role).count()
                print(f"   - {role.name}: {user_count_for_role} users")
        else:
            print("   [WARNING] No roles found in database!")
            print("   [TIP] Create roles by running migrations or manually")
        
        return True
    except Exception as e:
        print(f"[ERROR] User Query Failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_login_query(email, password):
    """Test if a specific user can be authenticated"""
    try:
        from django.contrib.auth import authenticate
        user = authenticate(username=email, password=password)
        if user:
            print(f"\n[OK] Authentication Test:")
            print(f"   Email: {email}")
            print(f"   Username: {user.username}")
            print(f"   Role: {user.role.name if user.role else 'No Role'}")
            print(f"   Active: {user.is_active}")
            return True
        else:
            print(f"\n[ERROR] Authentication Failed for: {email}")
            print("   Check if:")
            print("   1. User exists in database")
            print("   2. Password is correct")
            print("   3. User is active (is_active=True)")
            return False
    except Exception as e:
        print(f"[ERROR] Authentication Test Failed: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("PostgreSQL Database Connection Test")
    print("=" * 60)
    
    # Test 1: Database Connection
    if not test_connection():
        print("\n[ERROR] Cannot proceed - Database connection failed!")
        print("   Check your settings.py DATABASES configuration")
        sys.exit(1)
    
    # Test 2: Tables
    if not test_tables():
        print("\n[WARNING] Tables may not exist. Run: python manage.py migrate")
    
    # Test 3: Query Users
    test_users()
    
    # Test 4: Authentication (if email provided as argument)
    if len(sys.argv) > 1:
        email = sys.argv[1]
        password = sys.argv[2] if len(sys.argv) > 2 else input(f"Enter password for {email}: ")
        test_login_query(email, password)
    
    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)

