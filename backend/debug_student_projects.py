
import os
import django
import sys

# Setup Django environment
sys.path.append(r'c:\Users\Admin\Desktop\testing_main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from management_admin.models import Student
from teacher.models import Class, ClassStudent, Project
from student_parent.models import Parent

User = get_user_model()
email = "harika.k@gmail.com"

print(f"--- Debugging for User: {email} ---")

try:
    user = User.objects.get(email=email)
    print(f"User Found: {user}")
except User.DoesNotExist:
    print("User not found!")
    sys.exit()

# Simulate StudentProjectViewSet.get_queryset
print("\n--- Simulating Student Logic ---")
try:
    student = Student.objects.get(user=user)
    print(f"Student Profile Found: {student.student_name}")
    print(f"Applying Class: '{student.applying_class}'")
    
    # 1. Check Explicit Enrollment
    class_ids = list(ClassStudent.objects.filter(student=student).values_list('class_obj_id', flat=True))
    print(f"Explicit Class IDs: {class_ids}")
    
    # 2. Check Fallback
    if not class_ids:
        print("No explicit enrollment. Checking fallback...")
        if student.applying_class:
            class_name = student.applying_class.lower().replace('class', '').strip()
            print(f"Normalized Class Name: '{class_name}'")
            
            # Exact match
            matched_classes_exact = Class.objects.filter(name__iexact=class_name)
            print(f"Exact Matches: {list(matched_classes_exact)}")
            
            # Contains match
            matched_classes_contains = Class.objects.filter(name__icontains=class_name)
            print(f"Contains Matches: {list(matched_classes_contains)}")
            
            final_class_ids = []
            if matched_classes_exact.exists():
                final_class_ids.extend(matched_classes_exact.values_list('id', flat=True))
            if not matched_classes_exact.exists() and class_name and matched_classes_contains.exists():
                final_class_ids.extend(matched_classes_contains.values_list('id', flat=True))
            
            print(f"Final Fallback Class IDs: {final_class_ids}")
            
            # 3. Check Projects
            if final_class_ids:
                projects = Project.objects.filter(class_obj_id__in=final_class_ids)
                print(f"Projects Found: {projects.count()}")
                for p in projects:
                    print(f" - {p.title} (Class ID: {p.class_obj_id})")
            else:
                print("No classes matched.")
        else:
            print("No applying_class set.")
            
except Student.DoesNotExist:
    print("No Student profile found for this user.")

# Simulate Parent Logic (just in case)
print("\n--- Simulating Parent Logic ---")
try:
    parent = Parent.objects.get(user=user)
    print(f"Parent Profile Found: {parent}")
    # ... (Parent logic same as verification) ...
except Parent.DoesNotExist:
    print("No Parent profile found for this user.")
