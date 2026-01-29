
from django.db import connection
from main_login.models import User
from management_admin.models import Student

def run():
    print("--- DEBUG VALUES ---")
    try:
        user = User.objects.get(username='k')
        s = Student.objects.filter(user=user).first()
        if not s:
            print("No student for user 'k'")
            return
            
        print(f"Django Object Email (PK): {repr(s.email)}")
        print(f"Django Object PK:         {repr(s.pk)}")
        
        # Raw SQL check
        with connection.cursor() as cursor:
            cursor.execute("SELECT email FROM students WHERE email = %s", [s.email])
            row = cursor.fetchone()
            if row:
                print(f"DB Exact Match Found:   {repr(row[0])}")
            else:
                print("NO EXACT DB MATCH FOR THIS PK!")
                
                # Search for it via LIKE to see what's actually there
                cursor.execute("SELECT email FROM students WHERE email LIKE %s", [f"%{s.email.strip()}%"])
                rows = cursor.fetchall()
                print(f"Found {len(rows)} similar rows:")
                for r in rows:
                    print(f" - DB Value: {repr(r[0])}")

    except Exception as e:
        print(f"Error: {e}")

run()
