import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

tables_to_check = [
    'management_admin_event',
    'management_admin_galleryevent',
    'management_admin_galleryevents',
    'events',
    'gallery',
    'gallery_images',
    'school_activities',
    'management_admin_student',
    'management_admin_teacher'
]

print("Checking table existence in 'public' schema:")
with connection.cursor() as cursor:
    for t in tables_to_check:
        cursor.execute("SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename = %s)", [t])
        exists = cursor.fetchone()[0]
        print(f" - {t:40} : {'EXISTS' if exists else 'MISSING'}")

    print("\nAll management_admin tables present:")
    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename LIKE 'management_admin%' ORDER BY tablename")
    for row in cursor.fetchall():
        print(f" - {row[0]}")
