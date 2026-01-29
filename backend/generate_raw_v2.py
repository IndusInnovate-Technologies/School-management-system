
from django.db import connection, transaction
from main_login.models import User
from management_admin.models import Student
import datetime
import sys

def run():
    print("START")
    try:
        user = User.objects.get(username='k')
        s = Student.objects.filter(user=user).first()
        if not s:
            print("NO_STUDENT")
            return

        with connection.cursor() as cursor:
            # 1. Get Class
            cursor.execute("SELECT id FROM classes LIMIT 1")
            class_row = cursor.fetchone()
            if not class_row:
                # Create class raw
                cursor.execute("INSERT INTO classes (name, section, academic_year, created_at, updated_at) VALUES ('RawClass', 'A', '2025', NOW(), NOW()) RETURNING id")
                class_id = cursor.fetchone()[0]
            else:
                class_id = class_row[0]
            
            # 2. Insert Attendance
            # We must be careful with table name. Let's find it.
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name = 'attendance'")
            if not cursor.fetchone():
                 # try 'teacher_attendance' (default app_model)
                 table = 'teacher_attendance'
            else:
                 table = 'attendance'
            
            # Insert 
            # Note: We are using the EXACT email from the student object, trusting Django has the right ref
            # If this fails, then Django's 's.email' is NOT what is in the DB PK column.
            
            sql = f"INSERT INTO {table} (student_id, class_obj_id, date, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s)"
            now = datetime.datetime.now()
            cursor.execute(sql, [s.email, class_id, datetime.date.today(), 'present', now, now])
            # transaction.commit() # Django shell usually autocommits unless atomic block
            
        print("SUCCESS_INSERT_DONE")

    except Exception as e:
        print(f"FAIL: {e}")

run()
