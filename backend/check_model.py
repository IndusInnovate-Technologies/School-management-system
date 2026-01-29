import os
import django
import sys

# Add backend dir to sys.path if needed
sys.path.append(os.getcwd())

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

try:
    from management_admin.models import Teacher
    print("Successfully imported Teacher from management_admin.models")
    fields = [f.name for f in Teacher._meta.get_fields()]
    print(f"Teacher fields: {fields}")
    
    if 'marital_status' in fields:
        print("SUCCESS: marital_status found.")
    else:
        print("FAILURE: marital_status NOT found.")
        
except Exception as e:
    print(f"Error: {e}")
