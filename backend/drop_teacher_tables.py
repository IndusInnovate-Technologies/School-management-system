import os
import sys
import django
from django.db import connection

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def drop_teacher_tables():
    tables = [
        'attendances',
        'grades',
        'exams',
        'assignments',
        'timetables',
        'study_materials',
        'class_students',
        'classes'
    ]
    
    with connection.cursor() as cursor:
        for table in tables:
            print(f"Dropping table: {table}")
            try:
                cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE")
                print(f"Dropped {table}")
            except Exception as e:
                print(f"Error dropping {table}: {e}")

if __name__ == '__main__':
    drop_teacher_tables()
