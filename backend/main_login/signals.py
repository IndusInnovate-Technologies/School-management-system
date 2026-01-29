"""
Signals to auto-populate school_id in User model when related profiles are created/updated
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from main_login.models import User
from main_login.utils import get_user_school_id


@receiver(post_save, sender='management_admin.Teacher')
def update_user_school_id_from_teacher(sender, instance, **kwargs):
    """
    Update user's school_id when Teacher profile is created/updated
    """
    if instance.user:
        school_id = get_user_school_id(instance.user)
        if school_id and instance.user.school_id != school_id:
            # Use update_fields to avoid triggering save() again
            User.objects.filter(user_id=instance.user.user_id).update(school_id=school_id)


@receiver(post_save, sender='management_admin.Student')
def update_user_school_id_from_student(sender, instance, **kwargs):
    """
    Update user's school_id when Student profile is created/updated
    """
    if instance.user:
        school_id = get_user_school_id(instance.user)
        if school_id and instance.user.school_id != school_id:
            # Use update_fields to avoid triggering save() again
            User.objects.filter(user_id=instance.user.user_id).update(school_id=school_id)

