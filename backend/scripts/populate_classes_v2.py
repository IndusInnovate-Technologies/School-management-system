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

LOG_FILE = os.path.join(os.path.dirname(__file__), '..', 'population_log.txt')

def log(msg):
    print(msg)
    with open(LOG_FILE, 'a') as f:
        f.write(msg + '\n')

def populate_classes_v2():
    try:
        # Clear log
        with open(LOG_FILE, 'w') as f:
            f.write("Starting population...\n")

        # 1. Identify the teacher (Pandey)
        log("Searching for user 'pandey'...")
        user = User.objects.filter(username__icontains='pandey').first()
        
        teacher = None
        if user:
            log(f"Found user: {user.username}")
            teacher = Teacher.objects.filter(user=user).first()
            if teacher:
                log(f"Found linked teacher: {teacher.first_name} {teacher.last_name}")
            else:
                log("User found but no linked teacher profile.")
        else:
            log("User 'pandey' not found.")
        
        if not teacher:
            log("Falling back to the first available teacher in the database...")
            teacher = Teacher.objects.first()
            
        if not teacher:
            log("ERROR: No teachers found in the database. Cannot assign classes.")
            return

        log(f"Proceeding with Teacher: {teacher.first_name} (ID: {teacher.pk})")
        if teacher.department:
             log(f"Teacher Department: {teacher.department.name} (School: {teacher.department.school})")
        else:
             log("Teacher has no department.")

        # 2. Define Classes and Sections
        # "nursery , ukg, lkg from class 1 to 10"
        # Using "Class X" format for 1-10 to match user screenshot "Class 5"
        class_names = ['Nursery', 'LKG', 'UKG'] + [f"Class {i}" for i in range(1, 11)]
        sections = ['A', 'B', 'C', 'D']
        academic_year = '2025-2026'

        created_count = 0
        updated_count = 0

        log(f"Ensuring classes exist for identifiers: {class_names}")
        log(f"Sections: {sections}")

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
                        log(f"  [UPDATED] {name}-{section}: Reassigned from {old_teacher} to {teacher}")
                        updated_count += 1
                    else:
                        # Already assigned
                        # log(f"  [SKIP] {name}-{section} already assigned.")
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
                    log(f"  [CREATED] {name}-{section}")
                    created_count += 1

        log("-" * 30)
        log(f"Summary: Created {created_count} classes. Updated {updated_count} classes.")
        log("Done.")
        
    except Exception as e:
        log(f"CRITICAL ERROR: {e}")
        import traceback
        log(traceback.format_exc())

if __name__ == "__main__":
    populate_classes_v2()
