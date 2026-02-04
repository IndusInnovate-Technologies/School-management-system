# Add driver_email to Bus for creating driver login credentials

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('management_admin', '0003_add_driver_model'),
    ]

    operations = [
        migrations.AddField(
            model_name='bus',
            name='driver_email',
            field=models.EmailField(blank=True, help_text='Driver login email; credentials created so driver can log in and see this bus', max_length=254),
        ),
    ]
