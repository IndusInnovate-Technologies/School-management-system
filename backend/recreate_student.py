
from main_login.models import User
from management_admin.models import Student
from teacher.models import Attendance, Class
from datetime import date, timedelta
import random

def run():
    print("--- RECREATE STUDENT & GENERATE ATTENDANCE ---")
    try:
        user = User.objects.get(username='k')
        print(f"User: {user.username}")
        
        # 1. Delete existing student(s)
        students = Student.objects.filter(user=user)
        count = students.count()
        if count > 0:
            print(f"Deleting {count} existing student profiles...")
            students.delete()
            print("Deleted.")
        else:
             print("No existing student profiles to delete.")

        # 2. Create NEW Student with CLEAN email
        # Check if School exists
        from super_admin.models import School
        school = School.objects.first()
        if not school:
            school = School.objects.create(name="Default School", location="City", status="active")
            
        new_email = "k_student_clean@test.com"
        print(f"Creating new student with email: {new_email}")
        
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
        
        # 3. Generate Attendance
        c = Class.objects.first()
        if not c:
             c = Class.objects.create(name="10", section="A", academic_year="2025")
        
        print("Generating 30 days of attendance...")
        today = date.today()
        for i in range(30):
            d = today - timedelta(days=i)
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
