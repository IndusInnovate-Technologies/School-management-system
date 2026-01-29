
import os
import django
import sys

# Setup Django environment
sys.path.append(r'c:\Users\Admin\Desktop\testing_main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Class, ClassStudent, Project, Task
from django.contrib.auth import get_user_model
User = get_user_model()

def debug_data():
    print("--- DEBUGGING DATA VISIBILITY ---")
    
    # 1. List all Users and linked Students
    print("\n1. Users & Students:")
    students = Student.objects.all()
    for s in students:
        user_email = s.user.email if s.user else "No User Linked"
        print(f"Student: {s.student_name} (Email: {s.email}) - User: {user_email} - Class: {s.applying_class}")

    # 2. List all Classes and Enrolled Students
    print("\n2. Classes & Enrollments (ClassStudent):")
    classes = Class.objects.all()
    for c in classes:
        print(f"Class: {c.name} {c.section} (ID: {c.id})")
        enrollments = ClassStudent.objects.filter(class_obj=c)
        for e in enrollments:
            print(f"  - Student: {e.student.student_name} (Email: {e.student.email})")

    # 3. List all Projects
    print("\n3. Projects:")
    projects = Project.objects.all()
    for p in projects:
        print(f"Project: {p.title} (ID: {p.id}) - Assigned to Class ID: {p.class_obj.id} ({p.class_obj.name} {p.class_obj.section})")

    # 4. List all Tasks
    print("\n4. Tasks:")
    tasks = Task.objects.all()
    for t in tasks:
        print(f"Task: {t.title} (ID: {t.id}) - Assigned to Class ID: {t.class_obj.id} ({t.class_obj.name} {t.class_obj.section})")

if __name__ == "__main__":
    debug_data()
