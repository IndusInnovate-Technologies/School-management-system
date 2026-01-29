import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User
from management_admin.models import Teacher
from teacher.models import Class, Exam

def debug_venu():
    output = []
    output.append("--- Debugging User 'venu' ---")
    
    # Try to find user 'venu'
    users = User.objects.filter(username__icontains='venu')
    if not users.exists():
        output.append("User 'venu' not found.")
    
    for user in users:
        output.append(f"\nUser: {user.username} (ID: {user.pk})")
        
        # Check Teacher Profile
        teachers = Teacher.objects.filter(user=user)
        if not teachers.exists():
            output.append("  No Teacher profile found linked to this user.")
            continue
            
        for teacher in teachers:
            output.append(f"  Teacher Profile: {teacher.first_name} {teacher.last_name} (ID: {teacher.pk})")
            output.append(f"    School ID: {teacher.school_id}")
            
            # Check Classes View Logic
            output.append("    [Class Logic Check]")
            if teacher.school_id:
                classes = Class.objects.filter(school_id=teacher.school_id)
                output.append(f"      Filtering by school_id={teacher.school_id}: found {classes.count()} classes")
            else:
                classes = Class.objects.filter(teacher=teacher)
                output.append(f"      Filtering by teacher={teacher.pk}: found {classes.count()} classes")
                
            # Check Exams View Logic
            output.append("    [Exam Logic Check]")
            exams = Exam.objects.filter(teacher=teacher)
            output.append(f"      Found {exams.count()} exams linked to this teacher:")

    with open('venu_short.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(output))

if __name__ == '__main__':
    debug_venu()

if __name__ == '__main__':
    debug_venu()
