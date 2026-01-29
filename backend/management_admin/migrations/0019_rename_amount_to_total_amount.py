# Generated manually

from django.db import migrations, models


def migrate_amount_to_total_amount(apps, schema_editor):
    """Copy amount to total_amount for existing records where total_amount is None"""
    Fee = apps.get_model('management_admin', 'Fee')
    for fee in Fee.objects.all():
        # If total_amount is None, set it to amount
        if fee.total_amount is None:
            fee.total_amount = fee.amount
            fee.save()


def reverse_migrate_total_amount_to_amount(apps, schema_editor):
    """Reverse migration - no action needed as RenameField handles it"""
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0015_update_foreign_keys_to_email'),
    ]

    operations = [
    ]

