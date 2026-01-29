from django.db.models.signals import m2m_changed
from django.dispatch import receiver
from .models import Parent

@receiver(m2m_changed, sender=Parent.students.through)
def update_parent_school_on_student_change(sender, instance, action, **kwargs):
    """Update parent's school_id and school_name when students are added/removed"""
    if action in ('post_add', 'post_remove', 'post_clear'):
        # Update school info from students
        if instance.students.exists():
            first_student = instance.students.first()
            if first_student and first_student.school:
                needs_save = False
                
                if not instance.school_id or instance.school_id != first_student.school.school_id:
                    instance.school_id = first_student.school.school_id
                    needs_save = True
                
                if not instance.school_name or instance.school_name != first_student.school.school_name:
                    instance.school_name = first_student.school.school_name
                    needs_save = True
                
                if needs_save:
                    instance.save(update_fields=['school_id', 'school_name'])

