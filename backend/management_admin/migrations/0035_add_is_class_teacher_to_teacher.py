# Generated manually to add is_class_teacher field to Teacher model
# Note: If the column already exists in the database, you may need to fake this migration:
# python manage.py migrate management_admin 0035 --fake
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0034_add_stop_time_to_busstop'),
    ]

    operations = [
        migrations.AddField(
            model_name='teacher',
            name='is_class_teacher',
            field=models.BooleanField(default=False, help_text='Whether the teacher is a class teacher'),
        ),
    ]

