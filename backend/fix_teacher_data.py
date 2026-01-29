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
Department = apps.get_model('management_admin', 'Department')
School = apps.get_model('super_admin', 'School')
Role = apps.get_model('main_login', 'Role')

def fix_user_classes(username):
    print(f"\n--- FIXING DATA FOR USER: {username} ---")
    
    # 1. Get User
    user = User.objects.filter(username=username).first()
    if not user:
        print(f"User '{username}' not found. Skipping.")
        return

    print(f"Target User: {user.username} (PK: {user.pk})")
    
    # 2. Ensure Role is Teacher
    if not user.role:
        print("User has no role. Assigning 'teacher' role...")
        teacher_role, _ = Role.objects.get_or_create(name='teacher')
        user.role = teacher_role
        user.save()
    elif user.role.name != 'teacher':
        print(f"Warning: User role is '{user.role.name}'. Proceeding anyway.")

    # 3. Get School & Department
    school = School.objects.first()
    if not school:
        school = School.objects.create(name="Indus International School", school_id="IND-SCHOOL-01", status="active")
    
    department = Department.objects.filter(school=school).first()
    if not department:
        department = Department.objects.create(school=school, name="General Science", code="GEN-SCI")

    # 4. Check/Create Teacher Profile
    teacher = Teacher.objects.filter(user=user).first()
    if not teacher:
        print("Creating Teacher profile...")
        teacher = Teacher.objects.create(
            user=user,
            employee_no=f"EMP-{username.upper()}",
            first_name=username.capitalize(),
            last_name="Teacher",
            department=department,
            email=user.email,
            is_active=True
        )
        print(f"Teacher profile created: {teacher}")
    else:
        print(f"Teacher profile exists: {teacher}")

    # 5. Assign Classes
    existing_classes = Class.objects.filter(teacher=teacher).count()
    # User requested classes 1 to 10
    print("Creating classes 1 to 10...")
    # Use E/F to avoid collision with Tinku (A/B) and Indus (C/D)
    sections = ['E', 'F']
    for i in range(1, 11): # 1 to 10
        class_name = f"Class {i}"
        section = sections[i % 2]
        # Check if exists first to avoid duplicates if run multiple times
        if not Class.objects.filter(teacher=teacher, name=class_name, section=section).exists():
            Class.objects.create(
                teacher=teacher,
                name=class_name,
                section=section,
                academic_year="2025-2026"
            )
            print(f"  - Created {class_name} Section {section}")
        else:
             print(f"  - {class_name} Section {section} already exists.")

if __name__ == '__main__':
    # Only fix pandey
    fix_user_classes('pandey')
    print("\n--- ALL FIXES COMPLETE ---")
