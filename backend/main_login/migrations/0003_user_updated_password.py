# Generated migration for adding updated_password field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('main_login', '0002_alter_user_password_hash'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='updated_password',
            field=models.CharField(blank=True, help_text="User's custom created password (hashed)", max_length=255, null=True),
        ),
    ]

