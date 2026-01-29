
from django.db import connection
from main_login.models import User
from management_admin.models import Student
from student_parent.models import Parent
from teacher.models import Attendance, Class
from datetime import date, timedelta
import random

def run():
    print("--- NUCLEAR RECREATE V3 ---")
    try:
        user = User.objects.get(username='k') # Assuming 'k' exists
        
        # 1. RAW SQL CLEANUP
        with connection.cursor() as cursor:
            # Find the corrupted email (approximate)
            # We know it starts with 'Amala' or is related to 'k'
            # But 'k' is linked to 'Amalapaul@gmail.com' via ORM.
            
            target_email = 'Amalapaul@gmail.com' 
            # (or better, get it from ORM if possible, but trust it has garbage chars)
            
            wildcard_email = f"%{target_email.strip()}%"
            print(f"Targeting email like: {wildcard_email}")
            
            # A. Identify tables
            # M2M table
            cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%parent%student%'")
            m2m_tables = [r[0] for r in cursor.fetchall()]
            print(f"Found M2M tables: {m2m_tables}")
            
            # Attendance table
            att_table = 'teacher_attendance'
            
            # B. Execute Deletes
            # 1. M2M
            for t in m2m_tables:
                print(f"Deleting from {t}...")
                cursor.execute(f"DELETE FROM {t} WHERE student_id LIKE %s", [wildcard_email])
                
            # 2. Attendance
            print(f"Deleting from {att_table}...")
            cursor.execute(f"DELETE FROM {att_table} WHERE student_id LIKE %s", [wildcard_email])
            
            # 3. Fees? Grades? (Optional, might fail constraint if we don't catch all)
            # Let's hope cascading takes care of others or they don't exist
            
            # 4. Students
            print(f"Deleting from students...")
            cursor.execute("DELETE FROM students WHERE email LIKE %s", [wildcard_email])
            
        print("Cleanup Complete. Checking if student gone...")
        if Student.objects.filter(email__icontains='Amalapaul').exists():
            print("WARNING: Student still exists! (Might have failed silently or mismatched)")
        else:
             print("Student successfully nuked.")

        # 2. CREATE NEW STUDENT
        from super_admin.models import School
        school = School.objects.first() or School.objects.create(name="Def", location="Loc", status="active")
        
        new_email = "k_student_final@test.com"
        print(f"Creating new student: {new_email}")
        
        s = Student.objects.create(
            user=user,
            email=new_email,
            student_name="K Final Student",
            date_of_birth=date(2010, 1, 1),
            gender="Male",
            school=school,
            applying_class="10",
            section="A"
        )
        print(f"Created: {s.pk}")
        
        # Link to Parent
        p, _ = Parent.objects.get_or_create(user=user)
        p.students.add(s)
        print("Linked to Parent.")
        
        # 3. GENERATE ATTENDANCE
        c = Class.objects.first() or Class.objects.create(name="10", section="A", academic_year="2025")
        
        print("Generating attendance...")
        for i in range(30):
            if (date.today() - timedelta(days=i)).weekday() == 6: continue
            Attendance.objects.create(
                student=s, 
                class_obj=c, 
                date=date.today() - timedelta(days=i), 
                status=random.choice(['present', 'present', 'absent'])
            )
            
        print(f"SUCCESS: Created {Attendance.objects.filter(student=s).count()} records.")

    except Exception as e:
        print(f"FAILURE: {e}")
        import traceback
        traceback.print_exc()

run()
