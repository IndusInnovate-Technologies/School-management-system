"""
Django management command to create dummy users for all roles.
Usage: python manage.py create_dummy_users
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from main_login.models import Role

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates dummy users for all roles (admin, management, teacher, parent)'

    def handle(self, *args, **options):
        # Define roles and their corresponding users
        roles_data = [
            {
                'role_name': 'super_admin',
                'role_display': 'Super Admin',
                'users': [
                    {
                        'username': 'admin',
                        'email': 'admin@school.com',
                        'password': 'admin123',
                        'first_name': 'Super',
                        'last_name': 'Admin',
                    }
                ]
            },
            {
                'role_name': 'management_admin',
                'role_display': 'Management Admin',
                'users': [
                    {
                        'username': 'management',
                        'email': 'management@school.com',
                        'password': 'management123',
                        'first_name': 'Management',
                        'last_name': 'Admin',
                    }
                ]
            },
            {
                'role_name': 'teacher',
                'role_display': 'Teacher',
                'users': [
                    {
                        'username': 'teacher',
                        'email': 'teacher@school.com',
                        'password': 'teacher123',
                        'first_name': 'John',
                        'last_name': 'Teacher',
                    },
                    {
                        'username': 'teacher2',
                        'email': 'teacher2@school.com',
                        'password': 'teacher123',
                        'first_name': 'Jane',
                        'last_name': 'Doe',
                    }
                ]
            },
            {
                'role_name': 'student_parent',
                'role_display': 'Student/Parent',
                'users': [
                    {
                        'username': 'parent',
                        'email': 'parent@school.com',
                        'password': 'parent123',
                        'first_name': 'Parent',
                        'last_name': 'User',
                    },
                    {
                        'username': 'parent2',
                        'email': 'parent2@school.com',
                        'password': 'parent123',
                        'first_name': 'Mary',
                        'last_name': 'Smith',
                    }
                ]
            },
        ]

        created_count = 0
        updated_count = 0

        for role_info in roles_data:
            role_name = role_info['role_name']
            role_display = role_info['role_display']
            
            # Get or create role
            role, role_created = Role.objects.get_or_create(
                name=role_name,
                defaults={'description': f'{role_display} role'}
            )
            
            if role_created:
                self.stdout.write(
                    self.style.SUCCESS(f'[OK] Created role: {role_display}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'[SKIP] Role already exists: {role_display}')
                )

            # Create users for this role
            for user_data in role_info['users']:
                username = user_data['username']
                email = user_data['email']
                
                # Check if user already exists
                user, user_created = User.objects.get_or_create(
                    email=email,
                    defaults={
                        'username': username,
                        'first_name': user_data['first_name'],
                        'last_name': user_data['last_name'],
                        'role': role,
                        'is_active': True,
                        'is_verified': True,
                    }
                )
                
                if user_created:
                    user.set_password(user_data['password'])
                    user.save()
                    created_count += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'  [OK] Created user: {username} ({email}) - Password: {user_data["password"]}'
                        )
                    )
                else:
                    # Update existing user's password and role
                    user.set_password(user_data['password'])
                    user.role = role
                    user.is_active = True
                    user.is_verified = True
                    user.save()
                    updated_count += 1
                    self.stdout.write(
                        self.style.WARNING(
                            f'  [UPDATE] Updated user: {username} ({email}) - Password: {user_data["password"]}'
                        )
                    )

        self.stdout.write(self.style.SUCCESS('\n' + '='*60))
        self.stdout.write(self.style.SUCCESS('Summary:'))
        self.stdout.write(self.style.SUCCESS(f'  Created users: {created_count}'))
        self.stdout.write(self.style.SUCCESS(f'  Updated users: {updated_count}'))
        self.stdout.write(self.style.SUCCESS('='*60))
        
        # Print credentials summary
        self.stdout.write(self.style.SUCCESS('\nDUMMY CREDENTIALS SUMMARY:\n'))
        self.stdout.write(self.style.SUCCESS('Admin Login:'))
        self.stdout.write(self.style.SUCCESS('  Email: admin@school.com'))
        self.stdout.write(self.style.SUCCESS('  Password: admin123\n'))
        
        self.stdout.write(self.style.SUCCESS('Management Login:'))
        self.stdout.write(self.style.SUCCESS('  Email: management@school.com'))
        self.stdout.write(self.style.SUCCESS('  Password: management123\n'))
        
        self.stdout.write(self.style.SUCCESS('Teacher Login:'))
        self.stdout.write(self.style.SUCCESS('  Email: teacher@school.com'))
        self.stdout.write(self.style.SUCCESS('  Password: teacher123\n'))
        
        self.stdout.write(self.style.SUCCESS('Parent Login:'))
        self.stdout.write(self.style.SUCCESS('  Email: parent@school.com'))
        self.stdout.write(self.style.SUCCESS('  Password: parent123\n'))

