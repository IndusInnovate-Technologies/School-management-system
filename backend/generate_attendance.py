
import random
from datetime import date, timedelta
from main_login.models import User
from student_parent.models import Parent
from management_admin.models import Student
from teacher.models import Attendance, Class

def run():
    print("Starting Attendance Generation...")
    try:
        # Try to find user 'k' or fallback to first user
        try:
            u = User.objects.get(username='k')
            print(f"Found User: {u.username} ({u.email})")
        except User.DoesNotExist:
            print("User 'k' not found, using first user with student profile")
            u = User.objects.filter(student_profiles__isnull=False).first()
            if not u:
                u = User.objects.filter(parent_profiles__isnull=False).first()
        
        if not u:
            print("No suitable user found.")
            return

        # Find linked student
        student = None
        if hasattr(u, 'student_profiles') and u.student_profiles.exists():
            student = u.student_profiles.first()
        elif hasattr(u, 'parent_profiles') and u.parent_profiles.exists():
            parent = u.parent_profiles.first()
            if parent.students.exists():
                student = parent.students.first()
        
        if not student:
            print(f"User {u.username} has no student linked.")
            return

        print(f"Target Student: {student.student_name} (Email/PK: {student.pk}, ID: {student.student_id})")

        # Check existing attendance
        count = Attendance.objects.filter(student=student).count()
        print(f"Existing Attendance Count: {count}")

        if count == 0:
            print("No attendance found. Generating data...")
            c = Class.objects.first()
            if not c:
                c = Class.objects.create(name="Default Class", section="A", academic_year="2025")
            
            today = date.today()
            # Generate 14 days of data
            for i in range(14):
                d = today - timedelta(days=i)
                # Skip Sundays
                if d.weekday() == 6: continue
                
                status = random.choice(['present', 'present', 'present', 'absent', 'late'])
                Attendance.objects.create(
                    student=student,
                    class_obj=c,
                    date=d,
                    status=status
                )
                print(f"Created {status} for {d}")
            print("Attendance generation complete.")
        else:
            print("Attendance data already exists. No changes made.")

    except Exception as e:
        print(f"Error: {e}")

run()
