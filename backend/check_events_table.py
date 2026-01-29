import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def check_table(table_name):
    with connection.cursor() as cursor:
        cursor.execute("SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname = 'public' AND tablename = %s)", [table_name])
        return cursor.fetchone()[0]

table = 'events'
exists = check_table(table)
print(f"Table '{table}' exists: {exists}")

if not exists:
    print("Listing all tables in public schema:")
    with connection.cursor() as cursor:
        cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
        for row in cursor.fetchall():
            print(f" - {row[0]}")
