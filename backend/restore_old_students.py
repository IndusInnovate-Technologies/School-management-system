
import os
import django
import sys
from datetime import datetime
import pytz

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from management_admin.models import NewAdmission, Student

def restore_old_students():
    # Define cutoff date (restore only data created before 2026)
    cutoff_date = datetime(2026, 1, 1, tzinfo=pytz.UTC)

    # Get admissions created BEFORE cutoff
    admissions_to_restore = NewAdmission.objects.filter(created_at__lt=cutoff_date, status='Approved')
    
    print(f"Found {admissions_to_restore.count()} old admissions to restore.")
    
    for admission in admissions_to_restore:
        print(f"Restoring: {admission.student_name} (ID: {admission.student_id})")
        # Check if student already exists to avoid duplicates (though model handles it)
        try:
            student = admission.create_student_from_admission()
            if student:
                print(f"Successfully restored student: {student.student_id}")
            else:
                print(f"Failed to restore student (returned None): {admission.student_id}")
        except Exception as e:
            print(f"Error restoring {admission.student_id}: {str(e)}")

    print("Restoration complete.")

if __name__ == '__main__':
    restore_old_students()
