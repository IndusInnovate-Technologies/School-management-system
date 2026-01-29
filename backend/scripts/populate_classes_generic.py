import os
import sys
import django
import traceback

# Setup Django environment
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
from super_admin.models import School

# Use relative path for log
LOG_FILE = 'backend/generic_population_log.txt'

def log(msg):
    print(msg)
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(msg + '\n')
    except:
        pass

def populate_classes_generic():
    try:
        with open(LOG_FILE, 'w') as f:
            f.write("Starting generic population...\n")

        # 1. Identify Target School
        # We need a school ID to link the classes to.
        # Strategy: Get the first school found.
        school = School.objects.first()
        
        if not school:
            log("ERROR: No schools found in the database. Cannot create classes.")
            return

        log(f"Target School: {school.school_name} (ID: {school.school_id})")

        # 2. Define Classes "Nursery..10" and "A..D"
        class_names = ['Nursery', 'LKG', 'UKG'] + [f"Class {i}" for i in range(1, 11)]
        sections = ['A', 'B', 'C', 'D']
        academic_year = '2025-2026'

        created_count = 0
        updated_count = 0

        for name in class_names:
            for section in sections:
                # Find existing class in this school
                # Note: Class model has school_id field but filtering usually done by name+section+year
                # We should ensure we don't duplicate if it exists.
                class_obj = Class.objects.filter(
                    name=name, 
                    section=section, 
                    academic_year=academic_year
                ).first()

                if class_obj:
                    # If exists, ensure school_id matches (fix data if inconsistent)
                    if class_obj.school_id != school.school_id:
                        log(f"  [UPDATE SCHOOL] {name}-{section}")
                        class_obj.school_id = school.school_id
                        class_obj.school_name = school.school_name
                        class_obj.save()
                        updated_count += 1
                    else:
                        # log(f"  [SKIP] {name}-{section} exists.")
                        pass
                else:
                    # Create new class
                    # We create WITHOUT a teacher if we want it generic.
                    # But we MUST set school_id manually because save() logic depends on teacher otherwise.
                    new_class = Class(
                        name=name,
                        section=section,
                        academic_year=academic_year,
                        teacher=None, # Explicitly no teacher
                        school_id=school.school_id,
                        school_name=school.school_name
                    )
                    new_class.save()
                    log(f"  [CREATED] {name}-{section}")
                    created_count += 1

        log("-" * 30)
        log(f"Total: Created {created_count}, Updated {updated_count} classes for school {school.school_name}")
        log("DONE_SUCCESS")

    except Exception as e:
        log(f"CRITICAL ERROR: {e}")
        log(traceback.format_exc())

if __name__ == "__main__":
    populate_classes_generic()
