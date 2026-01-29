
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

print(f"DEBUG_START")
try:
    user = User.objects.get(email=email)
    print(f"User: {user.email}")
    
    # Check Student
    try:
        student = Student.objects.get(user=user)
        print(f"Student: {student.student_name}, Class: {student.applying_class}")
        
        # 1. Explicit
        class_ids = list(ClassStudent.objects.filter(student=student).values_list('class_obj_id', flat=True))
        print(f"Explicit IDs: {class_ids}")
        
        # 2. Fallback
        if not class_ids and student.applying_class:
            c_name = student.applying_class.lower().replace('class', '').strip()
            print(f"Fallback Name: '{c_name}'")
            matches = Class.objects.filter(name__icontains=c_name)
            fallback_ids = list(matches.values_list('id', flat=True))
            print(f"Fallback IDs: {fallback_ids}")
            
            # 3. Projects
            if fallback_ids:
                projs = Project.objects.filter(class_obj_id__in=fallback_ids)
                print(f"Projects Count: {projs.count()}")
    except Student.DoesNotExist:
        print("No Student found")

    # Check Parent logic
    try:
        parent = Parent.objects.get(user=user)
        print(f"Parent: {parent.id}, School ID: {parent.school_id}")
        
        # Check Project School IDs
        all_proj_school_ids = set()

        for s in parent.students.all():
            print(f"Child: {s.student_name}, Class: {s.applying_class}")
            # Same logic...
            c_name = s.applying_class.lower().replace('class', '').strip()
            matches = Class.objects.filter(name__icontains=c_name)
            f_ids = list(matches.values_list('id', flat=True))
            print(f"Child Fallback IDs: {f_ids}")
            
            projs = Project.objects.filter(class_obj_id__in=f_ids)
            p_count = projs.count()
            print(f"Child Projects Found (Raw): {p_count}")
            
            for p in projs[:1]:
                print(f" -- Project: {p.title}, ID: {p.id} ({type(p.id)}), PK Type: {Project._meta.pk.get_internal_type()}")
                all_proj_school_ids.add(p.school_id)
        
        print(f"\n--- School ID Mismatch Check ---")
        print(f"Parent School ID: {parent.school_id}")
        print(f"Project School IDs: {all_proj_school_ids}")
        
        if parent.school_id not in all_proj_school_ids:
             print("MISMATCH DETECTED: Parent cannot see projects from other schools due to SchoolFilterMixin!")
        else:
             print("School IDs match.")

    except Parent.DoesNotExist:
        print("No Parent found")

        
except Exception as e:
    print(f"Error: {e}")
print(f"DEBUG_END")
