
from main_login.models import User
from management_admin.models import Student
from student_parent.models import Parent
from teacher.models import Attendance, Class
from datetime import date, timedelta
import random

def run():
    print("--- ISOLATE & REPLACE STRATEGY ---")
    try:
        user = User.objects.get(username='k')
        
        # 1. ISOLATE OLD STUDENT (if exists)
        old_student = Student.objects.filter(user=user).first()
        if old_student:
             print(f"Found corrupted student: {old_student.pk}")
             
             # Create dummy user to hold the bag
             garbage_user, _ = User.objects.get_or_create(username='garbage_dump', defaults={'email':'garbage@dump.com'})
             garbage_user.set_password('garbage')
             garbage_user.save()
             
             try:
                 old_student.user = garbage_user
                 old_student.save()
                 print("SUCCESS: Moved corrupted student to 'garbage_dump' user.")
             except Exception as e:
                 print(f"FAILED to move student: {e}")
                 # If this fails, we are stuck with 2 students.
                 # We must ensure New Student comes first in API.
                 # API uses: students = Student.objects.filter(user=user).first()
                 # Ordering is by PK usually.
                 pass
        else:
             print("No old student found (maybe previously deleted?)")

        # 2. CREATE NEW STUDENT
        from super_admin.models import School
        school = School.objects.first() or School.objects.create(name="Def", location="Loc", status="active")
        
        new_email = "000_k_clean@test.com" # '000' to ensure sort order if email sorting used
        
        # Cleaning up if my previous attempts left half-baked records
        Student.objects.filter(email=new_email).delete()
        
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
        try:
            # Clear old links if possible
            p.students.clear() 
        except: pass
        p.students.add(s)
        print("Linked to Parent.")
        
        # 3. GENERATE ATTENDANCE
        c = Class.objects.first() or Class.objects.create(name="10", section="A", academic_year="2025")
        
        print("Generating attendance...")
        created_count = 0
        for i in range(30):
            if (date.today() - timedelta(days=i)).weekday() == 6: continue
            Attendance.objects.create(
                student=s, 
                class_obj=c, 
                date=date.today() - timedelta(days=i), 
                status=random.choice(['present', 'present', 'absent'])
            )
            created_count += 1
            
        print(f"SUCCESS: Created {created_count} records.")

    except Exception as e:
        print(f"FAILURE: {e}")
        import traceback
        traceback.print_exc()

run()
