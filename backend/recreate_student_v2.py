
from main_login.models import User
from management_admin.models import Student
from student_parent.models import Parent
from teacher.models import Attendance, Class
from datetime import date, timedelta
import random

def run():
    print("--- RECREATE STUDENT V2 ---")
    try:
        user = User.objects.get(username='k')
        
        # 1. Delete existing student(s) with careful M2M handling
        students = Student.objects.filter(user=user)
        for s in students:
            print(f"Propelling deletion for: {s.email}")
            
            # Find parents linking to this student
            parents = Parent.objects.filter(students=s)
            for p in parents:
                print(f" - Unlinking from parent: {p}")
                p.students.remove(s)
            
            # Find any other related objects if crucial
            # (Attendance, Grades etc should cascade or set null)
            
            s.delete()
            print(" - Deleted student record.")

        # 2. Create NEW Student
        from super_admin.models import School
        school = School.objects.first()
        if not school: school = School.objects.create(name="Default School", location="City", status="active")
            
        new_email = "k_student_clean_v2@test.com"
        
        # Ensure new email doesn't exist
        if Student.objects.filter(email=new_email).exists():
            Student.objects.filter(email=new_email).delete()

        print(f"Creating new student: {new_email}")
        s = Student.objects.create(
            user=user,
            email=new_email,
            student_name="K Test Student",
            date_of_birth=date(2010, 1, 1),
            gender="Male",
            address="123 Test St",
            phone_number="1234567890",
            school=school,
            applying_class="10",
            section="A"
        )
        print(f"Created Student: {s.student_name} (PK: {s.pk})")
        
        # Link to Parent (create generic parent if needed)
        p, _ = Parent.objects.get_or_create(user=user)
        p.students.add(s)
        print("Linked to Parent profile.")
        
        # 3. Generate Attendance
        c = Class.objects.first()
        if not c: c = Class.objects.create(name="10", section="A", academic_year="2025")
        
        print("Generating 30 days of attendance...")
        today = date.today()
        for i in range(30):
            d = today - timedelta(days=i)
            # Skip Sundays
            if d.weekday() == 6: continue
            
            status = random.choice(['present', 'present', 'present', 'absent', 'late'])
            Attendance.objects.create(
                student=s,
                class_obj=c,
                date=d,
                status=status
            )
        
        print(f"SUCCESS: Generated {Attendance.objects.filter(student=s).count()} records.")

    except Exception as e:
        print(f"FAILURE: {e}")
        import traceback
        traceback.print_exc()

run()
