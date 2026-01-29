import os
import django
import sys

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from management_admin.models import Student
from management_admin.serializers import StudentSerializer
from django.test import RequestFactory

def verify_student_serializer():
    print("--- Verifying StudentSerializer ---")
    student = Student.objects.filter(student_name__icontains="Sushil").first()
    if not student:
        print("No student 'Sushil' found for verification.")
        return
    
    factory = RequestFactory()
    request = factory.get('/')
    
    serializer = StudentSerializer(student, context={'request': request})
    data = serializer.data
    
    print(f"Student: {data['student_name']}")
    print(f"Applying Class: {data['applying_class']}")
    print(f"Grade: {data['grade']}")
    print(f"Student Classes: {data['student_classes']}")
    
    if 'student_classes' in data:
        print("SUCCESS: 'student_classes' field present in Serializer.")
    else:
        print("FAILURE: 'student_classes' field missing in Serializer.")

def verify_exam_fetch():
    print("\n--- Verifying Exam Fetch Logic ---")
    from student_parent.views import StudentDashboardViewSet
    from rest_framework.test import APIRequestFactory, force_authenticate
    from main_login.models import User
    
    student = Student.objects.filter(student_name__icontains="Sushil").first()
    if not student or not student.user:
        print("No student with linked user found for verification.")
        return
        
    factory = APIRequestFactory()
    view = StudentDashboardViewSet.as_view({'get': 'student_exams'})
    
    # 1. Test fetch by student_id
    url = f'/api/student-parent/dashboard/student_exams/?student_id={student.student_id}'
    request = factory.get(url)
    force_authenticate(request, user=student.user)
    
    response = view(request)
    print(f"Fetch by Student ID ({student.student_id}) status: {response.status_code}")
    print(f"Exams found: {len(response.data)}")
    if len(response.data) > 0:
        print(f"First exam: {response.data[0]['title']} for subject {response.data[0]['subject']}")

    # 2. Test fetch by class_id (if student has a class)
    if student.student_classes.exists():
        class_id = student.student_classes.first().class_obj.id
        url = f'/api/student-parent/dashboard/student_exams/?class_id={class_id}'
        request = factory.get(url)
        force_authenticate(request, user=student.user)
        
        response = view(request)
        print(f"Fetch by Class ID ({class_id}) status: {response.status_code}")
        print(f"Exams found: {len(response.data)}")

if __name__ == "__main__":
    verify_student_serializer()
    verify_exam_fetch()
