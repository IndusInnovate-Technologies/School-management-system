
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student

def inspect_students():
    print("--- Inspecting Students ---")
    students = Student.objects.all()
    print(f"Total Students: {students.count()}")
    
    unique_classes = students.values_list('applying_class', flat=True).distinct()
    print(f"Unique Applying Classes: {list(unique_classes)}")
    
    unique_sections = students.values_list('section', flat=True).distinct()
    print(f"Unique Sections: {list(unique_sections)}")
    
    print("\n--- Sample Data ---")
    for s in students[:10]:
        print(f"Student: {s.student_name} | Class: '{s.applying_class}' | Section: '{s.section}' | SchoolID: '{s.school_id}'")

if __name__ == "__main__":
    inspect_students()
