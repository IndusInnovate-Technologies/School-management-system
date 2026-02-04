# Data migration: ensure driver role has role_id 6 (there are only 6 roles; 6th is driver).
# If driver was created with id 7, move it to id 6: create role 6 if missing, reassign users, remove 7.

from django.db import migrations
from django.utils import timezone


def ensure_driver_role_id_6(apps, schema_editor):
    Role = apps.get_model('main_login', 'Role')
    User = apps.get_model('main_login', 'User')
    driver_by_name = Role.objects.filter(name='driver').first()
    role_6 = Role.objects.filter(pk=6).first()
    if not driver_by_name:
        # No driver role at all: create with id 6 if slot is free
        if role_6 is None:
            now = timezone.now()
            Role.objects.get_or_create(pk=6, defaults={'name': 'driver', 'description': 'Driver role', 'created_at': now, 'updated_at': now})
        return
    if driver_by_name.pk == 6:
        return
    # Driver exists but has id != 6 (e.g. 7)
    old_id = driver_by_name.pk
    if role_6 is None:
        # Id 6 is free: create role with id 6 using temp name to avoid unique violation, reassign users, delete old, rename
        now = timezone.now()
        Role.objects.create(
            id=6,
            name='_driver_migration_6_',
            description=getattr(driver_by_name, 'description', '') or 'Driver role',
            created_at=driver_by_name.created_at,
            updated_at=now,
        )
        User.objects.filter(role_id=old_id).update(role_id=6)
        driver_by_name.delete()
        Role.objects.filter(pk=6).update(name='driver')
    else:
        # Id 6 exists: if it's already driver, just reassign users from old id to 6 and delete old
        if role_6.name == 'driver':
            User.objects.filter(role_id=old_id).update(role_id=6)
            driver_by_name.delete()


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('main_login', '0004_fix_driver_role_name'),
    ]

    operations = [
        migrations.RunPython(ensure_driver_role_id_6, noop),
    ]
