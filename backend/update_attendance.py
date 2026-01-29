
import random
from datetime import date, timedelta
from main_login.models import User
from student_parent.models import Parent
from management_admin.models import Student
from teacher.models import Attendance, Class

def run():
    print("Starting Update Attendance...")
    try:
        # Find user 'k'
        try:
            u = User.objects.get(username='k')
            print(f"Found User: {u.username}")
        except User.DoesNotExist:
            print("User 'k' not found.")
            return

        # Find linked student (handle various linking methods)
        student = None
        # method 1: direct link
        if hasattr(u, 'student_profiles') and u.student_profiles.exists():
            student = u.student_profiles.first()
            print("Found via student_profiles")
        
        # method 2: via parent profile
        if not student and hasattr(u, 'parent_profiles') and u.parent_profiles.exists():
            p = u.parent_profiles.first()
            if p.students.exists():
                student = p.students.first()
                print("Found via parent_profiles")

        if not student:
            print(f"User {u.username} has NO student linked. Attempting to link first available student.")
            student = Student.objects.first()
            if student:
                student.user = u
                student.save()
                print(f"Forcibly linked {u.username} to {student.student_name}")
            else:
                print("No students in database to link.")
                return

        print(f"Target Student: {student.student_name} (ID: {student.student_id})")

        # Generate Attendance
        count = Attendance.objects.filter(student=student).count()
        print(f"Current Attendance Count: {count}")
        
        # Always add fresh data for last 30 days to ensure calendar looks busy
        c = Class.objects.first()
        if not c:
             c = Class.objects.create(name="10", section="A", academic_year="2025")

        created_count = 0
        today = date.today()
        for i in range(30):
            d = today - timedelta(days=i)
            # Check if exists
            if not Attendance.objects.filter(student=student, date=d).exists():
                 status = random.choice(['present', 'present', 'present', 'present', 'absent', 'late'])
                 Attendance.objects.create(student=student, class_obj=c, date=d, status=status)
                 created_count += 1
        
        print(f"Added {created_count} new attendance records.")
        print(f"Total Attendance Count: {Attendance.objects.filter(student=student).count()}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

run()
