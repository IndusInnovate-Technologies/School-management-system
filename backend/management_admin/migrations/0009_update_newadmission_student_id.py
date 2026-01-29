# Generated manually

from django.db import migrations
import uuid


def populate_student_ids(apps, schema_editor):
    """Populate student_id for existing NewAdmission records"""
    NewAdmission = apps.get_model('management_admin', 'NewAdmission')
    
    for admission in NewAdmission.objects.filter(student_id__isnull=True):
        # Generate a unique student_id if it doesn't exist
        admission.student_id = f'STD-{uuid.uuid4().hex[:8].upper()}'
        admission.save()


def reverse_populate_student_ids(apps, schema_editor):
    """Reverse migration - set student_id to None"""
    NewAdmission = apps.get_model('management_admin', 'NewAdmission')
    NewAdmission.objects.all().update(student_id=None)


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0008_alter_event_options_event_date'),
    ]

    operations = [
        migrations.RunPython(populate_student_ids, reverse_populate_student_ids),
    ]
