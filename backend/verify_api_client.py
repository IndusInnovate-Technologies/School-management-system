
from rest_framework.test import APIClient
from main_login.models import User
from student_parent.views import StudentDashboardViewSet

def run():
    print("--- Verifying API with APIClient ---")
    try:
        user = User.objects.get(username='k')
        print(f"Found User: {user.username}")
        
        client = APIClient()
        client.force_authenticate(user=user)
        
        response = client.get('/api/student-parent/dashboard/attendance_history/')
        
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            stats = data.get('stats', {})
            history = data.get('history', [])
            print(f"Student Name in Response: {data.get('student_name')}")
            print(f"Stats: {stats}")
            print(f"History Count: {len(history)}")
            if len(history) > 0:
                print("Sample History (First 3):")
                for h in history[:3]:
                    print(f" - {h}")
            else:
                print("HISTORY IS EMPTY.")
        else:
            print(f"Error Response: {response.content}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

run()
