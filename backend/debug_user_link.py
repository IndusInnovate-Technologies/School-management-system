
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from main_login.models import User

def check_user_link():
    print("--- Checking User-Student Link for k@std.com ---")
    
    email = "k@std.com"
    
    # Check User
    try:
        user = User.objects.get(email=email)
        print(f"User found: {user.username} (ID: {user.user_id}, Email: {user.email})")
    except User.DoesNotExist:
        print(f"User with email {email} NOT FOUND.")
        user = None

    # Check Student
    try:
        student = Student.objects.get(email=email)
        print(f"Student found: {student.student_name} (PK: {student.pk}, Student ID: {student.student_id})")
        
        if student.user:
            print(f"  Linked User: {student.user.username} (ID: {student.user.user_id})")
            if user and student.user == user:
                print("  [OK] Student is correctly linked to the User.")
            else:
                print("  [ERROR] Student is linked to a DIFFERENT User!")
        else:
             print("  [ERROR] Student has NO User linked!")
             
             if user:
                 print("  -> Attempting to link now...")
                 student.user = user
                 student.save()
                 print("  [FIXED] Linked User to Student.")
                 
    except Student.DoesNotExist:
        print(f"Student with email {email} NOT FOUND.")

if __name__ == "__main__":
    check_user_link()
