
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Homework

def backfill():
    qs = Homework.objects.filter(target_class__isnull=True)
    count = qs.count()
    print(f"Found {count} homework records requiring backfill...")
    
    updated_count = 0
    for hw in qs:
        # Saving triggers the auto-populate logic we just added to the model
        hw.save()
        updated_count += 1
        
    print(f"Successfully backfilled {updated_count} records.")

if __name__ == '__main__':
    backfill()
