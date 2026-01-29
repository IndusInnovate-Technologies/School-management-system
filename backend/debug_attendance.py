
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Attendance, Class

def debug_attendance():
    print("--- Debugging Attendance ---")
    
    students = Student.objects.all()
    print(f"Total Students: {students.count()}")
    
    for student in students:
        print(f"\nStudent: {student.student_name} (ID: {student.student_id})")
        
        # Check overall attendance count
        attendance_records = Attendance.objects.filter(student=student)
        print(f"  Total Attendance Records: {attendance_records.count()}")
        
        if attendance_records.exists():
            # Show last few records
            last_records = attendance_records.order_by('-date')[:5]
            for record in last_records:
                print(f"    - Date: {record.date}, Status: {record.status}, Class: {record.class_obj}")
        else:
             print("  [!] No attendance records found.")
             
        # Check enrolled classes
        student_classes = student.student_classes.all()
        if not student_classes.exists():
            print("  [!] Student NOT enrolled in any class")
        else:
            for link in student_classes:
                 if hasattr(link, 'class_obj'):
                     cls = link.class_obj
                 else:
                     cls = link
                 
                 print(f"  Enrolled in: {cls.name} - {cls.section}")

if __name__ == "__main__":
    debug_attendance()
