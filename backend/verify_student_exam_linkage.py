
import os
import django
import sys

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student, StudentClass, Class
from teacher.models import Exam

def debug_student_exams():
    print("=== DEBUGGING STUDENT EXAM LINKAGE ===")
    
    # 1. Check Students and their Classes
    students = Student.objects.all()
    if not students.exists():
        print("No students found in the database.")
        return

    print(f"\nFound {students.count()} students. Checking enrollments:")
    for student in students:
        if student.student_name != 'applicant name': # Filter if needed, showing all for now
             pass
        
        print(f"\nStudent: {student.student_name} (ID: {student.student_id})")
        enrollments = StudentClass.objects.filter(student=student)
        
        if not enrollments.exists():
            print("  [WARNING] No class enrollments found!")
            continue
            
        student_class_objs = []
        for enrollment in enrollments:
            cls = enrollment.class_obj
            student_class_objs.append(cls)
            print(f"  - Enrolled in: {cls.name} - {cls.section} (ID: {cls.id})")
        
        # 2. Check Exams for these classes
        for cls in student_class_objs:
            exams = Exam.objects.filter(class_obj=cls)
            if exams.exists():
                print(f"    -> Finding exams for {cls.name} {cls.section}:")
                for exam in exams:
                     print(f"       * Exam: {exam.title} (ID: {exam.id}) Date: {exam.exam_date}")
            else:
                 print(f"    -> No exams found for {cls.name} {cls.section}")

    print("\n\n=== RECENT EXAMS CREATED ===")
    recent_exams = Exam.objects.all().order_by('-id')[:5]
    for exam in recent_exams:
        print(f"Exam: {exam.title} | Class: {exam.class_obj.name} {exam.class_obj.section} (ID: {exam.class_obj.id})")

if __name__ == "__main__":
    debug_student_exams()
