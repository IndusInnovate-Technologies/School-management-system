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

username = 'pandey'
print(f"--- CHECKING USER: {username} ---")

try:
    user = User.objects.filter(username=username).first()
    if user:
        print(f"User Found: {user.username} (PK: {user.pk})")
        teacher = Teacher.objects.filter(user=user).first()
        if teacher:
            print(f"  - Teacher Profile Found: {teacher} (ID: {teacher.pk})")
            classes = Class.objects.filter(teacher=teacher)
            print(f"  - Assigned Classes: {classes.count()}")
            for cls in classes:
                print(f"    - {cls.name} {cls.section}")
        else:
             print("  - No Teacher Profile")
    else:
        print(f"User '{username}' NOT FOUND.")
        
except Exception as e:
    print(f"Error: {e}")
