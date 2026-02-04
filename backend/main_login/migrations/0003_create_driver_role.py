# Data migration: ensure 'driver' role exists

from django.db import migrations


def create_driver_role(apps, schema_editor):
    Role = apps.get_model('main_login', 'Role')
    Role.objects.get_or_create(
        name='driver',
        defaults={'description': 'Driver role'}
    )


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('main_login', '0002_add_fcm_device'),
    ]

    operations = [
        migrations.RunPython(create_driver_role, noop),
    ]
