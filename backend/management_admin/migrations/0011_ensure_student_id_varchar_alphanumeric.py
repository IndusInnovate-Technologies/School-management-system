# Generated manually to ensure student_id is VARCHAR and accepts alphanumeric values

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0010_newadmission_student_id_pk_and_fee_due_amount'),
    ]

    operations = [
        # Explicitly ensure student_id is CharField (VARCHAR) that accepts alphanumeric values
        # CharField already maps to VARCHAR in most databases and supports both numeric and alphabetic characters
        migrations.AlterField(
            model_name='newadmission',
            name='student_id',
            field=models.CharField(
                max_length=100,
                primary_key=True,
                help_text='Student ID (Primary Key) - accepts both numeric and alphabetic characters'
            ),
        ),
    ]

