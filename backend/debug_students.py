
import os
import django
import sys

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student, NewAdmission

def list_students():
    with open('students_list.txt', 'w') as f:
        students = Student.objects.all()
        f.write(f"Total students: {students.count()}\n")
        for s in students:
            f.write(f"ID: {s.student_id}, Name: {s.student_name}, Class: {s.applying_class}, Section: {s.section}, Email: {s.email}, Created: {s.created_at}\n")
        
        admissions = NewAdmission.objects.all()
        f.write(f"\nTotal NewAdmissions: {admissions.count()}\n")
        for a in admissions:
            f.write(f"ID: {a.student_id}, Name: {a.student_name}, Email: {a.email}, Status: {a.status}, Created: {a.created_at}\n")

if __name__ == '__main__':
    list_students()
