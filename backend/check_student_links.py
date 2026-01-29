import os
import django
import sys

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from main_login.models import User
from management_admin.models import Student
from student_parent.models import Parent

def check_user(username):
    print(f"\n--- Checking User: {username} ---")
    user = User.objects.filter(username=username).first()
    if not user:
        print(f"User '{username}' not found.")
        return

    print(f"User ID: {user.user_id}")
    print(f"Email: {user.email}")
    print(f"Role: {user.role.name if user.role else 'None'}")
    
    # Check Parent Links
    parent = Parent.objects.filter(user=user).first()
    print(f"Parent Profile Found: {parent is not None}")
    if parent:
        students = parent.students.all()
        print(f"Students linked to Parent ({len(students)}):")
        for s in students:
            print(f"  - {s.student_name} (ID: {s.student_id}, email: {s.email})")
    
    # Check Direct Student Link
    student = Student.objects.filter(user=user).first()
    print(f"Direct Student Profile Link: {student.student_name if student else 'None'}")
    
    if student:
        classes = student.student_classes.all()
        print(f"Classes for Direct Student ({len(classes)}):")
        for sc in classes:
            print(f"  - {sc.class_obj.name} - {sc.class_obj.section} (ID: {sc.class_obj.id})")

if __name__ == "__main__":
    check_user('raosushil')
