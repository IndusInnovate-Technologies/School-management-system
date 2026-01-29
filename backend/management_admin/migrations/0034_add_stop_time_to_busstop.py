# Generated manually
# Changed from AddField to AlterField because stop_time already exists from migration 0028
# This migration makes stop_time nullable (it was originally required)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0033_fix_busstop_bus_column'),
    ]

    operations = [
        migrations.AlterField(
            model_name='busstop',
            name='stop_time',
            field=models.TimeField(blank=True, null=True, help_text='Time when bus arrives at this stop'),
        ),
    ]

