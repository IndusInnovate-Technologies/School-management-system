import os
import sys
import django

# Setup Django environment
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Teacher
from teacher.models import Class
from main_login.models import User

def populate_classes():
    # 1. Identify the teacher (Pandey)
    print("Searching for user 'pandey'...")
    user = User.objects.filter(username__icontains='pandey').first()
    
    teacher = None
    if user:
        print(f"Found user: {user.username}")
        teacher = Teacher.objects.filter(user=user).first()
        if teacher:
            print(f"Found linked teacher: {teacher.first_name} {teacher.last_name}")
        else:
            print("User found but no linked teacher profile.")
    else:
        print("User 'pandey' not found.")
    
    if not teacher:
        print("Falling back to the first available teacher in the database...")
        teacher = Teacher.objects.first()
        
    if not teacher:
        print("ERROR: No teachers found in the database. Cannot assign classes.")
        return

    print(f"Proceeding with Teacher: {teacher.first_name} (ID: {teacher.pk})")

    # 2. Define Classes and Sections
    # "nursery , ukg, lkg from class 1 to 10"
    class_names = ['Nursery', 'LKG', 'UKG'] + [str(i) for i in range(1, 11)]
    sections = ['A', 'B', 'C', 'D']
    academic_year = '2025-2026'

    created_count = 0
    updated_count = 0

    print(f"Ensuring classes exist for identifiers: {class_names}")
    print(f"Sections: {sections}")

    for name in class_names:
        for section in sections:
            # Check if class exists (Unique constraint on name+section+academic_year)
            class_obj = Class.objects.filter(
                name=name, 
                section=section, 
                academic_year=academic_year
            ).first()

            if class_obj:
                # Class exists
                if class_obj.teacher != teacher:
                    # Reassign to this teacher
                    old_teacher = class_obj.teacher
                    class_obj.teacher = teacher
                    class_obj.save()
                    print(f"  [UPDATED] {name}-{section}: Reassigned from {old_teacher} to {teacher}")
                    updated_count += 1
                else:
                    # Already assigned
                    # print(f"  [SKIP] {name}-{section} already assigned.")
                    pass
            else:
                # Create new class
                Class.objects.create(
                    name=name,
                    section=section,
                    academic_year=academic_year,
                    teacher=teacher,
                    # Optional: school_id will be auto-populated by save() method if teacher has one
                )
                print(f"  [CREATED] {name}-{section}")
                created_count += 1

    print("-" * 30)
    print(f"Summary: Created {created_count} classes. Reassigned {updated_count} classes.")
    print("Done.")

if __name__ == "__main__":
    populate_classes()
