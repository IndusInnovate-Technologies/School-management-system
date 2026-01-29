from django.db import connection

with connection.cursor() as cursor:
    try:
        cursor.execute("ALTER TABLE students ADD COLUMN IF NOT EXISTS grade VARCHAR(50) NULL")
        print("✓ Grade column added successfully")
    except Exception as e:
        print(f"Error: {e}")
