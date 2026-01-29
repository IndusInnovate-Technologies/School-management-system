
from management_admin.models import Student
from teacher.models import Exam, Class, ClassStudent

print("--- DEBUGGING EXAM VISIBILITY ---")

# 1. Get the target student
# Try to find a student who might be the one logged in.
students = Student.objects.all()[:3] 
for student in students:
    print(f"\nChecking Student: {student.student_name} (ID: {student.student_id}) User: {student.user.username if student.user else 'No User'}")
    
    # 2. Check Enrollments
    enrollments = student.student_classes.all()
    print(f"  Enrollments count: {enrollments.count()}")
    
    enrolled_classes = []
    if enrollments.exists():
        for enrollment in enrollments:
            cls = enrollment.class_obj
            if cls:
                 print(f"  - Enrolled in: {cls.name} Section: {cls.section} (ID: {cls.id})")
                 enrolled_classes.append(cls)
            else:
                 print(f"  - Broken Enrollment: {enrollment.id}")
    else:
        print("  NO ENROLLMENTS")

    # 3. Check Exams for enrolled classes
    for cls in enrolled_classes:
         exams = Exam.objects.filter(class_obj=cls)
         print(f"    -> Exams for {cls.name} {cls.section}: {exams.count()}")
         for e in exams:
             print(f"       * {e.title} (Date: {e.exam_date})")

print("\n--- ALL RECENT EXAMS ---")
for e in Exam.objects.order_by('-id')[:5]:
    c_str = f"{e.class_obj.name} {e.class_obj.section}" if e.class_obj else "No Class"
    print(f"Exam: {e.title} (ID: {e.id}) -> Assigned to: {c_str}")
