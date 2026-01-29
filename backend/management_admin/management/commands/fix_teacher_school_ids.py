from django.core.management.base import BaseCommand
from management_admin.models import Teacher

class Command(BaseCommand):
    help = 'Fix teacher school_id values from their departments'

    def handle(self, *args, **options):
        teachers = Teacher.objects.select_related('department', 'department__school').all()
        fixed_count = 0
        skipped_count = 0
        
        for teacher in teachers:
            try:
                if teacher.department:
                    # Use select_related to avoid N+1 queries
                    department = teacher.department
                    if hasattr(department, 'school') and department.school:
                        expected_school_id = department.school.school_id
                        expected_school_name = department.school.school_name
                        
                        needs_fix = False
                        if not teacher.school_id or teacher.school_id != expected_school_id:
                            teacher.school_id = expected_school_id
                            needs_fix = True
                        
                        if not teacher.school_name or teacher.school_name != expected_school_name:
                            teacher.school_name = expected_school_name
                            needs_fix = True
                        
                        if needs_fix:
                            teacher.save(update_fields=['school_id', 'school_name'])
                            fixed_count += 1
                            self.stdout.write(
                                f'Fixed teacher {teacher.employee_no}: school_id={teacher.school_id}'
                            )
                    else:
                        skipped_count += 1
                        self.stdout.write(
                            self.style.WARNING(f'Teacher {teacher.employee_no} has department but no school')
                        )
                else:
                    skipped_count += 1
                    self.stdout.write(
                        self.style.WARNING(f'Teacher {teacher.employee_no} has no department')
                    )
            except Exception as e:
                skipped_count += 1
                self.stdout.write(
                    self.style.ERROR(f'Error processing teacher {teacher.employee_no}: {e}')
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'Fixed {fixed_count} teachers')
        )
        if skipped_count > 0:
            self.stdout.write(
                self.style.WARNING(f'Skipped {skipped_count} teachers')
            )

