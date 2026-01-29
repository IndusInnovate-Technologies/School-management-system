#!/usr/bin/env python
"""
Test script to create sample teachers and students, then test API endpoints
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User, Role
from super_admin.models import School
from management_admin.models import Teacher, Student

def create_test_data():
    """Create sample teachers and students for testing"""
    
    # Get or create school
    school, created = School.objects.get_or_create(
        name='Test School',
        defaults={'location': 'Test Location', 'status': 'active'}
    )
    print(f"School: {school.name} ({'created' if created else 'existing'})")
    
    # Get or create management_admin role
    role, created = Role.objects.get_or_create(
        name='management_admin',
        defaults={'description': 'Management Admin'}
    )
    print(f"Role: {role.name} ({'created' if created else 'existing'})")
    
    # Create test teachers
    teacher_count = 0
    for i in range(3):
        user, created = User.objects.get_or_create(
            username=f'teacher{i}',
            defaults={
                'email': f'teacher{i}@school.com',
                'first_name': f'Teacher',
                'last_name': f'{i}',
                'phone': f'555000{i}',
                'role': role,
                'is_active': True,
            }
        )
        
        teacher, created = Teacher.objects.get_or_create(
            user=user,
            defaults={
                'school': school,
                'employee_id': f'EMP{1000+i}',
                'designation': 'Mathematics',
                'hire_date': '2023-01-01',
                'phone': f'555000{i}',
                'email': f'teacher{i}@school.com',
                'address': f'{100+i} Teacher Street',
                'experience': '5',
                'qualifications': 'B.Ed, M.Sc',
                'specializations': 'Mathematics, Science',
                'class_teacher': f'Class {i}A',
            }
        )
        if created:
            teacher_count += 1
    
    print(f"Teachers created: {teacher_count}")
    
    # Create test students
    student_count = 0
    for i in range(3):
        user, created = User.objects.get_or_create(
            username=f'student{i}',
            defaults={
                'email': f'student{i}@school.com',
                'first_name': f'Student',
                'last_name': f'{i}',
                'phone': f'555100{i}',
                'role': role,
                'is_active': True,
            }
        )
        
        student, created = Student.objects.get_or_create(
            user=user,
            defaults={
                'school': school,
                'student_id': f'STU{2000+i}',
                'class_name': f'Class {i}A',
                'section': 'A',
                'admission_date': '2023-06-01',
                'date_of_birth': '2008-01-01',
                'gender': 'Male',
                'blood_group': 'O+',
                'address': f'{200+i} Student Street',
                'emergency_contact': f'555200{i}',
                'medical_info': 'No allergies',
                'parent_name': f'Parent {i}',
                'parent_phone': f'555300{i}',
            }
        )
        if created:
            student_count += 1
    
    print(f"Students created: {student_count}")
    
    # Test API retrieval
    print("\n--- Testing API Data ---")
    print(f"Total Teachers in DB: {Teacher.objects.count()}")
    print(f"Total Students in DB: {Student.objects.count()}")

if __name__ == '__main__':
    create_test_data()
