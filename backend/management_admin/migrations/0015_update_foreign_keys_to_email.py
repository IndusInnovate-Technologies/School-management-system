# Generated manually to update foreign key columns to reference email instead of student_id UUID

from django.db import migrations


def update_foreign_key_columns(apps, schema_editor):
    """Update all foreign key columns that reference Student to use email instead of UUID"""
    with schema_editor.connection.cursor() as cursor:
        # Step 1: Get all foreign keys that reference students table
        cursor.execute("""
            SELECT 
                conrelid::regclass AS table_name, 
                conname AS constraint_name,
                a.attname AS column_name
            FROM pg_constraint c
            JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
            WHERE confrelid = 'students'::regclass
            AND contype = 'f';
        """)
        
        foreign_keys = cursor.fetchall()
        
        for table_name, constraint_name, column_name in foreign_keys:
            table_name_str = str(table_name).replace('"', '')
            
            # Skip if this is the students table itself
            if table_name_str == 'students':
                continue
            
            # Step 2: Drop the foreign key constraint
            cursor.execute(f'ALTER TABLE {table_name_str} DROP CONSTRAINT IF EXISTS {constraint_name};')
            
            # Step 3: Check column type and convert if needed
            cursor.execute("""
                SELECT data_type 
                FROM information_schema.columns 
                WHERE table_name = %s AND column_name = %s;
            """, [table_name_str, column_name])
            
            col_result = cursor.fetchone()
            if col_result and col_result[0] == 'uuid':
                # Convert UUID column to VARCHAR(254)
                # Note: This will convert UUID values to their string representation
                # The actual email values will need to be set by the application
                cursor.execute(f"""
                    ALTER TABLE {table_name_str} 
                    ALTER COLUMN {column_name} TYPE VARCHAR(254) USING {column_name}::text;
                """)
                
                # Set all values to NULL since we can't map UUIDs to emails
                # The application will need to repopulate these
                cursor.execute(f"""
                    UPDATE {table_name_str} 
                    SET {column_name} = NULL;
                """)
            elif col_result and col_result[0] not in ['character varying', 'varchar']:
                # Convert other types to VARCHAR
                cursor.execute(f"""
                    ALTER TABLE {table_name_str} 
                    ALTER COLUMN {column_name} TYPE VARCHAR(254) USING {column_name}::text;
                """)
            
            # Step 4: Recreate foreign key constraint pointing to students.email
            new_constraint_name = f"{constraint_name}_email_fk"
            try:
                cursor.execute(f"""
                    ALTER TABLE {table_name_str} 
                    ADD CONSTRAINT {new_constraint_name} 
                    FOREIGN KEY ({column_name}) REFERENCES students(email) ON DELETE CASCADE;
                """)
            except Exception as e:
                # If constraint creation fails (e.g., due to NULL values), make column nullable
                cursor.execute(f"""
                    ALTER TABLE {table_name_str} 
                    ALTER COLUMN {column_name} DROP NOT NULL;
                """)
                cursor.execute(f"""
                    ALTER TABLE {table_name_str} 
                    ADD CONSTRAINT {new_constraint_name} 
                    FOREIGN KEY ({column_name}) REFERENCES students(email) ON DELETE CASCADE;
                """)


def reverse_update_foreign_keys(apps, schema_editor):
    """Reverse migration - this is complex and may not be fully reversible"""
    # This would require storing the original UUID values, which we don't have
    # So we'll just leave a placeholder
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0014_make_email_primary_key'),
    ]

    operations = [
        migrations.RunPython(update_foreign_key_columns, reverse_update_foreign_keys),
    ]

