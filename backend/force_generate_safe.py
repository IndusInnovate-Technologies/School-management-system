
from main_login.models import User
from management_admin.models import Student
from teacher.models import Attendance, Class
from datetime import date

def run():
    print("--- Force Generate Safe ---")
    try:
        user = User.objects.get(username='k')
        student = Student.objects.filter(user=user).first()
        
        if not student:
            print("No student found for 'k'!")
            return

        print(f"Student PK: {student.pk} (Type: {type(student.pk)})")
        print(f"Student Email: {student.email}")
        
        c = Class.objects.first()
        if not c:
            c = Class.objects.create(name="Test Class", section="A", academic_year="2025")
            
        print("Attempting to create ONE record...")
        try:
            Attendance.objects.create(
                student=student, 
                class_obj=c, 
                date=date.today(), 
                status='present'
            )
            print("SUCCESS: Created record.")
        except Exception as e:
            print(f"FAILED to create record. Error: {e}")
            # Try to print more details if possible
            if hasattr(e, 'message'): print(e.message)
            
    except Exception as e:
        print(f"Global Error: {e}")

run()
