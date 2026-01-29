import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection

def list_tables():
    with connection.cursor() as cursor:
        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"Tables found: {tables}")
        return tables

def check_columns(table_name):
    with connection.cursor() as cursor:
        query = f"SELECT column_name FROM information_schema.columns WHERE table_name = '{table_name}' AND table_schema = 'public' ORDER BY ordinal_position;"
        cursor.execute(query)
        columns = [row[0] for row in cursor.fetchall()]
        print(f"Columns in {table_name}: {columns}")

all_tables = list_tables()
target_keywords = ['fee', 'busstopstudent', 'teacher', 'admission', 'student']

for table in all_tables:
    if any(kw in table.lower() for kw in target_keywords):
        check_columns(table)
