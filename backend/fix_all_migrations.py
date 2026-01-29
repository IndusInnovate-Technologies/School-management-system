import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection
from django.db.migrations.loader import MigrationLoader

def fix_all_inconsistencies():
    loader = MigrationLoader(connection, ignore_no_migrations=True)
    graph = loader.graph
    
    with connection.cursor() as cursor:
        print("Checking for inconsistent migration history...")
        cursor.execute("SELECT app, name FROM django_migrations")
        applied_records = cursor.fetchall()
        applied_map = {}
        for app, name in applied_records:
            if app not in applied_map:
                applied_map[app] = set()
            applied_map[app].add(name)
            
        # Find the highest applied migration for each app
        highest_applied = {}
        for app, names in applied_map.items():
            # Try to extract the number
            nums = []
            for name in names:
                try:
                    nums.append(int(name.split('_')[0]))
                except (ValueError, IndexError):
                    pass
            if nums:
                highest_applied[app] = max(nums)
        
        # Now find migrations that are NOT applied but are "before" the highest applied
        to_fake = []
        for (app, name), node in graph.nodes.items():
            try:
                num = int(name.split('_')[0])
                if app in highest_applied and num < highest_applied[app]:
                    if app not in applied_map or name not in applied_map[app]:
                        to_fake.append((app, name))
            except (ValueError, IndexError):
                pass
        
        if not to_fake:
            print("No obvious inconsistencies found (where a later migration is applied but an earlier one is not).")
            return
            
        print(f"Found {len(to_fake)} migrations to fake apply:")
        for app, name in sorted(to_fake):
            print(f"  - {app}: {name}")
            
        # Insert them
        for app, name in sorted(to_fake):
            print(f"Faking {app}:{name}...")
            cursor.execute(
                "INSERT INTO django_migrations (app, name, applied) VALUES (%s, %s, now())",
                [app, name]
            )
            
        print("Done faking migrations.")

if __name__ == "__main__":
    try:
        fix_all_inconsistencies()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
