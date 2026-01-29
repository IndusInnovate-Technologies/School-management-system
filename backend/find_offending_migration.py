import os
import django
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.db import connection
from django.db.migrations.loader import MigrationLoader
from django.db.migrations.state import ProjectState

def find_offending_migration():
    loader = MigrationLoader(connection, ignore_no_migrations=True)
    graph = loader.graph
    
    project_state = ProjectState()
    
    # Get all leaf nodes
    leaves = graph.leaf_nodes()
    
    # Build a full plan for all leaves
    # We can use executor's internal logic to get a sorted plan of ALL migrations
    from django.db.migrations.executor import MigrationExecutor
    executor = MigrationExecutor(connection)
    
    # To get ALL migrations in the project, we can treat them all as unapplied
    # We'll mock the 'applied' set to be empty
    original_applied = executor.loader.applied_migrations
    executor.loader.applied_migrations = set()
    
    try:
        plan = executor.migration_plan(leaves)
        print(f"Total migrations to process: {len(plan)}")
        
        for migration, backwards in plan:
            # print(f"Processing {migration.app_label}.{migration.name}...")
            try:
                project_state = migration.mutate_state(project_state)
            except Exception as e:
                print(f"\nFAILED on {migration.app_label}.{migration.name}")
                print(f"Error type: {type(e).__name__}")
                print(f"Error: {e}")
                print("Operations:")
                for op in migration.operations:
                    print(f"  - {op}")
                break
        else:
            print("Successfully built state for all migrations!")
            
    finally:
        executor.loader.applied_migrations = original_applied

if __name__ == "__main__":
    try:
        find_offending_migration()
    except Exception as e:
        print(f"Error in script: {e}")
        sys.exit(1)
