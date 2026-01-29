import os
import django
from django.db import connection
import glob

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

app_name = 'management_admin'
print(f"Repairing migration history for '{app_name}'...")

# 1. Get all migrations on disk
disk_files = glob.glob(f'{app_name}/migrations/0*.py')
disk_names = sorted([os.path.basename(f)[:-3] for f in disk_files])

# 2. Get all migrations in DB
with connection.cursor() as cursor:
    cursor.execute("SELECT name FROM django_migrations WHERE app=%s", [app_name])
    db_names = set(row[0] for row in cursor.fetchall())

applied_in_db = sorted(list(db_names))
if not applied_in_db:
    print("No migrations applied in DB for this app. This is unexpected for the error seen.")
else:
    max_db_name = applied_in_db[-1]
    print(f"Latest applied in DB: {max_db_name}")

# 3. Inject missing sequential migrations
injected_count = 0
with connection.cursor() as cursor:
    for name in disk_names:
        if name not in db_names:
            # Check if there is any migration lexicographically later than this one that IS in DB
            has_applied_child = any(db_name > name for db_name in db_names)
            if has_applied_child:
                print(f"Injecting missing parent record: {name}")
                cursor.execute(
                    "INSERT INTO django_migrations (app, name, applied) VALUES (%s, %s, now())",
                    [app_name, name]
                )
                injected_count += 1

print(f"Successfully injected {injected_count} migration records for {app_name}.")
