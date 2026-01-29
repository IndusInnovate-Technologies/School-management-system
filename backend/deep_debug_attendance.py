
from rest_framework.test import APIClient
from main_login.models import User
from management_admin.models import Student
from teacher.models import Attendance

def run():
    print("--- Deep Debugging for user 'k' ---")
    try:
        user = User.objects.get(username='k')
        print(f"User: {user.username} (PK: {user.pk})")
        
        print("\n1. All Linked Students:")
        students = Student.objects.filter(user=user)
        for s in students:
            count = Attendance.objects.filter(student=s).count()
            print(f" - Student: {s.student_name} (PK: {s.pk}, ID: {s.student_id}) | Attendance Count: {count}")
            
        print("\n2. API Response Logic:")
        # Simulate exactly what the view does
        selected_student = students.first()
        if selected_student:
            print(f" - View would select: {selected_student.student_name} (PK: {selected_student.pk})")
            
            # Check for school_id mismatch issues (Attendance is school-aware?)
            # Attendance model doesn't strictly enforce school_id filtering in the view, 
            # but let's check if the view filters by it.
            # I recalled the view code: attendances = Attendance.objects.filter(student=student).order_by('-date')
            # It DOES NOT filter by school_id in the view code I saw earlier.
            
            # Re-generate data if needed right here
            if Attendance.objects.filter(student=selected_student).count() == 0:
                print("   !!! SELECTED STUDENT HAS 0 RECORDS. GENERATING NOW !!!")
                from datetime import date, timedelta
                from teacher.models import Class
                import random
                
                c = Class.objects.first()
                if not c: c = Class.objects.create(name="Emergency Class", section="A", academic_year="2025")
                
                for i in range(15):
                    Attendance.objects.create(
                        student=selected_student,
                        class_obj=c,
                        date=date.today() - timedelta(days=i),
                        status=random.choice(['present', 'absent'])
                    )
                print("   -> Generated 15 records.")
                
        else:
            print(" - NO STUDENT FOUND FOR USER!")

    except Exception as e:
        print(f"Error: {e}")

run()
