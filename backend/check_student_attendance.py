
import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Attendance
from main_login.models import User

emails = ['krishna@student.com', 'twinkle@student.com']

with open('atts_debug.txt', 'w', encoding='utf-8') as f:
    f.write("-" * 50 + "\n")
    f.write("Checking Attendance Records\n")
    f.write("-" * 50 + "\n")

    for email in emails:
        f.write(f"\nChecking for: {email}\n")
        try:
            # Try to find student by email directly first
            students = Student.objects.filter(email=email)
            
            if not students.exists():
                f.write(f"  X Student profile not found directly with email {email}\n")
                # Try to find by User
                users = User.objects.filter(email=email)
                if not users.exists():
                     f.write(f"  X User account not found with email {email}\n")
                     continue
                
                user = users.first()
                students = Student.objects.filter(user=user)
                if not students.exists():
                    f.write(f"  X Student profile not linked to User {user.username}\n")
                    continue
                
                if students.count() > 1:
                     f.write(f"  ! WARNING: Multiple students ({students.count()}) linked to User {user.username}\n")
            
            student = students.first()
            f.write(f"  ✓ Found Student: {student.student_name} (ID: {student.student_id})\n")
            f.write(f"    - Linked User: {student.user.username if student.user else 'NONE'}\n")
            f.write(f"    - Class: '{student.applying_class}', Section: '{student.section}'\n")
            f.write(f"    - School ID: {student.school_id}\n")
            
            # Check attendance
            records = Attendance.objects.filter(student=student)
            count = records.count()
            f.write(f"  ✓ Found {count} attendance records\n")
            
            for record in records:
                f.write(f"    - Date: {record.date}, Status: {record.status}, Marked By: {record.marked_by}\n")
                
        except Exception as e:
            f.write(f"  ! Error: {e}\n")

    f.write("-" * 50 + "\n")
