from django.db import migrations

class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0078_fix_missing_columns'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            ALTER TABLE teachers ADD COLUMN IF NOT EXISTS marital_status varchar(20);
            ALTER TABLE gallery_images ADD COLUMN IF NOT EXISTS photo_id varchar(100);
            """,
            reverse_sql="""
            ALTER TABLE teachers DROP COLUMN IF EXISTS marital_status;
            ALTER TABLE gallery_images DROP COLUMN IF EXISTS photo_id;
            """
        ),
    ]
