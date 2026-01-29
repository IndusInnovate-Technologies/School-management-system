from django.apps import AppConfig


class StudentParentConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'student_parent'
    verbose_name = 'Student Parent'
    
    def ready(self):
        import student_parent.signals  # noqa

