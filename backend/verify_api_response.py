
from management_admin.models import Student
from teacher.models import Exam, Class, Grade

print("--- VERIFYING API RESPONSE LOGIC ---")

# 1. Get Student
student = Student.objects.filter(student_name__icontains='Sushil').first()
if not student:
    print("Student not found")
    exit()

print(f"Student: {student.student_name} (ID: {student.student_id})")

# 2. Simulate View Logic
response_data = []
student_classes = student.student_classes.all()
print(f"Enrolled Classes: {student_classes.count()}")

for class_link in student_classes:
    cls = class_link.class_obj
    print(f"Checking Class: {cls.name} {cls.section}")
    exams = Exam.objects.filter(class_obj=cls).order_by('-exam_date')
    print(f"Found {exams.count()} exams for this class.")
    
    for exam in exams:
        grade_entry = Grade.objects.filter(exam=exam, student=student).first()
        
        exam_data = {
            'id': exam.id,
            'title': exam.title,
            'subject': exam.subject or exam.title,
            'exam_date': exam.exam_date.isoformat() if exam.exam_date else None,
            'date': exam.exam_date.strftime('%Y-%m-%d') if exam.exam_date else None,
        }
        print(f"  -> Exam: {exam_data['title']} Date: {exam_data['exam_date']}")
        response_data.append(exam_data)

print(f"\nTotal Exams returned: {len(response_data)}")
