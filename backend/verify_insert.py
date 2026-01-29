
from main_login.models import User
from management_admin.models import Student
from teacher.models import Attendance

def run():
    print("--- VERIFY INSERT ---")
    try:
        user = User.objects.get(username='k')
        s = Student.objects.filter(user=user).first()
        if not s:
            print("No student found.")
            return

        count = Attendance.objects.filter(student=s).count()
        print(f"Student: {s.student_name} (Email: {s.email})")
        print(f"Attendance Count: {count}")
        
    except Exception as e:
        print(f"Error: {e}")

run()
