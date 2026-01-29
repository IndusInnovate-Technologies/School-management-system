
from django.db import connection

def run():
    print("--- Schema Inspection ---")
    with connection.cursor() as cursor:
        # Check students table PK
        cursor.execute("SELECT kcu.column_name FROM information_schema.table_constraints tco JOIN information_schema.key_column_usage kcu ON kcu.constraint_name = tco.constraint_name AND kcu.table_schema = tco.table_schema AND kcu.constraint_schema = tco.constraint_schema WHERE tco.constraint_type = 'PRIMARY KEY' AND kcu.table_name = 'students'")
        pk_cols = cursor.fetchall()
        print(f"Student PK Columns: {pk_cols}")

        # Check attendances table columns
        cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'attendances'")
        cols = cursor.fetchall()
        print("Attendance Columns:")
        for c in cols:
            print(f" - {c}")
            
    # Check what Django THINKS the PK is
    from management_admin.models import Student
    print(f"Django Model Student PK: {Student._meta.pk.name}")

run()
