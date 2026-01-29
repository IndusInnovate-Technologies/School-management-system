
import os
import django
import sys
from datetime import datetime
import pytz

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student, NewAdmission

def remove_dummy_data():
    # Define cutoff date for dummy data (e.g., created in 2026)
    cutoff_date = datetime(2026, 1, 1, tzinfo=pytz.UTC)

    # 1. Delete Students created after cutoff
    students_to_delete = Student.objects.filter(created_at__gte=cutoff_date)
    count_students = students_to_delete.count()
    print(f"Found {count_students} dummy students to delete.")
    for s in students_to_delete:
        print(f"Deleting Student: {s.student_name} (ID: {s.student_id})")
    students_to_delete.delete()

    # 2. Delete NewAdmissions created after cutoff
    admissions_to_delete = NewAdmission.objects.filter(created_at__gte=cutoff_date)
    count_admissions = admissions_to_delete.count()
    print(f"Found {count_admissions} dummy admissions to delete.")
    for a in admissions_to_delete:
        print(f"Deleting Admission: {a.student_name} (ID: {a.student_id})")
    admissions_to_delete.delete()

    print("Dummy data removal complete.")

if __name__ == '__main__':
    remove_dummy_data()
