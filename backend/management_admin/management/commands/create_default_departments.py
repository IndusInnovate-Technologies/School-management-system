"""
Django management command to create default departments for schools.
Usage: python manage.py create_default_departments
       python manage.py create_default_departments --school-id <school_id>
"""
from django.core.management.base import BaseCommand
from management_admin.models import Department
from super_admin.models import School


class Command(BaseCommand):
    help = 'Creates default departments for schools (from old designation names)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--school-id',
            type=str,
            help='School ID to create departments for (if not provided, creates for all schools)',
            default=None
        )

    def handle(self, *args, **options):
        # Default department names from old designation dropdown
        default_departments = [
            'Mathematics',
            'Physics',
            'Chemistry',
            'Biology',
            'English',
            'History',
            'Geography',
            'Computer Science',
            'Art',
            'Music',
            'Principal',
            'Vice Principal',
            'Coordinator',
        ]

        school_id = options.get('school_id')
        
        if school_id:
            # Create departments for specific school
            try:
                school = School.objects.get(school_id=school_id)
                self._create_departments_for_school(school, default_departments)
            except School.DoesNotExist:
                self.stdout.write(
                    self.style.ERROR(f'School with ID {school_id} not found')
                )
        else:
            # Create departments for all schools
            schools = School.objects.all()
            if not schools.exists():
                self.stdout.write(
                    self.style.WARNING('No schools found. Please create a school first.')
                )
                return

            for school in schools:
                self._create_departments_for_school(school, default_departments)

    def _create_departments_for_school(self, school, department_names):
        """Create departments for a specific school"""
        created_count = 0
        skipped_count = 0

        for dept_name in department_names:
            # Check if department already exists for this school
            if Department.objects.filter(school=school, name=dept_name).exists():
                skipped_count += 1
                continue

            # Create the department
            Department.objects.create(
                school=school,
                name=dept_name,
                description=f'{dept_name} department'
            )
            created_count += 1

        if created_count > 0:
            self.stdout.write(
                self.style.SUCCESS(
                    f'Created {created_count} departments for {school.name} ({school.school_id})'
                )
            )
        if skipped_count > 0:
            self.stdout.write(
                self.style.WARNING(
                    f'Skipped {skipped_count} departments (already exist) for {school.name}'
                )
            )

