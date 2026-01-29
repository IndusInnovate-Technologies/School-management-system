import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

with connection.cursor() as cursor:
    cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'teachers';")
    columns = [row[0] for row in cursor.fetchall()]
    
    print(f"Columns in teachers table: {columns}")
    
    missing = []
    for field in ['experience', 'salary', 'emergency_contact_relation']:
        if field not in columns:
            missing.append(field)
            
    if missing:
        print(f"MISSING COLUMNS: {missing}")
    else:
        print("All fields present.")
