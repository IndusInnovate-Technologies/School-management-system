# Generated manually to fix missing stop_id column in bus_stop_students table
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0036_update_busstopstudent_field_name'),
    ]

    operations = [
        # Ensure stop_id column exists in bus_stop_students table
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunSQL(
                    sql="""
                        DO $$ 
                        BEGIN
                            -- Check if stop_id column exists
                            IF NOT EXISTS (
                                SELECT 1 
                                FROM information_schema.columns 
                                WHERE table_name='bus_stop_students' 
                                AND column_name='stop_id'
                            ) THEN
                                -- If the column doesn't exist, create it
                                -- First check if the table exists
                                IF EXISTS (
                                    SELECT 1 
                                    FROM information_schema.tables 
                                    WHERE table_name='bus_stop_students'
                                ) THEN
                                    -- Add the stop_id column as UUID
                                    ALTER TABLE bus_stop_students 
                                    ADD COLUMN stop_id UUID;
                                    
                                    -- Add foreign key constraint
                                    ALTER TABLE bus_stop_students
                                    ADD CONSTRAINT bus_stop_students_stop_id_fkey
                                    FOREIGN KEY (stop_id) 
                                    REFERENCES bus_stops(stop_id) 
                                    ON DELETE CASCADE;
                                    
                                    -- Create index for better performance
                                    CREATE INDEX IF NOT EXISTS bus_stop_st_stop_id_idx 
                                    ON bus_stop_students(stop_id);
                                END IF;
                            END IF;
                        END $$;
                    """,
                    reverse_sql="-- Cannot reverse column creation",
                ),
            ],
            state_operations=[
                # No state changes needed - the model already has the field defined
                # This migration only fixes the database schema
            ],
        ),
    ]

