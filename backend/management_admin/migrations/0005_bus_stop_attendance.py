# Generated manually for BusStopAttendance model

import uuid
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0004_add_bus_driver_email'),
    ]

    operations = [
        migrations.CreateModel(
            name='BusStopAttendance',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('attendance_date', models.DateField(help_text='Date of attendance')),
                ('status', models.CharField(choices=[('present', 'Present'), ('absent', 'Absent')], default='present', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('bus_stop_student', models.ForeignKey(help_text='Bus stop student assignment', on_delete=django.db.models.deletion.CASCADE, related_name='attendance_records', to='management_admin.busstopstudent')),
            ],
            options={
                'verbose_name': 'Bus Stop Attendance',
                'verbose_name_plural': 'Bus Stop Attendances',
                'db_table': 'bus_stop_attendance',
                'ordering': ['attendance_date', 'bus_stop_student'],
                'unique_together': {('bus_stop_student', 'attendance_date')},
            },
        ),
    ]
