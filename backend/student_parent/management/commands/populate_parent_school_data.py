from django.core.management.base import BaseCommand
from student_parent.models import Parent

class Command(BaseCommand):
    help = 'Populate school_id and school_name for parents from their students'

    def handle(self, *args, **options):
        parents = Parent.objects.all()
        updated_count = 0
        skipped_count = 0
        
        for parent in parents:
            if parent.students.exists():
                first_student = parent.students.first()
                if first_student and first_student.school:
                    needs_update = False
                    
                    if not parent.school_id or parent.school_id != first_student.school.school_id:
                        parent.school_id = first_student.school.school_id
                        needs_update = True
                    
                    if not parent.school_name or parent.school_name != first_student.school.school_name:
                        parent.school_name = first_student.school.school_name
                        needs_update = True
                    
                    if needs_update:
                        parent.save(update_fields=['school_id', 'school_name'])
                        updated_count += 1
                        self.stdout.write(
                            f'Updated parent {parent.id}: school_id={parent.school_id}, school_name={parent.school_name}'
                        )
                else:
                    skipped_count += 1
                    self.stdout.write(
                        self.style.WARNING(f'Parent {parent.id} has students but no school assigned to students')
                    )
            else:
                skipped_count += 1
                self.stdout.write(
                    self.style.WARNING(f'Parent {parent.id} has no students linked')
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully updated {updated_count} parent records')
        )
        if skipped_count > 0:
            self.stdout.write(
                self.style.WARNING(f'Skipped {skipped_count} parent records (no students or no school)')
            )

