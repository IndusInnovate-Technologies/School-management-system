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
# Class is defined in teacher/models.py, so it belongs to 'teacher' app
Class = apps.get_model('teacher', 'Class')

output_path = r'c:\Users\D-IT\Desktop\sushil code\backend\output.txt'

with open(output_path, 'w') as f:
    f.write("--- USERS & TEACHER PROFILES ---\n")
    try:
        count = 0
        for user in User.objects.all():
            # Only print for specific users to reduce noise if many users exist
            if user.username in ['sairam', 'indus', 'tinku'] or user.email.startswith('indus'):
                count += 1
                f.write(f"User: {user.username} (PK: {user.pk})\n")
                try:
                    teacher = Teacher.objects.filter(user=user).first()
                    if teacher:
                        f.write(f"  - Teacher Profile Found: {teacher} (ID: {teacher.pk})\n")
                        classes = Class.objects.filter(teacher=teacher)
                        f.write(f"  - Assigned Classes: {classes.count()}\n")
                        for cls in classes:
                            f.write(f"    - {cls.name} {cls.section}\n")
                    else:
                        f.write("  - No Teacher Profile\n")
                except Exception as e:
                    f.write(f"  - Error checking teacher: {e}\n")
        
        if count == 0:
            f.write("No matching users found (sairam, indus, tinku).\n")
            
    except Exception as e:
        f.write(f"Error iterating users: {e}\n")

    f.write("\n--- ALL CLASSES ---\n")
    try:
        for cls in Class.objects.all():
            teacher_name = "None"
            if cls.teacher:
                try:
                    if cls.teacher.user:
                        teacher_name = cls.teacher.user.username
                    else:
                        teacher_name = "Teacher(NoUser)"
                except Exception:
                    teacher_name = "ErrorAccessingUser"
                
            f.write(f"Class: {cls.name} {cls.section} (Teacher: {teacher_name})\n")
    except Exception as e:
        f.write(f"Error iterating classes: {e}\n")
