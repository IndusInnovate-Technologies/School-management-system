"""
Django management command to create dummy credentials for all roles.
Creates at least 10 users across all roles with proper links to respective tables.

Usage: python manage.py create_role_credentials
"""
import random
from datetime import date, datetime, timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from main_login.models import Role
from super_admin.models import School
from management_admin.models import Teacher, Student, Department

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates dummy credentials for all roles (at least 10 users) with proper database links'

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=10,
            help='Minimum number of users to create (default: 10)',
        )

    def handle(self, *args, **options):
        min_count = options['count']
        
        # Get or create a default school
        school, _ = School.objects.get_or_create(
            name='Demo School',
            defaults={
                'location': 'Demo City',
                'status': 'active'
            }
        )
        self.stdout.write(self.style.SUCCESS(f'[OK] Using school: {school.name}'))
        
        # Get or create departments
        departments = []
        dept_names = ['Mathematics', 'Science', 'English', 'History', 'Computer Science']
        for dept_name in dept_names:
            dept, _ = Department.objects.get_or_create(
                school=school,
                name=dept_name,
                defaults={'description': f'{dept_name} Department'}
            )
            departments.append(dept)
        
        # Define users to create for each role
        users_data = []
        
        # Super Admin users (2)
        users_data.extend([
            {
                'role_name': 'super_admin',
                'username': 'superadmin1',
                'email': 'superadmin1@school.com',
                'password': '123456',
                'first_name': 'Super',
                'last_name': 'Admin One',
                'mobile': '9876543210',
            },
            {
                'role_name': 'super_admin',
                'username': 'superadmin2',
                'email': 'superadmin2@school.com',
                'password': '123456',
                'first_name': 'Super',
                'last_name': 'Admin Two',
                'mobile': '9876543211',
            },
        ])
        
        # Management Admin users (2)
        users_data.extend([
            {
                'role_name': 'management_admin',
                'username': 'management1',
                'email': 'management1@school.com',
                'password': '123456',
                'first_name': 'Management',
                'last_name': 'Admin One',
                'mobile': '9876543220',
            },
            {
                'role_name': 'management_admin',
                'username': 'management2',
                'email': 'management2@school.com',
                'password': '123456',
                'first_name': 'Management',
                'last_name': 'Admin Two',
                'mobile': '9876543221',
            },
        ])
        
        # Teacher users (3) - will create Teacher records
        users_data.extend([
            {
                'role_name': 'teacher',
                'username': 'teacher1',
                'email': 'teacher1@school.com',
                'password': '123456',
                'first_name': 'John',
                'last_name': 'Smith',
                'mobile': '9876543300',
                'employee_no': 'EMP001',
                'designation': 'Senior Teacher',
                'department': departments[0] if departments else None,
            },
            {
                'role_name': 'teacher',
                'username': 'teacher2',
                'email': 'teacher2@school.com',
                'password': '123456',
                'first_name': 'Jane',
                'last_name': 'Doe',
                'mobile': '9876543301',
                'employee_no': 'EMP002',
                'designation': 'Mathematics Teacher',
                'department': departments[0] if departments else None,
            },
            {
                'role_name': 'teacher',
                'username': 'teacher3',
                'email': 'teacher3@school.com',
                'password': '123456',
                'first_name': 'Robert',
                'last_name': 'Johnson',
                'mobile': '9876543302',
                'employee_no': 'EMP003',
                'designation': 'Science Teacher',
                'department': departments[1] if len(departments) > 1 else None,
            },
        ])
        
        # Student/Parent users (3) - will create Student records
        users_data.extend([
            {
                'role_name': 'student_parent',
                'username': 'student1',
                'email': 'student1@school.com',
                'password': '123456',
                'first_name': 'Alice',
                'last_name': 'Williams',
                'mobile': '9876543400',
                'student_name': 'Alice Williams',
                'parent_name': 'Parent Williams',
                'applying_class': 'Class 10A',
                'admission_number': 'ADM-2024-001',
            },
            {
                'role_name': 'student_parent',
                'username': 'student2',
                'email': 'student2@school.com',
                'password': '123456',
                'first_name': 'Bob',
                'last_name': 'Brown',
                'mobile': '9876543401',
                'student_name': 'Bob Brown',
                'parent_name': 'Parent Brown',
                'applying_class': 'Class 9B',
                'admission_number': 'ADM-2024-002',
            },
            {
                'role_name': 'student_parent',
                'username': 'student3',
                'email': 'student3@school.com',
                'password': '123456',
                'first_name': 'Charlie',
                'last_name': 'Davis',
                'mobile': '9876543402',
                'student_name': 'Charlie Davis',
                'parent_name': 'Parent Davis',
                'applying_class': 'Class 11A',
                'admission_number': 'ADM-2024-003',
            },
        ])
        
        # Add more users if needed to reach minimum count
        current_count = len(users_data)
        if current_count < min_count:
            additional_needed = min_count - current_count
            # Add more teachers
            for i in range(additional_needed):
                dept = departments[i % len(departments)] if departments else None
                users_data.append({
                    'role_name': 'teacher',
                    'username': f'teacher{4 + i}',
                    'email': f'teacher{4 + i}@school.com',
                    'password': '123456',
                    'first_name': f'Teacher{4 + i}',
                    'last_name': f'Name{4 + i}',
                    'mobile': f'9876543{300 + i}',
                    'employee_no': f'EMP{4 + i:03d}',
                    'designation': 'Teacher',
                    'department': dept,
                })
        
        # Track created users
        created_users = []
        created_teachers = []
        created_students = []
        
        # Process each user
        for user_data in users_data:
            role_name = user_data.pop('role_name')
            password = user_data.pop('password')
            
            # Get or create role
            role, _ = Role.objects.get_or_create(
                name=role_name,
                defaults={'description': f'{role_name.replace("_", " ").title()} role'}
            )
            
            # Extract role-specific data
            employee_no = user_data.pop('employee_no', None)
            designation = user_data.pop('designation', None)
            department = user_data.pop('department', None)
            student_name = user_data.pop('student_name', None)
            parent_name = user_data.pop('parent_name', None)
            applying_class = user_data.pop('applying_class', None)
            admission_number = user_data.pop('admission_number', None)
            
            # Create or get user
            email = user_data['email']
            username = user_data['username']
            
            user, user_created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': username,
                    'first_name': user_data.get('first_name', ''),
                    'last_name': user_data.get('last_name', ''),
                    'mobile': user_data.get('mobile', ''),
                    'role': role,
                    'is_active': True,
                    'has_custom_password': False,  # False so they need to create password on first login
                }
            )
            
            # Update password and role if user already exists
            if not user_created:
                user.role = role
                user.is_active = True
                user.has_custom_password = False  # Reset to False so they create password
                if user_data.get('first_name'):
                    user.first_name = user_data['first_name']
                if user_data.get('last_name'):
                    user.last_name = user_data['last_name']
                if user_data.get('mobile'):
                    user.mobile = user_data['mobile']
            
            # Set password_hash to "123456" (fixed default temporary password)
            # Set password field to unusable so authentication backend checks password_hash
            user.password_hash = "123456"  # Store temporary password in password_hash field
            user.set_unusable_password()  # Set password field to unusable (effectively null)
            user.has_custom_password = False  # User needs to create their own password
            user.save()
            created_users.append((user, user_created))
            
            # Create role-specific records
            if role_name == 'teacher':
                # Create Teacher record - try by user first, then by employee_no
                teacher = None
                teacher_created = False
                
                # Try to get existing teacher by user
                try:
                    teacher = Teacher.objects.get(user=user)
                except Teacher.DoesNotExist:
                    pass
                
                # If not found, try by employee_no
                if not teacher and employee_no:
                    try:
                        teacher = Teacher.objects.get(employee_no=employee_no)
                        # Update user link if teacher exists but has different user
                        if teacher.user != user:
                            teacher.user = user
                            teacher.save()
                    except Teacher.DoesNotExist:
                        pass
                
                # Create new teacher if doesn't exist
                if not teacher:
                    # Generate unique employee_no if not provided or if it exists
                    final_employee_no = employee_no
                    if not final_employee_no:
                        final_employee_no = f'EMP{random.randint(1000, 9999)}'
                    
                    # Ensure uniqueness
                    while Teacher.objects.filter(employee_no=final_employee_no).exists():
                        final_employee_no = f'EMP{random.randint(1000, 9999)}'
                    
                    teacher = Teacher.objects.create(
                        user=user,
                        employee_no=final_employee_no,
                        first_name=user.first_name or '',
                        last_name=user.last_name or '',
                        email=user.email,
                        mobile_no=user.mobile or '',
                        designation=designation or 'Teacher',
                        department=department,
                        joining_date=date.today() - timedelta(days=random.randint(30, 365)),
                        gender=random.choice(['Male', 'Female']),
                        qualification='B.Ed, M.Sc',
                        is_active=True,
                    )
                    teacher_created = True
                
                if teacher_created:
                    created_teachers.append(teacher)
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'  [OK] Created teacher: {user.email} (Employee: {teacher.employee_no})'
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'  [SKIP] Teacher already exists: {user.email}')
                    )
            
            elif role_name == 'student_parent':
                # Create Student record - try by email first, then by admission_number
                student = None
                student_created = False
                
                # Try to get existing student by email
                try:
                    student = Student.objects.get(email=user.email)
                except Student.DoesNotExist:
                    pass
                
                # If not found and admission_number provided, try by admission_number
                if not student and admission_number:
                    try:
                        student = Student.objects.get(admission_number=admission_number)
                        # Update user and email if student exists but has different user
                        if student.user != user:
                            student.user = user
                            student.email = user.email
                            student.save()
                    except Student.DoesNotExist:
                        pass
                
                # Create new student if doesn't exist
                if not student:
                    # Generate unique admission_number if not provided or if it exists
                    final_admission_number = admission_number
                    if not final_admission_number:
                        final_admission_number = f'ADM-{datetime.now().year}-{random.randint(100, 999)}'
                    
                    # Ensure uniqueness
                    while Student.objects.filter(admission_number=final_admission_number).exists():
                        final_admission_number = f'ADM-{datetime.now().year}-{random.randint(100, 999)}'
                    
                    student = Student.objects.create(
                        user=user,
                        school=school,
                        email=user.email,
                        student_name=student_name or f'{user.first_name} {user.last_name}',
                        parent_name=parent_name or f'Parent of {user.first_name}',
                        date_of_birth=date.today() - timedelta(days=random.randint(3650, 6200)),  # Age 10-17
                        gender=random.choice(['Male', 'Female']),
                        applying_class=applying_class or 'Class 10A',
                        admission_number=final_admission_number,
                        address='Demo Address',
                        category=random.choice(['General', 'OBC', 'SC', 'ST']),
                        parent_phone=user.mobile or '',
                    )
                    student_created = True
                
                if student_created:
                    created_students.append(student)
                    self.stdout.write(
                        self.style.SUCCESS(
                            f'  [OK] Created student: {user.email} (Admission: {student.admission_number})'
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'  [SKIP] Student already exists: {user.email}')
                    )
            
            # Log user creation
            if user_created:
                self.stdout.write(
                    self.style.SUCCESS(
                        f'  [OK] Created user: {username} ({email}) - Password: {password} - Role: {role_name}'
                    )
                )
            else:
                self.stdout.write(
                    self.style.WARNING(
                        f'  [UPDATE] Updated user: {username} ({email}) - Password: {password} - Role: {role_name}'
                    )
                )
        
        # Print summary
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS('SUMMARY:'))
        self.stdout.write(self.style.SUCCESS(f'  Total users processed: {len(created_users)}'))
        self.stdout.write(self.style.SUCCESS(f'  Teachers created: {len(created_teachers)}'))
        self.stdout.write(self.style.SUCCESS(f'  Students created: {len(created_students)}'))
        self.stdout.write(self.style.SUCCESS('='*70))
        
        # Print credentials summary
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS('DUMMY CREDENTIALS FOR LOGIN:\n'))
        
        # Group by role
        role_groups = {}
        for user, _ in created_users:
            role_name = user.role.name if user.role else 'No Role'
            if role_name not in role_groups:
                role_groups[role_name] = []
            role_groups[role_name].append(user)
        
        for role_name, users in role_groups.items():
            self.stdout.write(self.style.SUCCESS(f'\n{role_name.replace("_", " ").title()} Users:'))
            for user in users:
                # Show temporary password from password_hash
                temp_password = user.password_hash if user.password_hash else 'N/A'
                self.stdout.write(
                    self.style.SUCCESS(f'  Email: {user.email}')
                )
                self.stdout.write(
                    self.style.SUCCESS(f'  Temporary Password (password_hash): {temp_password}')
                )
                self.stdout.write(
                    self.style.SUCCESS(f'  Needs Password Creation: {user.needs_password_creation()}')
                )
                self.stdout.write('')
        
        self.stdout.write(self.style.SUCCESS('='*70))
        self.stdout.write(self.style.SUCCESS('\nPASSWORD CREATION FLOW'))
        self.stdout.write(self.style.SUCCESS('='*70))
        self.stdout.write(self.style.SUCCESS('\n1. Initial Login:'))
        self.stdout.write(self.style.SUCCESS('   - All users can login with temporary password: 123456'))
        self.stdout.write(self.style.SUCCESS('   - password_hash field in users table = "123456"'))
        self.stdout.write(self.style.SUCCESS('   - has_custom_password = False'))
        self.stdout.write(self.style.SUCCESS('\n2. After Login:'))
        self.stdout.write(self.style.SUCCESS('   - Users will be redirected to create password page'))
        self.stdout.write(self.style.SUCCESS('   - They must create their own password (minimum 8 characters)'))
        self.stdout.write(self.style.SUCCESS('\n3. Password Storage:'))
        self.stdout.write(self.style.SUCCESS('   - Created password is saved in users.password field (Django hash)'))
        self.stdout.write(self.style.SUCCESS('   - password_hash is cleared (set to None)'))
        self.stdout.write(self.style.SUCCESS('   - has_custom_password is set to True'))
        self.stdout.write(self.style.SUCCESS('\n4. Future Logins:'))
        self.stdout.write(self.style.SUCCESS('   - Users login with their own created password'))
        self.stdout.write(self.style.SUCCESS('\nUse role_login endpoint with appropriate role parameter:\n'))
        self.stdout.write(self.style.SUCCESS('  - admin (for super_admin)'))
        self.stdout.write(self.style.SUCCESS('  - management (for management_admin)'))
        self.stdout.write(self.style.SUCCESS('  - teacher (for teacher)'))
        self.stdout.write(self.style.SUCCESS('  - parent (for student_parent)'))

