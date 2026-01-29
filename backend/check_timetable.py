
import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Timetable
from management_admin.models import Teacher

print("Checking Timetable entries...")
timetables = Timetable.objects.all().order_by('-id')[:10]

if not timetables:
    print("No timetable entries found.")
else:
    print(f"Found {Timetable.objects.count()} total entries. Showing last 10:")
    for t in timetables:
        print(f"ID: {t.id}, Teacher: {t.teacher.first_name} (ID: {t.teacher_id}), Class: {t.class_obj.name}, Day: {t.day_of_week}, Time: {t.start_time}-{t.end_time}, Subject: {t.subject}, School: {t.school_id}")


print("\nChecking Class duplicate possibilities...")
from teacher.models import Class
classes = Class.objects.filter(name="Class 10", section="A")
for c in classes:
    print(f"Class: {c.name} {c.section} (ID: {c.id}), School: {c.school_id}")

print("\nChecking Teacher School...")
try:
    teacher = Teacher.objects.get(employee_no="EMPN-0010")
    print(f"Teacher: {teacher.first_name} (ID: {teacher.employee_no}), School: {teacher.school_id}")
except Teacher.DoesNotExist:
    print("Teacher EMPN-0010 not found")

print("\nSchools:")
from super_admin.models import School
for s in School.objects.all():
    print(f"School: {s.name} (ID: {s.school_id})")

