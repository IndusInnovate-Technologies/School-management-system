import os
import django
import sys
from datetime import datetime, time, timedelta

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Examination_management, Student
from teacher.models import Class
from django.test import RequestFactory
from student_parent.views import StudentDashboardViewSet
from django.db.models import Q

def verify_student_exam_filter():
    print("--- Verifying Student Exam Filter ---")
    
    # 1. Setup Data
    # Find or Create Student A (Section A)
    student_a = Student.objects.filter(grade='A', applying_class='class-1', school_id='SCH001').first()
    if not student_a:
        # Create Dummy Student A
        pass # Assuming data exists or creating mocked request below
        print("Note: Ideally valid student data should exist.")

    # Create Exams
    # Exam 1: Class 1, Section A
    exam_sec_a = Examination_management.objects.create(
        Exam_Title="Section A Only Exam",
        Exam_Type="unit-test",
        Exam_Date=datetime.now() + timedelta(days=1),
        Exam_Time=time(10, 0),
        Exam_Duration=60,
        Exam_Marks=100,
        Exam_Class="class-1",
        Exam_Section="A",
        school_id="SCH001"
    )

    # Exam 2: Class 1, Section ALL
    exam_all = Examination_management.objects.create(
        Exam_Title="All Sections Exam",
        Exam_Type="unit-test",
        Exam_Date=datetime.now() + timedelta(days=2),
        Exam_Time=time(10, 0),
        Exam_Duration=60,
        Exam_Marks=100,
        Exam_Class="class-1",
        Exam_Section="ALL",
        school_id="SCH001"
    )

    # Exam 3: Class 1, Section B
    exam_sec_b = Examination_management.objects.create(
        Exam_Title="Section B Only Exam",
        Exam_Type="unit-test",
        Exam_Date=datetime.now() + timedelta(days=3),
        Exam_Time=time(10, 0),
        Exam_Duration=60,
        Exam_Marks=100,
        Exam_Class="class-1",
        Exam_Section="B",
        school_id="SCH001"
    )

    print("Created 3 Test Exams.")

    # 2. Simulate Request for Student in Section A
    factory = RequestFactory()
    view = StudentDashboardViewSet.as_view({'get': 'student_exams'})
    
    # Mocking a request for a student with grade='A'
    # We can't easily mock the user/student authentication fully here without a real student
    # So we will test the LOGIC block by extracting it or creating a temporary student
    
    try:
        temp_student = Student.objects.create(
            student_name="Temp Student A",
            applying_class="class-1",
            grade="A",
            school_id="SCH001",
            email="tempA@test.com"
        )
        
        url = f'/api/student-parent/dashboard/student_exams/?student_id={temp_student.student_id}&class_id=class-1'
        print(f"Simulating request: {url}")
        
        # We need a user to force authenticate
        if not temp_student.user:
            from main_login.models import User
            user = User.objects.create(username="temp_student_a", email="tempA@test.com")
            temp_student.user = user
            temp_student.save()
            
        request = factory.get(url)
        from rest_framework.test import force_authenticate
        force_authenticate(request, user=temp_student.user)
        
        response = view(request)
        
        print(f"Response Status: {response.status_code}")
        data = response.data
        
        print(f"Exams Found: {len(data)}")
        found_titles = [e['title'] for e in data]
        print(f"Found Titles: {found_titles}")
        
        # Assertions
        if "Section A Only Exam" in found_titles:
            print("SUCCESS: Found Section A Exam")
        else:
            print("FAILURE: Missing Section A Exam")
            
        if "All Sections Exam" in found_titles:
            print("SUCCESS: Found ALL Sections Exam")
        else:
            print("FAILURE: Missing ALL Sections Exam")
            
        if "Section B Only Exam" not in found_titles:
            print("SUCCESS: Correctly excluded Section B Exam")
        else:
            print("FAILURE: Incorrectly included Section B Exam")

        # Cleanup
        temp_student.delete()
        if temp_student.user: temp_student.user.delete()
        
    except Exception as e:
        print(f"Test Execution Failed: {e}")
        import traceback
        traceback.print_exc()
    
    # Cleanup Exams
    exam_sec_a.delete()
    exam_all.delete()
    exam_sec_b.delete()

if __name__ == "__main__":
    verify_student_exam_filter()
