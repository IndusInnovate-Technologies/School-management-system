# Generated manually for UserNotificationSeen

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('main_login', '0004_fix_driver_role_name'),
    ]

    operations = [
        migrations.CreateModel(
            name='UserNotificationSeen',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('last_seen_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='notification_seen', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'User Notification Seen',
                'verbose_name_plural': 'User Notification Seen',
                'db_table': 'user_notification_seen',
            },
        ),
    ]
