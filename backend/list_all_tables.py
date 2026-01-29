import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

print("Searching for 'event' or 'gallery' tables in 'public' schema:")
with connection.cursor() as cursor:
    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
    tables = [row[0] for row in cursor.fetchall()]
    found = False
    for t in tables:
        if 'event' in t.lower() or 'gallery' in t.lower():
            print(f"FOUND TABLE: {t}")
            found = True
            # Get columns
            cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = %s", [t])
            cols = [r[0] for r in cursor.fetchall()]
            print(f"  COLUMNS: {', '.join(cols)}")
    if not found:
        print("No matching tables found.")

print("\nAll tables in public schema:")
with connection.cursor() as cursor:
    cursor.execute("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename")
    all_tables = [row[0] for row in cursor.fetchall()]
    print(", ".join(all_tables))
