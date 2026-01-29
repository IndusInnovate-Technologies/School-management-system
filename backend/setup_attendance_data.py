import os
import sys
import django
import random
from datetime import date

# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student, Teacher, Department
from teacher.models import Class, ClassStudent
from super_admin.models import School

def setup_data():
    print("Starting data setup...")

    # 1. identifying School
    school = School.objects.first()
    if not school:
        print("No school found. Please create a school first.")
        return
    print(f"Using School: {school.school_name} ({school.school_id})")

    # 2. Get or Create Department
    department, created = Department.objects.get_or_create(
        name="Academic",
        school=school,
        defaults={'head_name': "Principal"}
    )
    print(f"{'Created' if created else 'Found'} Department: {department.name}")

    # 3. Get Teachers
    teachers = list(Teacher.objects.filter(school_id=school.school_id))
    if not teachers:
        print("No teachers found. Please create teachers first.")
        return
    print(f"Found {len(teachers)} Teachers.")

    # 4. Get Students
    students = list(Student.objects.filter(school_id=school.school_id))
    if not students:
        print("No students found. Please create students first.")
        return
    print(f"Found {len(students)} Students.")

    # 5. Create Classes and Assign Teachers
    # simplified: Assign 1 class per teacher for now, or just a few classes
    class_names = ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 
                   'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10']
    sections = ['A', 'B']
    
    classes_created = []

    for i, class_name in enumerate(class_names):
        for section in sections:
            # Cycle through teachers
            teacher = teachers[(i + len(sections)) % len(teachers)]
            
            cls, created = Class.objects.get_or_create(
                name=class_name,
                section=section,
                academic_year='2025-2026',
                defaults={
                    'teacher': teacher,
                    'department': department,
                    'school_id': school.school_id,
                    'school_name': school.school_name
                }
            )
            classes_created.append(cls)
            print(f"{'Created' if created else 'Found'} Class: {cls.name} - {cls.section} (Teacher: {teacher.first_name})")

    # 6. Assign Students to Classes
    # Distribute students evenly across classes
    for i, student in enumerate(students):
        assigned_class = classes_created[i % len(classes_created)]
        
        # Update student's applying_class field to match
        student.applying_class = assigned_class.name
        student.save() # This triggers school_id check but we already filtered by school

        # Create ClassStudent link
        link, created = ClassStudent.objects.get_or_create(
            class_obj=assigned_class,
            student=student,
            defaults={
                'school_id': school.school_id,
                'school_name': school.school_name
            }
        )
        if created:
             print(f"Assigned {student.student_name} to {assigned_class.name}-{assigned_class.section}")

    print("Data setup complete.")

if __name__ == '__main__':
    setup_data()
