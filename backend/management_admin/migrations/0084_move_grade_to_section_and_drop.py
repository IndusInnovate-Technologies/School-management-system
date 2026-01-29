from django.db import migrations, models

def copy_grade_to_section(apps, schema_editor):
    # We can't use the model directly because 'grade' isn't in it.
    # We use raw SQL to ensure we capture the column even if Django doesn't know about it.
    with schema_editor.connection.cursor() as cursor:
        # Check if column 'grade' exists to avoid errors if re-run
        # (Postgres specific check, or just try/except)
        try:
            # Copy grade to section if section is null/empty and grade has value
            print("Copying data from 'grade' to 'section'...")
            cursor.execute("""
                UPDATE students 
                SET section = grade 
                WHERE (section IS NULL OR section = '') 
                AND (grade IS NOT NULL AND grade != '');
            """)
        except Exception as e:
            print(f"Skipping data copy (might be already done or column missing): {e}")

class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0083_alter_student_section'), # Depend on latest migration
    ]

    operations = [
        migrations.RunPython(copy_grade_to_section),
        # Remove the column via SQL since Django model doesn't have it
        migrations.RunSQL(
            sql='ALTER TABLE students DROP COLUMN IF EXISTS grade;',
            reverse_sql='ALTER TABLE students ADD COLUMN grade varchar(50) NULL;'
        ),
    ]
