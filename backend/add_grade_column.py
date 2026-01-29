
import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def add_grade():
    with connection.cursor() as cursor:
        try:
            print("Attempting to add 'grade' column to 'students' table...")
            cursor.execute('ALTER TABLE "students" ADD COLUMN "grade" varchar(50) NULL;')
            print("Column 'grade' added successfully.")
        except Exception as e:
            print(f"Error adding column: {e}")

if __name__ == '__main__':
    add_grade()
