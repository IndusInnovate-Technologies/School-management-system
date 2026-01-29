import os
import django
import sys
from datetime import datetime, time

# Add backend to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import Examination_management

def verify_section_creation():
    print("--- Verifying Exam Section Creation ---")
    
    # Create an exam with a specific section
    title = f"Test Exam {datetime.now().timestamp()}"
    section = "A"
    
    exam = Examination_management.objects.create(
        Exam_Title=title,
        Exam_Type="unit-test",
        Exam_Date=datetime.now(),
        Exam_Time=time(10, 0),
        Exam_Duration=60,
        Exam_Marks=100,
        Exam_Location="Hall 1",
        Exam_Status="upcoming",
        Exam_Section=section,
        # Default other fields
        Exam_Subject="Math",
        Exam_Class="class-1"
    )
    
    print(f"Created Exam: {exam.Exam_Title} with Section: {exam.Exam_Section}")
    
    # Verify retrieval
    fetched_exam = Examination_management.objects.get(id=exam.id)
    if fetched_exam.Exam_Section == section:
        print("SUCCESS: Exam Section saved and retrieved correctly.")
    else:
        print(f"FAILURE: Expected Section {section}, got {fetched_exam.Exam_Section}")

if __name__ == "__main__":
    verify_section_creation()
