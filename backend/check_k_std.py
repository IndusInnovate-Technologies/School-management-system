import os
import django
import sys

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Exam

def check_student(email):
    print(f"\n--- Checking Student: {email} ---")
    student = Student.objects.filter(email=email).first()
    if not student:
        print(f"Student '{email}' not found.")
        return

    print(f"Student Name: {student.student_name}")
    print(f"Applying Class: {student.applying_class}")
    
    classes = [sc.class_obj for sc in student.student_classes.all()]
    print(f"Directly Linked Classes: {[(c.id, c.name, c.section) for c in classes]}")
    
    if not classes:
        print("No direct class links found.")
    else:
        exams = Exam.objects.filter(class_obj__in=classes)
        print(f"Total Exams for these classes: {exams.count()}")
        for e in exams:
            print(f"  - {e.title} (Class ID: {e.class_obj.id})")

if __name__ == "__main__":
    check_student('k@std.com')
    # Also check raosushil for comparison
    check_student('raosushil@gmail.com')
