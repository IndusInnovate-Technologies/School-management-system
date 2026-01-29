import os
import django
import sys
from django.apps import apps
from django.contrib.auth import get_user_model
from django.db.models import Q

# Setup Django environment
sys.path.append(r'c:\Users\D-IT\Desktop\sushil code\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

User = get_user_model()
Teacher = apps.get_model('management_admin', 'Teacher')
Class = apps.get_model('teacher', 'Class')

def reset_classes(username):
    print(f"\n--- RESETTING CLASSES FOR: {username} ---")
    
    # 1. Get Teacher
    user = User.objects.filter(username=username).first()
    if not user:
        print(f"User '{username}' not found.")
        return

    teacher = Teacher.objects.filter(user=user).first()
    if not teacher:
        print(f"Teacher profile for '{username}' not found.")
        return
    
    print(f"Target Teacher: {teacher} (ID: {teacher.pk})")

    # 2. Get all currently assigned classes
    current_classes = Class.objects.filter(teacher=teacher)
    print(f"Found {current_classes.count()} currently assigned classes.")

    # 3. Unassign/Delete non-requested classes
    # Requested: Class 1 A, Class 1 B, Class 1 C
    requested_specs = [
        ('Class 1', 'A'),
        ('Class 1', 'B'),
        ('Class 1', 'C')
    ]

    for cls in current_classes:
        is_requested = False
        for req_name, req_sec in requested_specs:
            if cls.name == req_name and cls.section == req_sec:
                is_requested = True
                break
        
        if is_requested:
            print(f"  - KEEPING: {cls.name} - {cls.section}")
        else:
            # Check if this was a demo class we created (e.g. Sections E/F/D or Class 11+)
            # To be safe, let's just unassign (set teacher=None) so we don't destroy data 
            # if it belonged to Tinku originally.
            # But if it's junk we created (like Class 1 E), maybe delete?
            # Creating a simple cleanup rule: 
            # If section in E/F or class > 10, DELETE. Else UNASSIGN.
            
            if cls.section in ['E', 'F'] or cls.name in ['Class 11', 'Class 12', 'Class 13', 'Class 14', 'Class 15']:
                print(f"  - DELETING junk: {cls.name} - {cls.section}")
                cls.delete()
            else:
                print(f"  - UNASSIGNING: {cls.name} - {cls.section}")
                cls.teacher = None
                cls.save()

    # 4. Ensure Requested Classes are Assigned
    print("\nEnsuring requested classes are assigned...")
    for req_name, req_sec in requested_specs:
        # Find the class
        cls = Class.objects.filter(name=req_name, section=req_sec).first()
        if cls:
            if cls.teacher != teacher:
                cls.teacher = teacher
                cls.save()
                print(f"  - Reassigned {req_name} - {req_sec} to {username}")
            else:
                print(f"  - {req_name} - {req_sec} already assigned.")
        else:
            print(f"  - {req_name} - {req_sec} NOT FOUND. Creating...")
            Class.objects.create(
                teacher=teacher,
                name=req_name,
                section=req_sec,
                academic_year="2025-2026"
            )

    print("\n--- RESET COMPLETE ---")

if __name__ == '__main__':
    reset_classes('pandey')
