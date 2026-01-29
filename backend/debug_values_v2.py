
from django.db import connection
from main_login.models import User
from management_admin.models import Student
import sys

def run():
    print("--- START DEBUG ---")
    sys.stdout.flush()
    try:
        user = User.objects.get(username='k')
        s = Student.objects.filter(user=user).first()
        if not s:
            print("No student for user 'k'")
            return
            
        print(f"EMAIL_STR|{s.email}|")
        print(f"PK_VAL___|{s.pk}|")
        
        # Raw SQL check
        with connection.cursor() as cursor:
            cursor.execute("SELECT email FROM students WHERE email = %s", [s.email])
            row = cursor.fetchone()
            if row:
                print(f"DB_RAW___|{row[0]}|")
            else:
                print("NO_EXACT_DB_MATCH")

        print("--- END DEBUG ---")
    except Exception as e:
        print(f"Error: {e}")

run()
