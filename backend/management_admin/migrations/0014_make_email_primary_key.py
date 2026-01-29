# Generated manually to change Student primary key from student_id to email

from django.db import migrations, models


def populate_email_for_existing_students(apps, schema_editor):
    """Ensure all existing students have a valid email (should already exist)"""
    Student = apps.get_model('management_admin', 'Student')
    # If any student has empty email, generate one (shouldn't happen, but safety check)
    for student in Student.objects.filter(email=''):
        # Generate a temporary email if missing
        student.email = f'student_{student.student_id}@temp.school'
        student.save()


def reverse_populate_email(apps, schema_editor):
    """Reverse migration - no action needed"""
    pass


def prepare_database_for_pk_change(apps, schema_editor):
    """Prepare database by dropping primary key constraint and making student_id nullable"""
    with schema_editor.connection.cursor() as cursor:
        # Step 1: Ensure email is unique and not null
        cursor.execute("""
            UPDATE students 
            SET email = 'temp_' || student_id::text || '@temp.school' 
            WHERE email IS NULL OR email = '';
        """)
        
        # Step 2: Get all foreign key constraints that reference students.student_id
        cursor.execute("""
            SELECT conname, conrelid::regclass
            FROM pg_constraint
            WHERE confrelid = 'students'::regclass
            AND contype = 'f';
        """)
        fk_constraints = cursor.fetchall()
        
        # Step 3: Drop all foreign key constraints temporarily
        for conname, table_name in fk_constraints:
            try:
                cursor.execute(f'ALTER TABLE {table_name} DROP CONSTRAINT IF EXISTS {conname};')
            except Exception as e:
                # Log but continue
                print(f"Warning: Could not drop constraint {conname}: {e}")
        
        # Step 4: Drop the primary key constraint on student_id
        # First, find the actual primary key constraint name
        cursor.execute("""
            SELECT constraint_name
            FROM information_schema.table_constraints
            WHERE table_name = 'students'
            AND constraint_type = 'PRIMARY KEY';
        """)
        pk_result = cursor.fetchone()
        if pk_result:
            pk_name = pk_result[0]
            cursor.execute(f'ALTER TABLE students DROP CONSTRAINT IF EXISTS {pk_name};')
        else:
            # Try default name
            cursor.execute("""
                ALTER TABLE students DROP CONSTRAINT IF EXISTS students_pkey;
            """)
        
        # Step 5: Change student_id column type if needed (UUID to VARCHAR)
        cursor.execute("""
            SELECT data_type 
            FROM information_schema.columns 
            WHERE table_name = 'students' AND column_name = 'student_id';
        """)
        result = cursor.fetchone()
        if result and result[0] == 'uuid':
            # Convert UUID to text
            cursor.execute("""
                ALTER TABLE students 
                ALTER COLUMN student_id TYPE VARCHAR(100) USING student_id::text;
            """)
        
        # Step 6: Make student_id nullable
        cursor.execute("""
            ALTER TABLE students 
            ALTER COLUMN student_id DROP NOT NULL;
        """)
        
        # Step 7: Ensure email is not null
        cursor.execute("""
            ALTER TABLE students 
            ALTER COLUMN email SET NOT NULL;
        """)


def reverse_prepare_database(apps, schema_editor):
    """Reverse migration - restore student_id as primary key"""
    with schema_editor.connection.cursor() as cursor:
        # Drop primary key on email
        cursor.execute("""
            ALTER TABLE students DROP CONSTRAINT IF EXISTS students_pkey;
        """)
        
        # Make student_id not null
        cursor.execute("""
            ALTER TABLE students 
            ALTER COLUMN student_id SET NOT NULL;
        """)
        
        # Make student_id the primary key again
        cursor.execute("""
            ALTER TABLE students 
            ADD PRIMARY KEY (student_id);
        """)


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0012_galleryimage_caption_galleryimage_uploaded_at'),
    ]

    operations = [
        # Step 1: Ensure email is populated for all existing records
        migrations.RunPython(populate_email_for_existing_students, reverse_populate_email),
        
        # Step 2: Prepare database - drop primary key constraint and make student_id nullable
        migrations.RunPython(prepare_database_for_pk_change, reverse_prepare_database),
        
        # Step 3: Update the model state - Django will handle foreign key updates automatically
        migrations.AlterField(
            model_name='student',
            name='student_id',
            field=models.CharField(
                blank=True,
                help_text='Student ID fetched from new_admissions table',
                max_length=100,
                null=True
            ),
        ),
        
        # Step 4: Make email the primary key - Django will update all foreign key references
        migrations.AlterField(
            model_name='student',
            name='email',
            field=models.EmailField(
                help_text='Primary key and used as login credential if account created',
                max_length=254,
                primary_key=True,
                serialize=False
            ),
        ),
    ]

