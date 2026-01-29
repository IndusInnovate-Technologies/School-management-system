import os
import sys
import django
from django.db import connection

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

def fix_table(table_name):
    print(f"Fixing table: {table_name}")
    try:
        with connection.cursor() as cursor:
            # Check if column exists first to be safe (though IF NOT EXISTS handles it)
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 0")
            columns = [col[0] for col in cursor.description]
            
            if 'parent_name' not in columns:
                print(f"Adding parent_name to {table_name}...")
                # Add column with default empty string since it's NOT NULL in model
                cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN IF NOT EXISTS parent_name varchar(255) NOT NULL DEFAULT '';")
                print(f"Successfully added parent_name to {table_name}")
            else:
                print(f"parent_name already exists in {table_name}")
                
    except Exception as e:
        print(f"Error fixing table {table_name}: {e}")

if __name__ == '__main__':
    fix_table('new_admissions')
    fix_table('students')
