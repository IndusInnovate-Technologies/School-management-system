import os
import sys
import django

# Add 'backend' to sys.path so 'school_backend' is importable
backend_path = os.path.join(os.getcwd(), 'backend')
if backend_path not in sys.path:
    sys.path.append(backend_path)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
try:
    django.setup()
except Exception as e:
    print(f"Setup failed: {e}")
    sys.exit(1)

from management_admin.models import Teacher
from main_login.models import User

def identify():
    print("--- Users ---")
    users = User.objects.all()
    for u in users:
        print(f"User: {u.username} (Email: {u.email})")

    print("\n--- Teachers ---")
    teachers = Teacher.objects.all()
    for t in teachers:
        user_str = t.user.username if t.user else "NO_USER"
        print(f"Teacher: {t.first_name} {t.last_name} | EmpNo: {t.employee_no} | User: {user_str} | Dept: {t.department}")

if __name__ == "__main__":
    identify()
