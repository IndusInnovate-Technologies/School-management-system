import os
import sys
import django

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Teacher
from teacher.models import Class
from main_login.models import User

def diagnose():
    try:
        user = User.objects.filter(username__icontains='pandey').first()
        print(f"User: {user}")
        if user:
            teacher = Teacher.objects.filter(user=user).first()
            print(f"Teacher: {teacher}")
            if teacher:
                print(f"  Department: {teacher.department}")
                if teacher.department:
                    print(f"  School: {teacher.department.school}")
                else:
                    print("  No Department linked!")
            else:
                print("  No Teacher profile linked!")
        
        print("-" * 20)
        print(f"Total Classes: {Class.objects.count()}")
        classes = Class.objects.all().order_by('name', 'section')
        for c in classes:
            print(f"Class: '{c.name}' | Section: '{c.section}' | Teacher: {c.teacher} | ID: {c.id}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    diagnose()
