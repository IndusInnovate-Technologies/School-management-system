
import os
import django
import sys

# Setup Django standalone
sys.path.append('c:\\Users\\D-IT\\Desktop\\cap\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection

def run():
    print("--- CONSTRAINT CHECK STANDALONE ---")
    with connection.cursor() as cursor:
        # Get constraint def for attendance
        sql = """
            SELECT 
                tc.table_name, 
                kcu.column_name, 
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name 
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.key_column_usage AS kcu
                  ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                  ON ccu.constraint_name = tc.constraint_name
                  AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'teacher_attendance' AND kcu.column_name = 'student_id';
        """
        cursor.execute(sql)
        rows = cursor.fetchall()
        print("FK Definition:")
        if not rows:
            print("No FK found for teacher_attendance.student_id!")
            # Maybe table name is wrong? Or col name?
            # Check cols
            cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'teacher_attendance'")
            print("Cols:", [r[0] for r in cursor.fetchall()])
        
        for r in rows:
             print(f"Table: {r[0]} | Col: {r[1]} -> Refs Table: {r[2]} | Refs Col: {r[3]}")
             
    print("\nM2M Constraint Check:")
    with connection.cursor() as cursor:
         cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%parent%student%'")
         m2m_rows = cursor.fetchall()
         if m2m_rows:
             for m2m_row in m2m_rows:
                 m2m_table = m2m_row[0]
                 print(f"M2M Table found: {m2m_table}")
                 
                 # Check Columns
                 cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{m2m_table}'")
                 print(f"Cols: {[r[0] for r in cursor.fetchall()]}")

                 sql = f"""
                    SELECT 
                        kcu.column_name, 
                        ccu.table_name AS foreign_table_name,
                        ccu.column_name AS foreign_column_name 
                    FROM 
                        information_schema.table_constraints AS tc 
                        JOIN information_schema.key_column_usage AS kcu
                          ON tc.constraint_name = kcu.constraint_name
                        JOIN information_schema.constraint_column_usage AS ccu
                          ON ccu.constraint_name = tc.constraint_name
                    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = '{m2m_table}';
                 """
                 cursor.execute(sql)
                 for r in cursor.fetchall():
                     print(f"FK: {r[0]} -> Refs {r[1]}({r[2]})")
         else:
             print("No M2M table found matching %parent%student%")

if __name__ == '__main__':
    run()
