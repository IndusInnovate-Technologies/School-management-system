
import random
from datetime import date, timedelta
from main_login.models import User
from student_parent.models import Parent
from management_admin.models import Student
from teacher.models import Attendance, Class
from super_admin.models import School

def run():
    print("Starting Fix Data...")
    try:
        try:
            u = User.objects.get(username='k')
            print(f"Found User: {u.username}")
        except User.DoesNotExist:
            print("User 'k' not found, can't fix.")
            return

        # Ensure School
        school = School.objects.first()
        if not school: school = School.objects.create(name='Default', location='Loc', status='active')

        # Create NEW Student to avoid PK conflicts
        import uuid
        new_email = f"test_student_{uuid.uuid4().hex[:6]}@example.com"
        
        student = Student.objects.create(
            email=new_email,
            student_name="Test Student (Fixed)",
            parent_name="Test Parent",
            date_of_birth=date(2010, 1, 1),
            gender="Male",
            applying_class="10",
            section="A",
            school=school,
            user=u  # Link to user k
        )
        print(f"Created Student: {student.student_name} ({student.pk})")
        
        # Link to Parent
        p, _ = Parent.objects.get_or_create(user=u)
        p.students.add(student)
        p.save()
        print("Linked to Parent.")

        # Generate Attendance
        c = Class.objects.first() or Class.objects.create(name="10", section="A", academic_year="2025")
        
        today = date.today()
        for i in range(14):
            d = today - timedelta(days=i)
            status = random.choice(['present', 'present', 'absent', 'late'])
            Attendance.objects.create(
                student=student, 
                class_obj=c, 
                date=d, 
                status=status
            )
        print("Attendance Generated Successfully.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

run()
