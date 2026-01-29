from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('management_admin', '0066_delete_awarddocument'),
    ]
    operations = [
        migrations.AddField(
            model_name='event',
            name='date',
            field=models.DateField(default='2026-01-01', help_text='Event date'),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='event',
            name='time',
            field=models.CharField(blank=True, default='', help_text='Event time', max_length=100),
        ),
    ]
