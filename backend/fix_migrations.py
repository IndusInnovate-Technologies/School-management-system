import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection

def fix_migrations():
    with connection.cursor() as cursor:
        print("Checking django_migrations...")
        cursor.execute("SELECT name FROM django_migrations WHERE app = 'management_admin'")
        applied = [row[0] for row in cursor.fetchall()]
        
        # Missing dependencies reported by Django
        to_add = [
            '0054_activity',
            '0055_teacher_emergency_contact_relation_and_more'
        ]
        
        for name in to_add:
            if name not in applied:
                print(f"Faking migration {name} in database...")
                # We use a dummy date and time
                cursor.execute(
                    "INSERT INTO django_migrations (app, name, applied) VALUES (%s, %s, now())",
                    ['management_admin', name]
                )
                print(f"Successfully added {name}")
            else:
                print(f"Migration {name} already exists in database.")

if __name__ == "__main__":
    try:
        fix_migrations()
        print("Finished fixing migrations.")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
