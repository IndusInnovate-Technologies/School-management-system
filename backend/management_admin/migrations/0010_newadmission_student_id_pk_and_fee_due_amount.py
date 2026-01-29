# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0009_update_newadmission_student_id'),
    ]

    operations = [
        # First, make student_id non-nullable
        migrations.AlterField(
            model_name='newadmission',
            name='student_id',
            field=models.CharField(max_length=100, help_text='Student ID (Primary Key)'),
        ),
        # Commenting out these operations since 0001_initial already has student_id as PK
        # Then remove the old primary key (id) and make student_id the primary key
        # migrations.RemoveField(
        #     model_name='newadmission',
        #     name='id',
        # ),
        # migrations.AlterField(
        #     model_name='newadmission',
        #     name='student_id',
        #     field=models.CharField(max_length=100, primary_key=True, serialize=False, help_text='Student ID (Primary Key)'),
        # ),
        # Add due_amount field to Fee
        migrations.AddField(
            model_name='fee',
            name='due_amount',
            field=models.DecimalField(decimal_places=2, default=0.0, help_text='Amount due (remaining to be paid)', max_digits=10),
        ),
    ]

