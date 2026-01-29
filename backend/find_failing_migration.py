
import os
import sys
import django
from django.conf import settings
from django.db.migrations.loader import MigrationLoader
from django.db.migrations.state import ProjectState

# Set up Django
sys.path.append(os.getcwd())
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "school_backend.settings")
django.setup()

def find_failing_migration():
    loader = MigrationLoader(None, ignore_no_migrations=True)
    graph = loader.graph
    
    # Get all leaf nodes
    leaves = graph.leaf_nodes()
    print(f"Leaf nodes: {leaves}")
    
    for leaf in leaves:
        print(f"\nChecking path to leaf: {leaf}")
        project_state = ProjectState()
        plan = graph.forwards_plan(leaf)
        
        for node in plan:
            # We want to check all migrations in the plan, even from other apps
            # but only print progress for the ones we suspect
            if node[0] == 'management_admin':
                print(f"  Applying state for {node}...")
            
            try:
                migration = graph.nodes[node]
                project_state = migration.mutate_state(project_state, preserve=False)
            except KeyError as e:
                print(f"FAILED at {node}: KeyError: {e}")
                print("Operations in this migration:")
                for op in migration.operations:
                    print(f"    {op}")
                return # Stop at first failure
            except Exception as e:
                print(f"FAILED at {node}: {type(e).__name__}: {e}")
                return

if __name__ == "__main__":
    find_failing_migration()
