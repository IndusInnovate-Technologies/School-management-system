import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) # Go up one level to 'backend'
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Teacher

def check_and_fix_venu():
    try:
        # filter by first_name usually, or user email
        venu = Teacher.objects.filter(first_name__icontains='venu').first()
        if not venu:
            print("Teacher 'Venu' not found!")
            return

        print(f"Teacher: {venu.first_name} {venu.last_name}")
        print(f"Is Class Teacher: {venu.is_class_teacher}")
        print(f"Assigned Class: {venu.class_teacher_class}")
        print(f"Assigned Section: {venu.class_teacher_section}")
        print("-" * 20)

        # Fix it if needed
        # We know from logs that students are in "Class 5" - "B"
        if not venu.is_class_teacher:
            print("Fixing: Setting is_class_teacher = True")
            venu.is_class_teacher = True
        
        if venu.class_teacher_class != 'Class 5':
            print(f"Fixing: Setting class_teacher_class = 'Class 5' (was {venu.class_teacher_class})")
            venu.class_teacher_class = 'Class 5'
            
        if venu.class_teacher_section != 'B':
            print(f"Fixing: Setting class_teacher_section = 'B' (was {venu.class_teacher_section})")
            venu.class_teacher_section = 'B'

        venu.save()
        print("Updated Venu's profile successfully.")
        
        # Verify
        venu.refresh_from_db()
        print(f"VERIFICATION -> Is Class Teacher: {venu.is_class_teacher}, Class: {venu.class_teacher_class}, Section: {venu.class_teacher_section}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_and_fix_venu()
