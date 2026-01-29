
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Attendance, Class

def debug_one_student():
    with open("student_debug.txt", "w", encoding="utf-8") as f:
        f.write("--- Debugging Specific Students ---\n")
        
        target_emails = ['k@std.com', 'raosushil@gmail.com', 'sushilr@gmail.com']
        
        for email in target_emails:
            f.write(f"\nChecking Email: {email}\n")
            try:
                student = Student.objects.get(pk=email)
                f.write(f"  Found Student: {student.student_name} (ID: {student.student_id})\n")
                
                attendance_records = Attendance.objects.filter(student=student)
                f.write(f"  Attendance Count: {attendance_records.count()}\n")
                
                if attendance_records.exists():
                    f.write("  Last 3 Records:\n")
                    for record in attendance_records.order_by('-date')[:3]:
                        f.write(f"    - {record.date}: {record.status} ({record.class_obj})\n")
                else:
                     f.write("  [!] NO ATTENDANCE FOUND\n")
                     
                # Enrolled classes
                student_classes = student.student_classes.all()
                if student_classes.exists():
                     for link in student_classes:
                         if hasattr(link, 'class_obj'): cls = link.class_obj
                         else: cls = link
                         f.write(f"  Enrolled in: {cls.name} - {cls.section} (ID: {cls.id})\n")
                else:
                     f.write("  [!] NOT ENROLLED IN ANY CLASS\n")

            except Student.DoesNotExist:
                f.write(f"  [!] Student with email {email} NOT FOUND\n")

if __name__ == "__main__":
    debug_one_student()
