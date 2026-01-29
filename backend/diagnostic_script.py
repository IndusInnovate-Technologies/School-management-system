import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def get_tables():
    print("Listing all database tables (public schema):")
    with connection.cursor() as cursor:
        cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
        for row in cursor.fetchall():
            print(f" - {row[0]}")

def get_migration_error_details():
    # Try to find exactly what relation is missing
    # We saw 'vents" does not exist' earlier. 
    # Let's check common names.
    tables_to_check = ['management_admin_event', 'management_admin_galleryevent', 'management_admin_galleryevents']
    print("\nChecking specific tables existence:")
    with connection.cursor() as cursor:
        for t in tables_to_check:
            cursor.execute("SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename = %s)", [t])
            exists = cursor.fetchone()[0]
            print(f" - {t}: {'EXISTS' if exists else 'MISSING'}")

get_tables()
get_migration_error_details()
