
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student

def check_class_5():
    print("--- Inspecting Class 5 Students ---")
    # Search for variations
    c5_students = Student.objects.filter(applying_class__icontains="5")
    print(f"Total students matching '5' in class: {c5_students.count()}")
    
    for s in c5_students:
        print(f"Student: {s.student_name} | Class: '{s.applying_class}' | SchoolID: '{s.school_id}'")

    print("\n--- Teacher School ID (from logs) ---")
    print("Expected Teacher School: KAKP6878787878887 (venu)")

if __name__ == "__main__":
    check_class_5()
