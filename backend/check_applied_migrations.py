import os
import django
from django.db import connection
import glob

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

print("Comparing disk vs database for 'management_admin'...")
disk_files = glob.glob('management_admin/migrations/0*.py')
disk_names = sorted([os.path.basename(f)[:-3] for f in disk_files])

with connection.cursor() as cursor:
    cursor.execute("SELECT name FROM django_migrations WHERE app='management_admin'")
    db_names = set(row[0] for row in cursor.fetchall())

applied_in_db = sorted(list(db_names))
head_db = applied_in_db[-1] if applied_in_db else None
print(f"Latest applied in DB: {head_db}")

missing_but_needed = []
for name in disk_names:
    if name not in db_names:
        # Check if there's any APPLIED migration AFTER this one
        is_orphaned = any(db_name > name for db_name in db_names)
        if is_orphaned:
            missing_but_needed.append(name)

if missing_but_needed:
    print("Found gaps (missing in DB but have children in DB):")
    for name in missing_but_needed:
        print(f" [!] {name}")
else:
    print("No gaps found.")
