from django.db import migrations

class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0079_force_add_missing_columns'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            ALTER TABLE teachers ADD COLUMN IF NOT EXISTS permanent_address text;
            ALTER TABLE gallery_images ADD COLUMN IF NOT EXISTS caption varchar(255);
            """,
            reverse_sql="""
            ALTER TABLE teachers DROP COLUMN IF EXISTS permanent_address;
            ALTER TABLE gallery_images DROP COLUMN IF EXISTS caption;
            """
        ),
    ]
