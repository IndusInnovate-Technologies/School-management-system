# Generated manually for Driver model

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('management_admin', '0002_push_notification_log'),
    ]

    operations = [
        migrations.AddField(
            model_name='busstop',
            name='notes',
            field=models.TextField(blank=True, help_text='Driver notes for this stop (e.g. gate code, landmarks)'),
        ),
        migrations.CreateModel(
            name='Driver',
            fields=[
                ('user', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    primary_key=True,
                    related_name='driver_profile',
                    to=settings.AUTH_USER_MODEL,
                    help_text='User account with driver role',
                )),
                ('employee_id', models.CharField(blank=True, help_text='Driver employee ID', max_length=100)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('bus', models.ForeignKey(
                    blank=True,
                    db_column='bus_number',
                    help_text='Assigned bus (null if not yet assigned)',
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='assigned_driver',
                    to='management_admin.bus',
                )),
            ],
            options={
                'verbose_name': 'Driver',
                'verbose_name_plural': 'Drivers',
                'db_table': 'drivers',
            },
        ),
    ]
