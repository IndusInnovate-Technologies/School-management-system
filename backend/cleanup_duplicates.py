
import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Timetable

def delete_duplicates():
    print("--- DELETING DUPLICATE TIMETABLES ---")
    
    # Find all timetables for class_id=123 (the problematic one from error)
    # Delete entries with the specific time that's causing issues
    duplicates = Timetable.objects.filter(
        class_obj_id=123,
        day_of_week=0,
        start_time='14:00:00'
    )
    
    count = duplicates.count()
    print(f"Found {count} entries for class_id=123, day=0, time=14:00:00")
    
    if count > 0:
        # Keep the first one, delete the rest
        first = duplicates.first()
        print(f"Keeping entry ID: {first.id}")
        
        to_delete = duplicates.exclude(id=first.id)
        deleted_count = to_delete.count()
        to_delete.delete()
        print(f"Deleted {deleted_count} duplicate entries")
    
    # Also delete all entries with wrong school_id
    wrong_school = Timetable.objects.filter(school_id='AP123678967890')
    wrong_count = wrong_school.count()
    if wrong_count > 0:
        print(f"\nDeleting {wrong_count} entries with wrong school_id (AP123678967890)")
        wrong_school.delete()
    
    print("\nDone!")

if __name__ == "__main__":
    delete_duplicates()
