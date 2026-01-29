# Generated manually to update BusStopStudent field name from 'stop' to 'bus_stop'
# The database column 'stop_id' already exists, we just need to update the model state
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0035_add_is_class_teacher_to_teacher'),
    ]

    operations = [
        # Use SeparateDatabaseAndState to only update model state, not database
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # No database changes needed - column already exists as 'stop_id'
            ],
            state_operations=[
                # Commenting out these operations since 0001_initial already has 'bus_stop' field
                # Remove old field from model state
                # migrations.RemoveField(
                #     model_name='busstopstudent',
                #     name='stop',
                # ),
                # Add new field with db_column pointing to existing column
                # migrations.AddField(
                #     model_name='busstopstudent',
                #     name='bus_stop',
                #     field=models.ForeignKey(
                #         db_column='stop_id',
                #         help_text='Bus stop where student boards/alights',
                #         on_delete=django.db.models.deletion.CASCADE,
                #         related_name='stop_students',
                #         to='management_admin.busstop'
                #     ),
                # ),
            ],
        ),
    ]

