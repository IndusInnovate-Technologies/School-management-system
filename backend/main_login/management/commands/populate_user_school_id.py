"""
Django management command to populate school_id for existing users.
Usage: python manage.py populate_user_school_id
"""
from django.core.management.base import BaseCommand
from main_login.models import User
from main_login.utils import get_user_school_id


class Command(BaseCommand):
    help = 'Populates school_id for existing users based on their relationships'

    def handle(self, *args, **options):
        users = User.objects.all()
        updated_count = 0
        skipped_count = 0
        
        for user in users:
            # Get school_id from user's relationships
            school_id = get_user_school_id(user)
            
            if school_id:
                # Update user's school_id if it's different or not set
                if user.school_id != school_id:
                    user.school_id = school_id
                    user.save(update_fields=['school_id'])
                    updated_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'Updated {user.username} ({user.email}): school_id = {school_id}'
                        )
                    )
                else:
                    skipped_count += 1
            else:
                skipped_count += 1
                self.stdout.write(
                    self.style.WARNING(
                        f'No school_id found for {user.username} ({user.email})'
                    )
                )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'\nCompleted: Updated {updated_count} users, Skipped {skipped_count} users'
            )
        )

