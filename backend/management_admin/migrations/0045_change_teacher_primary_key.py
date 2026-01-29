# Generated manually to change Teacher primary key from teacher_id to employee_no

from django.db import migrations, models
import django.utils.timezone


def populate_employee_no_for_existing_teachers(apps, schema_editor):
    """Populate employee_no for existing teachers that have null values"""
    Teacher = apps.get_model('management_admin', 'Teacher')
    import random
    import string
    from django.utils import timezone
    
    teachers_without_emp_no = Teacher.objects.filter(employee_no__isnull=True)
    for teacher in teachers_without_emp_no:
        # Generate unique employee number
        timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
        random_suffix = ''.join(random.choices(string.digits, k=4))
        employee_no = f'EMP{timestamp}{random_suffix}'
        
        # Ensure uniqueness
        while Teacher.objects.filter(employee_no=employee_no).exists():
            random_suffix = ''.join(random.choices(string.digits, k=4))
            employee_no = f'EMP{timestamp}{random_suffix}'
        
        teacher.employee_no = employee_no
        teacher.save(update_fields=['employee_no'])


def reverse_populate_employee_no(apps, schema_editor):
    """Reverse operation - nothing to do as employee_no will remain"""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0039_change_busstop_id_to_formatted_string'),
    ]

    operations = [
        # Step 1: Ensure all teachers have employee_no
        migrations.RunPython(populate_employee_no_for_existing_teachers, reverse_populate_employee_no),
        
        # Step 2: Remove the unwanted fields first
        # Commenting out these RemoveField operations since fields don't exist in 0001_initial
        # migrations.RemoveField(
        #     model_name='teacher',
        #     name='primary_room_id',
        # ),
        # migrations.RemoveField(
        #     model_name='teacher',
        #     name='class_teacher_section_id',
        # ),
        
        # Step 3: Make employee_no non-nullable
        migrations.AlterField(
            model_name='teacher',
            name='employee_no',
            field=models.CharField(max_length=50, unique=True),
        ),
        
        # Step 4: Change primary key from teacher_id to employee_no using SeparateDatabaseAndState
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # All database changes happen here
                migrations.RunSQL(
                    sql="""
                        -- Step 4a: Drop all foreign key constraints that reference teacher_id
                        DO $$ 
                        DECLARE
                            r RECORD;
                        BEGIN
                            FOR r IN (
                                SELECT 
                                    tc.constraint_name, 
                                    tc.table_name
                                FROM information_schema.table_constraints tc
                                JOIN information_schema.key_column_usage kcu
                                    ON tc.constraint_name = kcu.constraint_name
                                    AND tc.table_schema = kcu.table_schema
                                WHERE tc.constraint_type = 'FOREIGN KEY'
                                AND kcu.column_name = 'teacher_id'
                                AND tc.table_schema = 'public'
                            ) LOOP
                                BEGIN
                                    EXECUTE 'ALTER TABLE ' || quote_ident(r.table_name) || 
                                            ' DROP CONSTRAINT IF EXISTS ' || quote_ident(r.constraint_name) || ' CASCADE';
                                EXCEPTION WHEN OTHERS THEN
                                    NULL;
                                END;
                            END LOOP;
                        END $$;
                        
                        -- Step 4b: Drop the old primary key constraint on teacher_id
                        ALTER TABLE teachers DROP CONSTRAINT IF EXISTS teachers_pkey CASCADE;
                        
                        -- Step 4c: Drop the unique constraint on employee_no if it exists
                        ALTER TABLE teachers DROP CONSTRAINT IF EXISTS teachers_employee_no_key;
                        
                        -- Step 4d: Make employee_no the primary key
                        ALTER TABLE teachers ADD PRIMARY KEY (employee_no);
                        
                        -- Step 4e: Drop the teacher_id column
                        ALTER TABLE teachers DROP COLUMN IF EXISTS teacher_id CASCADE;
                    """,
                    reverse_sql="""
                        -- Reverse: Re-add teacher_id (simplified - full reverse would need data migration)
                        DO $$
                        BEGIN
                            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='teachers' AND column_name='teacher_id') THEN
                                ALTER TABLE teachers ADD COLUMN teacher_id UUID;
                                ALTER TABLE teachers ALTER COLUMN teacher_id SET DEFAULT gen_random_uuid();
                                UPDATE teachers SET teacher_id = gen_random_uuid() WHERE teacher_id IS NULL;
                                ALTER TABLE teachers ALTER COLUMN teacher_id SET NOT NULL;
                                
                                ALTER TABLE teachers DROP CONSTRAINT IF EXISTS teachers_pkey CASCADE;
                                ALTER TABLE teachers ADD PRIMARY KEY (teacher_id);
                                CREATE UNIQUE INDEX IF NOT EXISTS teachers_employee_no_key ON teachers(employee_no);
                            END IF;
                        END $$;
                    """,
                ),
            ],
            state_operations=[
                # Update Django's model state - make employee_no primary key
                # Note: teacher_id field removal is handled by Django automatically when we change the primary key
                migrations.AlterField(
                    model_name='teacher',
                    name='employee_no',
                    field=models.CharField(max_length=50, primary_key=True, serialize=False),
                ),
                migrations.AlterField(
                    model_name='teacher',
                    name='first_name',
                    field=models.CharField(max_length=150),
                ),
            ],
        ),
    ]

