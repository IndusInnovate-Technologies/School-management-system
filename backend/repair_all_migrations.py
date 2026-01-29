import os
import django
from django.db import connection
import glob

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.apps import apps

def repair_app(app_label):
    app_config = apps.get_app_config(app_label)
    migrations_dir = os.path.join(app_config.path, 'migrations')
    
    if not os.path.exists(migrations_dir):
        return

    print(f"Checking '{app_label}'...")
    disk_files = glob.glob(os.path.join(migrations_dir, '0*.py'))
    disk_names = sorted([os.path.basename(f)[:-3] for f in disk_files])

    with connection.cursor() as cursor:
        cursor.execute("SELECT name FROM django_migrations WHERE app=%s", [app_label])
        db_names = set(row[0] for row in cursor.fetchall())

    injected_count = 0
    with connection.cursor() as cursor:
        for name in disk_names:
            if name not in db_names:
                # Inject if it has any applied child
                if any(db_name > name for db_name in db_names):
                    print(f"  [!] Injecting missing record: {name}")
                    cursor.execute(
                        "INSERT INTO django_migrations (app, name, applied) VALUES (%s, %s, now())",
                        [app_label, name]
                    )
                    injected_count += 1
    if injected_count > 0:
        print(f"  Successfully injected {injected_count} records for {app_label}.")

# Repair all local apps
for app in apps.get_app_configs():
    # Only check apps in the current project (avoiding built-in django ones mostly, but can check all)
    if 'site-packages' not in app.path:
        repair_app(app.label)
