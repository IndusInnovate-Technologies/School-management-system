
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def run():
    print("--- Verifying API for user 'k' ---")
    
    # 1. Login
    login_url = f"{BASE_URL}/main_login/login/" # Adjust if path differs, trying common path or finding from urls
    # Actually based on previous logs: /api/auth/role-login/ might be it, or simplejwt
    # Let's check main_login/urls.py or similar. 
    # But usually simplejwt is at /api/token/ or similar.
    # Let's assume standard simplejwt or try to find it. 
    
    # Let's try standard login params
    payload = {
        "username": "k",
        "password": "k" # assuming password is same as username for test users, or 'password'
        # Wait, I don't know the password for 'k'. 
        # I can set a known password for 'k' first via shell script to be sure.
    }
    
    # Alternative: Use shell to mock the request directly without HTTP overhead 
    # This avoids auth issues.
    print("Running internal Django request check...")
    import os
    import django
    from django.conf import settings
    from django.test import RequestFactory
    from student_parent.views import StudentDashboardViewSet
    from main_login.models import User
    
    # Setup Django
    # (Assuming this script is run via 'python manage.py shell < script.py')
    
    try:
        user = User.objects.get(username='k')
        print(f"User: {user.username} (ID: {user.pk})")
        
        # Instantiate view
        view = StudentDashboardViewSet.as_view({'get': 'attendance_history'})
        
        # Create request
        factory = RequestFactory()
        request = factory.get('/api/student-parent/dashboard/attendance_history/')
        request.user = user
        
        # Get response
        response = view(request)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.data
            stats = data.get('stats', {})
            history = data.get('history', [])
            print(f"Student: {data.get('student_name')}")
            print(f"Stats: {stats}")
            print(f"History Count: {len(history)}")
            if len(history) > 0:
                print("First 3 records:")
                for h in history[:3]:
                    print(f" - {h}")
            else:
                print("!! HISTORY IS EMPTY !!")
                
                # Debug why
                from management_admin.models import Student
                from teacher.models import Attendance
                # s = Student.objects.filter(user=user).first()
                # print(f"Linked Student: {s}")
                # print(f"Attendance count for {s}: {Attendance.objects.filter(student=s).count()}")
                
        else:
            print(f"Error: {response.data}")

    except Exception as e:
        print(f"Failed: {e}")
        import traceback
        traceback.print_exc()

run()
