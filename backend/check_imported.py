
import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Timetable
from management_admin.models import Teacher

def check_imported_data():
    print("--- CHECKING IMPORTED TIMETABLES ---")
    
    # Get the latest 10 timetable entries
    latest = Timetable.objects.all().order_by('-id')[:10]
    
    print(f"Total Timetables in DB: {Timetable.objects.count()}")
    print(f"\nLatest 10 entries:")
    
    for t in latest:
        teacher_name = f"{t.teacher.first_name} {t.teacher.last_name}" if t.teacher else "No Teacher"
        teacher_id = t.teacher.employee_no if t.teacher else "N/A"
        print(f"ID: {t.id} | Teacher: {teacher_name} ({teacher_id}) | Class: {t.class_obj} | Day: {t.day_of_week} | Time: {t.start_time} | Subject: {t.subject} | School: {t.school_id}")

if __name__ == "__main__":
    check_imported_data()
