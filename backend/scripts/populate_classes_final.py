import os
import sys
import django
import traceback

# Setup Django environment
# Ensure we add the 'backend' folder to sys.path so 'school_backend' module is found
backend_path = os.path.join(os.getcwd(), 'backend')
if backend_path not in sys.path:
    sys.path.append(backend_path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
try:
    django.setup()
except Exception as e:
    print(f"Django setup failed: {e}")
    sys.exit(1)

from management_admin.models import Teacher
from teacher.models import Class
from main_login.models import User

# Use relative path for log
LOG_FILE = 'backend/final_population_log.txt'

def log(msg):
    print(msg)
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(msg + '\n')
    except:
        pass

def populate_classes_final():
    try:
        with open(LOG_FILE, 'w') as f:
            f.write("Starting final population...\n")

        # 1. Identify Target Teacher
        teacher = None
        
        # Try 'pandey'
        user = User.objects.filter(username__icontains='pandey').first()
        if user:
            teacher = Teacher.objects.filter(user=user).first()
            if teacher:
                log(f"Selected Teacher via User 'pandey': {teacher.first_name}")

        # Try 'hussain' if no pandey
        if not teacher:
            teacher = Teacher.objects.filter(first_name__icontains='hussain').first()
            if teacher:
                log(f"Selected Teacher via Name 'hussain': {teacher.first_name}")
                
        # Fallback to first
        if not teacher:
            teacher = Teacher.objects.first()
            if teacher:
                log(f"Selected First Available Teacher: {teacher.first_name}")

        if not teacher:
            log("ERROR: No teachers found. Aborting.")
            return

        log(f"Target Teacher: {teacher.first_name} {teacher.last_name} (ID: {teacher.pk})")

        # 2. Define Classes "Nursery..10" and "A..D"
        # Names: "Nursery", "LKG", "UKG", "Class 1" ... "Class 10"
        class_names = ['Nursery', 'LKG', 'UKG'] + [f"Class {i}" for i in range(1, 11)]
        sections = ['A', 'B', 'C', 'D']
        academic_year = '2025-2026'

        created_count = 0
        updated_count = 0

        for name in class_names:
            for section in sections:
                # Find existing class
                class_obj = Class.objects.filter(
                    name=name, 
                    section=section, 
                    academic_year=academic_year
                ).first()

                if class_obj:
                    # If exists, ensure it is assigned to OUR teacher
                    if class_obj.teacher != teacher:
                        log(f"  [RE-ASSIGN] {name}-{section} (was {class_obj.teacher})")
                        class_obj.teacher = teacher
                        class_obj.save()
                        updated_count += 1
                else:
                    # Create
                    Class.objects.create(
                        name=name, 
                        section=section, 
                        academic_year=academic_year,
                        teacher=teacher
                    )
                    log(f"  [CREATED] {name}-{section}")
                    created_count += 1

        log("-" * 30)
        log(f"Total: Created {created_count}, Re-assigned {updated_count}")
        log("DONE_SUCCESS")

    except Exception as e:
        log(f"CRITICAL ERROR: {e}")
        log(traceback.format_exc())

if __name__ == "__main__":
    populate_classes_final()
