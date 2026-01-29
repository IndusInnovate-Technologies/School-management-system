
from django.db import connection
from management_admin.models import Student
from main_login.models import User

def run():
    print("--- NUCLEAR DELETE ---")
    try:
        user = User.objects.get(username='k')
        # We need the email. 
        # If we can't find student via ORM, we can't get email?
        # Let's try to find it via ORM first as we did before.
        s = Student.objects.filter(user=user).first()
        if not s:
            print("No student found via ORM to delete.")
            return

        email = s.email
        print(f"Target Email: '{email}'")
        
        with connection.cursor() as cursor:
            # 1. Delete from parents_students (M2M)
            print("Deleting from parents_students...")
            # Table name might be 'student_parent_parent_students' or 'parents_students' or similar.
            # Let's check table name in information_schema
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%parent%student%'")
            tables = cursor.fetchall()
            print(f"Found M2M tables: {tables}")
            
            # Usually it's 'app_model_field' -> 'student_parent_parent_students'
            m2m_table = 'student_parent_parent_students' 
            # Check if it exists in list
            found_table = None
            for t in tables:
                if 'parent' in t[0] and 'student' in t[0]:
                    found_table = t[0]
                    # prefer shorter if ambiguous? No, prefer specific.
                    # 'student_parent_parent_students' is standard for app 'student_parent', model 'Parent', field 'students'
            
            if found_table:
                print(f"Targeting M2M table: {found_table}")
                cursor.execute(f"DELETE FROM {found_table} WHERE student_id = %s", [email])
            else:
                print("Could not find M2M table. Skipping (might fail later).")

            # 2. Delete from attendance
            print("Deleting from teacher_attendance...")
            cursor.execute("DELETE FROM teacher_attendance WHERE student_id = %s", [email])

            # 3. Delete from fees, grades, exams, assignments etc? 
            # Constraints might exist elsewhere.
            # Let's try to delete Student now.
            print("Deleting from students...")
            cursor.execute("DELETE FROM students WHERE email = %s", [email])
            
            print("NUCLEAR DELETE SUCCESSFUL")
            
    except Exception as e:
        print(f"DELETE FAILED: {e}")

run()
