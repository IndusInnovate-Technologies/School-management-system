
import os
import sys
import django
from django.db import connection

# Set up Django
sys.path.append(os.getcwd())
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "school_backend.settings")
django.setup()

def check_columns():
    with connection.cursor() as cursor:
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'teachers'")
        columns = [row[0] for row in cursor.fetchall()]
        print(f"Columns in 'teachers' table: {columns}")
        
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'students'")
        columns = [row[0] for row in cursor.fetchall()]
        print(f"Columns in 'students' table: {columns}")
        
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'new_admissions'")
        columns = [row[0] for row in cursor.fetchall()]
        print(f"Columns in 'new_admissions' table: {columns}")

if __name__ == "__main__":
    check_columns()
