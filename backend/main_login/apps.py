from django.apps import AppConfig


class MainLoginConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'main_login'
    verbose_name = 'Main Login'

    def ready(self):
        """Import signals to register them"""
        import main_login.signals  # noqa

