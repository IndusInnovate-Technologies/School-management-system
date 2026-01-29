"""
Script to fix duplicate user_id values in the database before running migration 0003.
Run this script before applying migration 0003_remove_user_id_remove_user_is_verified_and_more.
"""
import os
import sys
import django
import uuid

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection


def fix_duplicate_user_ids():
    """Fix duplicate user_id values in the users table"""
    with connection.cursor() as cursor:
        # Check if user_id column exists
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='users' AND column_name='user_id';
        """)
        user_id_exists = cursor.fetchone() is not None
        
        if not user_id_exists:
            print("user_id column does not exist yet. No duplicates to fix.")
            return
        
        # Find duplicate user_ids
        cursor.execute("""
            SELECT user_id, COUNT(*) as count
            FROM users
            WHERE user_id IS NOT NULL
            GROUP BY user_id
            HAVING COUNT(*) > 1;
        """)
        duplicates = cursor.fetchall()
        
        if not duplicates:
            print("No duplicate user_ids found. Database is clean.")
            return
        
        print(f"Found {len(duplicates)} duplicate user_id(s). Fixing...")
        
        for user_id, count in duplicates:
            print(f"  Fixing duplicate user_id: {user_id} (appears {count} times)")
            
            # Get all user IDs with this duplicate user_id, ordered by id
            cursor.execute("""
                SELECT id 
                FROM users 
                WHERE user_id = %s 
                ORDER BY id;
            """, [user_id])
            user_rows = cursor.fetchall()
            
            # Keep the first one, regenerate UUIDs for the rest
            for idx, (db_id,) in enumerate(user_rows):
                if idx == 0:
                    print(f"    Keeping user_id {user_id} for id {db_id}")
                else:
                    # Generate new unique UUID
                    new_user_id = uuid.uuid4()
                    
                    # Make sure it doesn't conflict with existing ones
                    cursor.execute("SELECT COUNT(*) FROM users WHERE user_id = %s", [new_user_id])
                    while cursor.fetchone()[0] > 0:
                        new_user_id = uuid.uuid4()
                    
                    # Update the user with new UUID
                    cursor.execute("UPDATE users SET user_id = %s WHERE id = %s", [new_user_id, db_id])
                    print(f"    Assigned new user_id {new_user_id} to id {db_id}")
        
        print("\nAll duplicates fixed successfully!")
        
        # Verify no duplicates remain
        cursor.execute("""
            SELECT user_id, COUNT(*) as count
            FROM users
            WHERE user_id IS NOT NULL
            GROUP BY user_id
            HAVING COUNT(*) > 1;
        """)
        remaining_duplicates = cursor.fetchall()
        
        if remaining_duplicates:
            print(f"WARNING: {len(remaining_duplicates)} duplicate(s) still remain!")
        else:
            print("Verification: No duplicates remain. Database is ready for migration.")


if __name__ == '__main__':
    try:
        fix_duplicate_user_ids()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

