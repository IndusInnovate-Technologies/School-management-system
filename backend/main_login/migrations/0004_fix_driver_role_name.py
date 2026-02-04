# Data migration: fix driver role name (driver_bus -> driver)

from django.db import migrations


def fix_driver_role_name(apps, schema_editor):
    Role = apps.get_model('main_login', 'Role')
    User = apps.get_model('main_login', 'User')
    driver_bus_role = Role.objects.filter(name='driver_bus').first()
    driver_role = Role.objects.filter(name='driver').first()
    if driver_bus_role:
        if driver_role:
            # Both exist: reassign users from driver_bus to driver, then remove driver_bus
            User.objects.filter(role=driver_bus_role).update(role=driver_role)
            driver_bus_role.delete()
        else:
            # Only driver_bus exists: rename to driver
            driver_bus_role.name = 'driver'
            driver_bus_role.save(update_fields=['name', 'updated_at'])


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('main_login', '0003_create_driver_role'),
    ]

    operations = [
        migrations.RunPython(fix_driver_role_name, noop),
    ]
