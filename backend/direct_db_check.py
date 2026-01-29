import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def check_table(t):
    try:
        with connection.cursor() as cursor:
            cursor.execute(f"SELECT 1 FROM {t} LIMIT 1")
            print(f"SUCCESS: Table '{t}' EXISTS and is accessible.")
    except Exception as e:
        print(f"FAILURE: Table '{t}' error: {e}")

tables = ['events', 'management_admin_event', 'gallery', 'gallery_images']
for t in tables:
    check_table(t)
