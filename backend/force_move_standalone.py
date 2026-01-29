
import os
import django
import sys
from datetime import date, timedelta
import random

# Setup Django standalone
sys.path.append('c:\\Users\\D-IT\\Desktop\\cap\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection
from main_login.models import User
from management_admin.models import Student
from student_parent.models import Parent
from teacher.models import Attendance, Class

def run():
    print("--- STANDALONE FORCE MOVE ---")
    try:
        user_k = User.objects.get(username='k')
        garbage_user, _ = User.objects.get_or_create(username='garbage_dump', defaults={'email':'garbage@dump.com', 'is_active':False})
        
        # 1. RAW MOVE
        with connection.cursor() as cursor:
            # Find student linked to k
            print(f"Moving students of user {user_k.id} to user {garbage_user.id}...")
            
            # Update 'students' table.
            cursor.execute("UPDATE students SET user_id = %s WHERE user_id = %s", [garbage_user.id, user_k.id])
            print("Row count affected:", cursor.rowcount)
            # Standalone script might need explicit commit if not autocommit
            # But Django usually handles it.
            
        print("Move complete. Creating new student...")
        
        # 2. CREATE NEW STUDENT (Django ORM)
        from super_admin.models import School
        school = School.objects.first() or School.objects.create(name="Def", location="Loc", status="active")
        
        new_email = "k_final_clean_v5@test.com"
        # delete if exists (orphan)
        Student.objects.filter(email=new_email).delete()
        
        print(f"Creating new student: {new_email}")
        s = Student.objects.create(
            user=user_k, # k is now free!
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
        p, _ = Parent.objects.get_or_create(user=user_k)
        try: p.students.clear() 
        except: pass
        p.students.add(s)
        
        # 3. GENERATE ATTENDANCE
        c = Class.objects.first() or Class.objects.create(name="10", section="A", academic_year="2025")
        
        count = 0
        for i in range(30):
            if (date.today() - timedelta(days=i)).weekday() == 6: continue
            Attendance.objects.create(
                student=s, 
                class_obj=c, 
                date=date.today() - timedelta(days=i), 
                status=random.choice(['present', 'present', 'absent'])
            )
            count += 1
            
        print(f"SUCCESS: Generated {count} records.")

    except Exception as e:
        print(f"FAILURE: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    run()
