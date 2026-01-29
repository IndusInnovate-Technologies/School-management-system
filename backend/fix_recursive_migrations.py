import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection
from django.db.migrations.loader import MigrationLoader

def fix_recursive_dependencies():
    loader = MigrationLoader(connection, ignore_no_migrations=True)
    graph = loader.graph
    
    with connection.cursor() as cursor:
        print("Checking for inconsistent migration history...")
        cursor.execute("SELECT app, name FROM django_migrations")
        applied_records = cursor.fetchall()
        applied_nodes = set(applied_records)
        
        all_required = set()
        
        def add_dependencies(app, name):
            if (app, name) in all_required:
                return
            all_required.add((app, name))
            if (app, name) in graph.nodes:
                node = graph.nodes[(app, name)]
                for dep in node.dependencies:
                    # Handle dummy dependencies like __first__ and __latest__ if needed
                    # But graph.nodes usually has concrete dependencies
                    if dep in graph.nodes:
                        add_dependencies(*dep)

        # For every applied node, find all its dependencies
        for app, name in applied_nodes:
            if (app, name) in graph.nodes:
                add_dependencies(app, name)
            else:
                # This migration is applied but not in the current codebase!
                # We can't do much about it, but it shouldn't cause InconsistentMigrationHistory
                # unless it's a dependency of something else.
                pass
        
        to_fake = all_required - applied_nodes
        
        if not to_fake:
            print("No missing dependencies found for applied migrations.")
            return
            
        print(f"Found {len(to_fake)} migrations to fake apply because they are dependencies of applied migrations:")
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
        fix_recursive_dependencies()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
