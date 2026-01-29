# Generated manually to fix BusStop.bus db_column reference

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('super_admin', '0001_initial'),
        ('management_admin', '0032_change_bus_primary_key_to_bus_number'),
    ]

    operations = [
        # Update model state to reflect that bus column is bus_number
        # Database already has the correct column from migration 0032
        migrations.AlterField(
            model_name='busstop',
            name='bus',
            field=models.ForeignKey(
                db_column='bus_number',
                on_delete=django.db.models.deletion.CASCADE,
                related_name='stops',
                to='management_admin.bus',
            ),
        ),
    ]
