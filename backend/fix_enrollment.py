
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Class, ClassStudent

def fix_enrollment():
    print("--- Fixing Student Enrollment ---")
    
    students = Student.objects.all()
    
    for student in students:
        # Check if already enrolled
        if student.student_classes.exists():
            print(f"Skipping {student.student_name}: Already enrolled in {student.student_classes.count()} classes.")
            continue
            
        print(f"\nProcessing {student.student_name} (Applying Class: '{student.applying_class}')")
        
        # normalized class name matcher
        # applying_class might be "Class 5", "5", "Grade 5"
        # We try to match with Class objects
        
        target_class_str = student.applying_class.strip() if student.applying_class else ""
        if not target_class_str:
             print("  -> No applying_class specified.")
             continue

        # Try to find a matching Class (Section A preferred, or any)
        # Assuming Class name format "Class 5" or "5"
        
        # Simple extraction: if "5" in string
        import re
        # Extract number
        number_match = re.search(r'\d+', target_class_str)
        if not number_match:
            print("  -> Could not extract class number.")
            continue
            
        class_num = number_match.group(0) # e.g. "5"
        
        # Search for available classes for this number
        # Try exact match first on name "Class 5" or "5"
        
        potential_classes = Class.objects.filter(name__icontains=class_num).order_by('section')
        
        if not potential_classes.exists():
            print(f"  -> No classes found matching number '{class_num}'.")
            continue
            
        # Pick the first one (usually Section A)
        target_class = potential_classes.first()
        
        print(f"  -> Found class: {target_class.name} - {target_class.section} (ID: {target_class.id})")
        
        # Enroll
        ClassStudent.objects.create(
            student=student,
            class_obj=target_class,
            school_id=target_class.school_id,
            school_name=target_class.school_name
        )
        print(f"  [SUCCESS] Enrolled {student.student_name} in {target_class.name} - {target_class.section}")

if __name__ == "__main__":
    fix_enrollment()
