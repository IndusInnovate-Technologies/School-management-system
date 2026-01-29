import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def get_columns(table_name):
    print(f"\nChecking table: {table_name}")
    with connection.cursor() as cursor:
        cursor.execute("SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename = %s)", [table_name])
        exists = cursor.fetchone()[0]
        if exists:
            print(f" - Table {table_name} EXISTS")
            cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = %s", [table_name])
            cols = [r[0] for r in cursor.fetchall()]
            print(f" - COLUMNS: {', '.join(cols)}")
        else:
            print(f" - Table {table_name} MISSING")

tables = ['events', 'management_admin_event', 'gallery', 'management_admin_gallery', 'gallery_images', 'management_admin_galleryimage']
for t in tables:
    get_columns(t)

print("\nAll tables in public schema:")
with connection.cursor() as cursor:
    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
    all_tabs = [row[0] for row in cursor.fetchall()]
    print(", ".join(all_tabs))
