
from django.db import connection
from main_login.models import User
from management_admin.models import Student
import datetime
import sys

def run():
    print("--- RAW SQL V3 ---")
    try:
        user = User.objects.filters(username='k').first()
        if not user:
            # Try to get *any* user if k not found, for safety
            user = User.objects.first()
            if not user:
                print("NO_USERS")
                return
            print(f"Using fallback user: {user.username}")
        else:
            print(f"User: {user.username}")
            
        s = Student.objects.filter(user=user).first()
        if not s:
            print("NO_STUDENT")
            return

        print(f"Student PK: {s.pk} (Email: {s.email})")

        with connection.cursor() as cursor:
            # 1. Get Class ID
            cursor.execute("SELECT id FROM classes LIMIT 1")
            class_row = cursor.fetchone()
            if not class_row:
                 print("Creating fresh class...")
                 current_year = str(datetime.date.today().year)
                 # Note: 'classes' table has fields: name, section, academic_year, plus auto pointers?
                 # unique_together = ['name', 'section', 'academic_year']
                 # We need to be careful about unique constraints.
                 try:
                     cursor.execute("INSERT INTO classes (name, section, academic_year, created_at, updated_at) VALUES ('RawClass', 'Z', %s, NOW(), NOW()) RETURNING id", [current_year])
                     class_id = cursor.fetchone()[0]
                 except Exception as e:
                     print(f"Class creation failed (might exist): {e}")
                     # Try finding it
                     cursor.execute("SELECT id FROM classes WHERE name='RawClass' AND section='Z'")
                     class_id = cursor.fetchone()[0]
            else:
                class_id = class_row[0]
            
            print(f"Class ID: {class_id}")
            
            # 2. Insert Attendance
            table = 'teacher_attendance' 
            # Columns: class_obj_id, student_id, date, status, created_at, updated_at
            # Plus school_id, school_name, teacher_name, student_name, marked_by_id, remarks (nullable)
            
            sql = f"""
                INSERT INTO {table} 
                (student_id, class_obj_id, date, status, created_at, updated_at, school_id, school_name) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            now = datetime.datetime.now()
            today = datetime.date.today()
            
            # We use s.email directly. If this fails, the DB PK is definitely not what Django thinks.
            try:
                cursor.execute(sql, [s.email, class_id, today, 'present', now, now, 'SCH001', 'Test School'])
                print("INSERT_SUCCESS")
            except Exception as e:
                 print(f"INSERT_FAIL: {e}")
                 
    except Exception as e:
        print(f"Global Error: {e}")

if __name__ == '__main__':
    run()
