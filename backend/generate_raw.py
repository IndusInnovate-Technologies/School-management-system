
from django.db import connection
from main_login.models import User
from management_admin.models import Student
import datetime

def run():
    print("--- RAW SQL INSERT ---")
    try:
        user = User.objects.get(username='k')
        s = Student.objects.filter(user=user).first()
        if not s:
            print("No student found.")
            return

        print(f"Target Email: '{s.email}'")
        
        # Get a class ID
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM classes LIMIT 1")
            class_row = cursor.fetchone()
            if not class_row:
                print("No classes found. Cannot insert.")
                return
            class_id = class_row[0]
            
            # RAW INSERT
            # Assuming table name is 'attendances' and columns exist.
            # We need to handle potential 'id' auto-increment if not UUID.
            # Usually django tables are app_model
            
            table_name = 'teacher_attendance' # Guessing based on app name 'teacher', model 'Attendance'
            # Let's verify table name first
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%attendance%'")
            tables = cursor.fetchall()
            print(f"Tables found: {tables}")
            
            real_table = None
            for t in tables:
                if 'teacher_attendance' in t[0] or 'attendance' in t[0]:
                    real_table = t[0]
                    break
            
            if not real_table:
                print("Could not find attendance table.")
                return

            print(f"Inserting into {real_table}...")
            
            # Simple Insert
            sql = f"""
                INSERT INTO {real_table} (student_id, class_obj_id, date, status, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            now = datetime.datetime.now()
            cursor.execute(sql, [s.email, class_id, datetime.date.today(), 'present', now, now])
            print("RAW INSERT SUCCESSFUL")

    except Exception as e:
        print(f"Raw Insert Failed: {e}")

run()
