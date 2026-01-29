import os
import sys
import django
import traceback

# Setup Django environment
# Assume running from project root (c:\Users\D-IT\Desktop\laptop)
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Teacher
from teacher.models import Class
from main_login.models import User

# Use relative path for log
LOG_FILE = 'backend/population_log_v3.txt'

def log(msg):
    print(msg)
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(msg + '\n')
    except Exception as e:
        print(f"Failed to write to log: {e}")

def populate_classes_v3():
    try:
        # Clear log
        with open(LOG_FILE, 'w') as f:
            f.write("Starting population v3...\n")

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
        
        # 2. Define Classes and Sections
        # Standardizing on "Class X"
        class_names = ['Nursery', 'LKG', 'UKG'] + [f"Class {i}" for i in range(1, 11)]
        sections = ['A', 'B', 'C', 'D']
        academic_year = '2025-2026'

        created_count = 0
        updated_count = 0

        for name in class_names:
            for section in sections:
                class_obj = Class.objects.filter(
                    name=name, 
                    section=section, 
                    academic_year=academic_year
                ).first()

                if class_obj:
                    if class_obj.teacher != teacher:
                        old_teacher = class_obj.teacher
                        class_obj.teacher = teacher
                        class_obj.save()
                        log(f"  [UPDATED] {name}-{section}")
                        updated_count += 1
                else:
                    Class.objects.create(
                        name=name,
                        section=section,
                        academic_year=academic_year,
                        teacher=teacher,
                    )
                    log(f"  [CREATED] {name}-{section}")
                    created_count += 1

        log("-" * 30)
        log(f"Summary: Created {created_count} classes. Updated {updated_count} classes.")
        log("Done.")
        
    except Exception as e:
        log(f"CRITICAL ERROR: {e}")
        log(traceback.format_exc())

if __name__ == "__main__":
    populate_classes_v3()
