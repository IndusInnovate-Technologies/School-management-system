
import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Student
from teacher.models import Class, Exam, ClassStudent
from student_parent.models import Parent

def debug_exams():
    print("--- Debugging Exams ---")
    
    # 1. List all Students and their Classes
    students = Student.objects.all()
    print(f"Total Students: {students.count()}")
    
    for student in students:
        print(f"\nStudent: {student.student_name} (ID: {student.student_id}, PK: {student.pk})")
        student_classes = student.student_classes.all()
        
        if not student_classes.exists():
            print("  [!] No classes enrolled (ClassStudent table empty for this student)")
            # check if string fields suggest a class
            print(f"  Note: applying_class='{student.applying_class}', section='{student.section}'")
            continue
            
        for link in student_classes:
            cls = link.class_obj
            print(f"  Enrolled in: {cls.name} - {cls.section} (ID: {cls.id})")
            
            # Check exams for this class
            exams = Exam.objects.filter(class_obj=cls)
            print(f"    Exams found for class {cls.id}: {exams.count()}")
            for exam in exams:
                print(f"      - {exam.title} (Status: {getattr(exam, 'exam_status', 'N/A')}, Date: {exam.exam_date})")

    # 2. List all Exams and their Classes
    print("\n\n--- All Exams ---")
    all_exams = Exam.objects.all()
    if not all_exams.exists():
        print("No exams found in the system.")
    for exam in all_exams:
        print(f"Exam: {exam.title} -> Class: {exam.class_obj} (ID: {exam.class_obj.id})")

if __name__ == "__main__":
    debug_exams()
