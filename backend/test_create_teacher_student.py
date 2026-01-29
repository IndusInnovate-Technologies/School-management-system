#!/usr/bin/env python
"""
Test script to verify API endpoints for creating teachers and students
"""
import os
import sys
import django
import requests
import json
from datetime import datetime

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from super_admin.models import School
from main_login.models import User

BASE_URL = 'http://localhost:8000/api/management-admin'

def get_or_create_school():
    """Get or create a default school"""
    school, created = School.objects.get_or_create(
        name='Test School',
        defaults={
            'code': 'TS001',
            'address': '123 School Street',
            'phone': '1234567890',
            'email': 'school@test.com',
        }
    )
    return school

def test_create_teacher():
    """Test creating a teacher via API"""
    print("\n--- Testing Teacher Creation ---")
    school = get_or_create_school()
    
    teacher_data = {
        'school': school.id,
        'employee_id': f'EMP-{datetime.now().timestamp()}',
        'first_name': 'John',
        'last_name': 'Doe',
        'username': 'john_doe_teacher',
        'email_user': 'john.doe@school.com',
        'designation': 'Mathematics Teacher',
        'phone': '9876543210',
        'email': 'john.doe@school.com',
        'address': '456 Teacher Lane',
        'experience': '5',
        'qualifications': 'B.Tech, M.Ed',
        'specializations': 'Algebra, Geometry',
        'class_teacher': 'Class A',
    }
    
    print(f"Posting teacher data: {json.dumps(teacher_data, indent=2)}")
    response = requests.post(
        f'{BASE_URL}/teachers/',
        json=teacher_data,
        headers={'Content-Type': 'application/json'}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code in [200, 201]:
        teacher = response.json()
        print(f"✓ Teacher created successfully: {teacher.get('id')}")
        return teacher
    else:
        print(f"✗ Failed to create teacher")
        return None

def test_create_student():
    """Test creating a student via API"""
    print("\n--- Testing Student Creation ---")
    school = get_or_create_school()
    
    student_data = {
        'school': school.id,
        'student_id': f'STU-{datetime.now().timestamp()}',
        'first_name': 'Jane',
        'last_name': 'Smith',
        'username': 'jane_smith_student',
        'email_user': 'jane.smith@school.com',
        'class_name': 'Grade 10',
        'section': 'A',
        'gender': 'Female',
        'blood_group': 'O+',
        'address': '789 Student Avenue',
        'date_of_birth': '2008-05-15',
        'parent_name': 'Mr. Smith',
        'parent_phone': '8765432109',
        'emergency_contact': '8765432108',
        'medical_info': 'No allergies',
        'admission_date': '2023-06-01',
    }
    
    print(f"Posting student data: {json.dumps(student_data, indent=2)}")
    response = requests.post(
        f'{BASE_URL}/students/',
        json=student_data,
        headers={'Content-Type': 'application/json'}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code in [200, 201]:
        student = response.json()
        print(f"✓ Student created successfully: {student.get('id')}")
        return student
    else:
        print(f"✗ Failed to create student")
        return None

def test_fetch_teachers():
    """Test fetching teachers"""
    print("\n--- Testing Fetch Teachers ---")
    response = requests.get(
        f'{BASE_URL}/teachers/',
        headers={'Content-Type': 'application/json'}
    )
    
    print(f"Status Code: {response.status_code}")
    data = response.json()
    if isinstance(data, list):
        print(f"✓ Fetched {len(data)} teachers")
    elif isinstance(data, dict) and 'results' in data:
        print(f"✓ Fetched {len(data['results'])} teachers")
    else:
        print(f"Response: {response.text}")

def test_fetch_students():
    """Test fetching students"""
    print("\n--- Testing Fetch Students ---")
    response = requests.get(
        f'{BASE_URL}/students/',
        headers={'Content-Type': 'application/json'}
    )
    
    print(f"Status Code: {response.status_code}")
    data = response.json()
    if isinstance(data, list):
        print(f"✓ Fetched {len(data)} students")
    elif isinstance(data, dict) and 'results' in data:
        print(f"✓ Fetched {len(data['results'])} students")
    else:
        print(f"Response: {response.text}")

if __name__ == '__main__':
    try:
        test_create_teacher()
        test_create_student()
        test_fetch_teachers()
        test_fetch_students()
        print("\n✓ All tests completed!")
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
