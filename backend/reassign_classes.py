import os
import django
import sys
from django.apps import apps
from django.contrib.auth import get_user_model

# Setup Django environment
sys.path.append(r'c:\Users\D-IT\Desktop\sushil code\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

User = get_user_model()
Teacher = apps.get_model('management_admin', 'Teacher')
Class = apps.get_model('teacher', 'Class')

def reassign_classes(username):
    print(f"\n--- REASSIGNING CLASSES TO: {username} ---")
    
    # 1. Get Target User & Teacher Profile
    user = User.objects.filter(username=username).first()
    if not user:
        print(f"User '{username}' not found.")
        return

    teacher = Teacher.objects.filter(user=user).first()
    if not teacher:
        print(f"Teacher profile for '{username}' not found.")
        return
    
    print(f"Target Teacher: {teacher} (ID: {teacher.pk})")

    # 2. Reassign Classes 1-10, Sections A, B, C, D
    target_sections = ['A', 'B', 'C', 'D']
    count = 0
    
    for i in range(1, 11):
        class_name = f"Class {i}"
        for section in target_sections:
            # Find the class regardless of who owns it
            cls = Class.objects.filter(name=class_name, section=section).first()
            if cls:
                if cls.teacher != teacher:
                    old_teacher = cls.teacher
                    cls.teacher = teacher
                    cls.save()
                    print(f"  - Reassigned {class_name} - {section} (was {old_teacher})")
                    count += 1
                else:
                    # print(f"  - {class_name} - {section} already verified.")
                    pass
            else:
                # If it doesn't exist (e.g. maybe Name was 'Grade 1'), try creating it?
                # But earlier logs showed 'Class 1 A' exists (owned by tinku)
                # and 'Class 1 D' exists (owned by indus).
                # 'Grade 1 B' exists (indus), so 'Class 1 B' might exist (tinku).
                print(f"  - {class_name} - {section} NOT FOUND. Creating...")
                Class.objects.create(
                    teacher=teacher,
                    name=class_name,
                    section=section,
                    academic_year="2025-2026"
                )
                print(f"    -> Created new.")
                count += 1

    print(f"\nTotal reassign/create operations: {count}")
    print("--- REASSIGN COMPLETE ---")

if __name__ == '__main__':
    reassign_classes('pandey')
