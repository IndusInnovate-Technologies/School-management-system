# Generated migration: add student_name, student_id, school_id to BusStopAttendance

from django.db import migrations, models


def backfill_student_fields(apps, schema_editor):
    BusStopAttendance = apps.get_model('management_admin', 'BusStopAttendance')
    for att in BusStopAttendance.objects.select_related('bus_stop_student').all():
        bss = att.bus_stop_student
        att.student_name = bss.student_name or ''
        att.student_id = bss.student_id_string or ''
        att.school_id = bss.school_id or ''
        att.save(update_fields=['student_name', 'student_id', 'school_id'])


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0005_bus_stop_attendance'),
    ]

    operations = [
        migrations.AddField(
            model_name='busstopattendance',
            name='student_name',
            field=models.CharField(blank=True, help_text='Student name (from bus stop student)', max_length=255),
        ),
        migrations.AddField(
            model_name='busstopattendance',
            name='student_id',
            field=models.CharField(blank=True, db_index=True, help_text='Student ID (from bus stop student)', max_length=100),
        ),
        migrations.AddField(
            model_name='busstopattendance',
            name='school_id',
            field=models.CharField(blank=True, db_index=True, help_text='School ID (from bus stop student)', max_length=100, null=True),
        ),
        migrations.RunPython(backfill_student_fields, noop),
    ]
