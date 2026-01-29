from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0077_remove_event_end_datetime_and_more'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.AddField(
                    model_name='teacher',
                    name='marital_status',
                    field=models.CharField(blank=True, help_text='Marital status', max_length=20, null=True),
                ),
                migrations.AddField(
                    model_name='galleryimage',
                    name='photo_id',
                    field=models.CharField(blank=True, help_text='Reference to Gallery Photo ID', max_length=100, null=True),
                ),
            ],
            state_operations=[
                # The state already believes these fields exist, so we do nothing here.
            ],
        ),
    ]
