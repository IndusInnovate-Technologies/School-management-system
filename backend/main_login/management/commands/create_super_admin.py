"""
Django management command to create a super_admin user.
Usage: python manage.py create_super_admin
       python manage.py create_super_admin --email admin@example.com --password admin123
"""
import random
import string
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from main_login.models import Role

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates a super_admin user with login credentials'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            help='Email address for the super admin (default: superadmin@school.com)',
            default='superadmin@school.com'
        )
        parser.add_argument(
            '--username',
            type=str,
            help='Username for the super admin (default: auto-generated from email)',
            default=None
        )
        parser.add_argument(
            '--password',
            type=str,
            help='Password for the super admin (default: auto-generated 8-character password)',
            default=None
        )
        parser.add_argument(
            '--first-name',
            type=str,
            help='First name for the super admin (default: Super)',
            default='Super'
        )
        parser.add_argument(
            '--last-name',
            type=str,
            help='Last name for the super admin (default: Admin)',
            default='Admin'
        )

    def handle(self, *args, **options):
        email = options['email']
        username = options['username']
        password = options['password']
        first_name = options['first_name']
        last_name = options['last_name']
        
        # Generate username from email if not provided
        if not username:
            username = email.split('@')[0]
            # Ensure username is unique
            base_username = username
            counter = 1
            while User.objects.filter(username=username).exists():
                username = f'{base_username}{counter}'
                counter += 1
        
        # Generate 8-character password if not provided
        if not password:
            characters = string.ascii_letters + string.digits
            password = ''.join(random.choice(characters) for _ in range(8))
        
        # Get or create super_admin role
        role, role_created = Role.objects.get_or_create(
            name='super_admin',
            defaults={'description': 'Super Admin role'}
        )
        
        if role_created:
            self.stdout.write(
                self.style.SUCCESS(f'[OK] Created role: Super Admin')
            )
        else:
            self.stdout.write(
                self.style.WARNING(f'[SKIP] Role already exists: Super Admin')
            )
        
        # Check if user already exists
        try:
            user = User.objects.get(email=email)
            # Update existing user
            user.username = username
            user.first_name = first_name
            user.last_name = last_name
            user.role = role
            user.is_active = True
            user.has_custom_password = False
            
            # Set password_hash to the provided/generated password
            user.password_hash = password
            user.set_unusable_password()  # This sets password field to unusable
            user.has_custom_password = False
            user.save()
            
            self.stdout.write(
                self.style.WARNING(
                    f'[UPDATE] Updated existing user: {username} ({email})'
                )
            )
            user_created = False
        except User.DoesNotExist:
            # Create new user
            user = User.objects.create(
                email=email,
                username=username,
                first_name=first_name,
                last_name=last_name,
                role=role,
                is_active=True,
                has_custom_password=False,
            )
            
            # Set password_hash to the provided/generated password
            user.password_hash = password
            user.set_unusable_password()  # This sets password field to unusable
            user.has_custom_password = False
            user.save()
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Created user: {username} ({email})'
                )
            )
            user_created = True
        
        # Print credentials
        self.stdout.write(self.style.SUCCESS('\n' + '='*60))
        self.stdout.write(self.style.SUCCESS('SUPER ADMIN CREDENTIALS:'))
        self.stdout.write(self.style.SUCCESS('='*60))
        self.stdout.write(self.style.SUCCESS(f'Email: {email}'))
        self.stdout.write(self.style.SUCCESS(f'Username: {username}'))
        self.stdout.write(self.style.SUCCESS(f'Password: {password}'))
        self.stdout.write(self.style.SUCCESS('='*60))
        self.stdout.write(
            self.style.WARNING(
                '\n⚠️  Please save these credentials. You can use them to login.'
            )
        )
        
        if not user_created:
            self.stdout.write(
                self.style.WARNING(
                    '\nNote: User already existed. Password and role have been updated.'
                )
            )

