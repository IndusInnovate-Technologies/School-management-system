import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def get_table_details(table_name):
    print(f"\nDetails for table '{table_name}':")
    with connection.cursor() as cursor:
        cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = %s", [table_name])
        columns = cursor.fetchall()
        if not columns:
            print(" - TABLE NOT FOUND in 'public' schema")
        for col in columns:
            print(f" - {col[0]} ({col[1]})")

print("Checking for Event related tables:")
get_table_details('events')
get_table_details('management_admin_event')
get_table_details('management_admin_galleryevents') # From the error bit I saw

print("\nListing all tables in public schema:")
with connection.cursor() as cursor:
    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
    for row in cursor.fetchall():
        print(f" - {row[0]}")
