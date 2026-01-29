
import os
import sys
import json
import django
from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework.response import Response

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User
from student_parent.views import StudentDashboardViewSet

def test_attendance_api(email):
    print(f"\nTesting Attendance API for: {email}")
    try:
        user = User.objects.get(email=email)
        print(f"User found: {user.username} (Role: {user.role.name})")
        
        factory = APIRequestFactory()
        view = StudentDashboardViewSet.as_view({'get': 'attendance_history'})
        
        # Create request
        request = factory.get('/api/student-dashboard/attendance_history/')
        force_authenticate(request, user=user)
        
        # Get response
        response = view(request)
        
        if response.status_code == 200:
            print("API Call Successful")
            data = response.data
            
            print(f"Student Name: {data.get('student_name')}")
            print(f"Stats: {data.get('stats')}")
            print("History (first 5 records):")
            history = data.get('history', [])
            for record in history[:5]:
                print(f"  - {record}")
                
            # Check for today's record specifically
            import datetime
            today = datetime.date.today().strftime('%Y-%m-%d')
            today_record = next((r for r in history if str(r['date']) == today), None)
            if today_record:
                print(f"FOUND TODAY'S RECORD: {today_record}")
            else:
                print(f"WARNING: No record found for today ({today})")
                
        else:
            print(f"API Failed: {response.status_code}")
            print(response.data)
            
    except User.DoesNotExist:
        print(f"User with email {email} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_attendance_api('krishna@student.com')
    test_attendance_api('twinkle@student.com')
