
import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Teacher

teacher = Teacher.objects.filter(employee_no='EMPN-001').first()
if teacher:
    print(f"Teacher: {teacher.first_name} {teacher.last_name}")
    print(f"Employee No: {teacher.employee_no}")
    print(f"School ID: {teacher.school_id}")
else:
    print("Teacher EMPN-001 not found")
