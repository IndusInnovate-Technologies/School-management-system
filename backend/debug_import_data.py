
import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Teacher
from teacher.models import Class
from teacher.models import Timetable

def check_data():
    print("--- DEBUG DATA CHECK ---")
    
    # 1. Check Teacher
    teacher_id = 'EMPN-001' # From logs/template
    teacher = Teacher.objects.filter(employee_no=teacher_id).first()
    
    if not teacher:
        print(f"Teacher {teacher_id} NOT FOUND.")
        # Try finding ANY teacher to see format
        print("First 5 teachers:", list(Teacher.objects.values_list('employee_no', flat=True)[:5]))
        return

    print(f"Teacher Found: {teacher.first_name} {teacher.last_name}")
    print(f"Teacher School ID: {teacher.school_id}")
    
    # 2. Check Classes for this School
    classes = Class.objects.filter(school_id=teacher.school_id)
    print(f"Classes in School {teacher.school_id}: {classes.count()}")
    
    for c in classes:
        print(f" - '{c.name}' Section '{c.section}' (ID: {c.id})")

    # 3. Check Timetables
    timetables = Timetable.objects.filter(teacher=teacher)
    print(f"Existing Timetables for {teacher.first_name}: {timetables.count()}")

if __name__ == "__main__":
    check_data()
