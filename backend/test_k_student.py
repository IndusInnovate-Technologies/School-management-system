
import os
import django
import sys
from django.utils import timezone

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from student_parent.views import StudentDashboardViewSet
from rest_framework.test import APIRequestFactory, force_authenticate
from main_login.models import User
from management_admin.models import Student

def test_k_student(student_id, date_str):
    factory = APIRequestFactory()
    student = Student.objects.filter(student_id=student_id).first()
    if not student:
        print(f"Student {student_id} not found")
        return
    
    user = student.user
    # If no user, mock one
    if not user:
        user = User.objects.filter(role__name='student_parent').first()

    print(f"Testing Day Details for student: {student.student_name} ({student_id}) on {date_str}")
    
    request = factory.get('/api/student-parent/day_details/', {'student_id': student_id, 'date': date_str})
    force_authenticate(request, user=user)
    
    view = StudentDashboardViewSet.as_view({'get': 'day_details'})
    try:
        response = view(request)
        print(f"Response Status: {response.status_code}")
        if response.status_code == 200:
            exams = response.data.get('exams', [])
            print(f"Exams Found: {len(exams)}")
            for ex in exams:
                print(f" - {ex.get('title')} ({ex.get('time')}) [Class: {ex.get('className')}]")
        else:
            print(f"Response Data: {response.data}")
    except Exception as e:
        print(f"CAUGHT EXCEPTION: {e}")

if __name__ == "__main__":
    # Test for NRK-009 on Jan 12 (Should see 'Project')
    test_k_student('NRK-009', '2026-01-12')
