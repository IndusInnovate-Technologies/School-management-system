"""
Models for management_admin app - API layer for App 2
"""
import uuid
from datetime import date
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator, FileExtensionValidator
from django.core.exceptions import ValidationError
from main_login.models import User
from super_admin.models import School


def validate_file_size(value):
    """Validate file size is between 2MB and 4MB"""
    max_size = 4 * 1024 * 1024  # 4MB
    min_size = 2 * 1024 * 1024  # 2MB
    if value.size > max_size:
        raise ValidationError(f'File size cannot exceed 4MB. Current size: {value.size / (1024*1024):.2f}MB')
    if value.size < min_size:
        raise ValidationError(f'File size must be at least 2MB. Current size: {value.size / (1024*1024):.2f}MB')


class File(models.Model):
    """File model to store uploaded files"""
    file_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    file = models.FileField(
        upload_to='profile_photos/',
        validators=[
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'gif']),
            validate_file_size
        ],
        help_text='Profile photo (2-4MB, jpg/jpeg/png/gif only)'
    )
    file_name = models.CharField(max_length=255)
    file_type = models.CharField(max_length=50)
    file_size = models.IntegerField(help_text='File size in bytes')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='uploaded_files'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate file metadata and school_id"""
        if self.file and not self.file_name:
            self.file_name = self.file.name
        if self.file and not self.file_type:
            import os
            ext = os.path.splitext(self.file.name)[1].lower().lstrip('.')
            self.file_type = ext
        if self.file and not self.file_size:
            self.file_size = self.file.size
        
        # Auto-populate school_id and school_name from uploaded_by user if available
        if self.uploaded_by and not self.school_id:
            from main_login.utils import get_user_school_id, get_user_school
            school_id = get_user_school_id(self.uploaded_by)
            if school_id:
                self.school_id = school_id
                # Get school name
                school = get_user_school(self.uploaded_by)
                if school:
                    self.school_name = school.school_name
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.file_name} ({self.file_id})"
    
    class Meta:
        db_table = 'files'
        verbose_name = 'File'
        verbose_name_plural = 'Files'


class Department(models.Model):
    """Department model"""
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='departments')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False)
    
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, blank=True)
    description = models.TextField(blank=True)
    head_name = models.CharField(max_length=255, blank=True, help_text="Name of the department head")
    head = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='headed_departments'
    )
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    faculty_count = models.IntegerField(default=0)
    student_count = models.IntegerField(default=0)
    course_count = models.IntegerField(default=0)
    established_date = models.DateField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        if self.school and not self.school_name:
            self.school_name = self.school.school_name
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.school_name or self.school.school_name}"
    
    class Meta:
        db_table = 'departments'
        verbose_name = 'Department'
        verbose_name_plural = 'Departments'
        unique_together = ['school', 'name']


class CampusFeature(models.Model):
    """Model for school campus features and facilities"""
    
    CATEGORY_CHOICES = [
        ('academic', 'Academic Facilities'),
        ('sports', 'Sports & Recreation'),
        ('technology', 'Technology & Labs'),
        ('arts', 'Arts & Culture'),
        ('infrastructure', 'Infrastructure'),
        ('amenities', 'Amenities'),
        ('speciality', 'Campus Speciality'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('under-construction', 'Under Construction'),
        ('planned', 'Planned'),
        ('maintenance', 'Under Maintenance'),
    ]

    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='campus_features', null=True)
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False)
    
    name = models.CharField(max_length=255)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='academic')
    description = models.TextField(blank=True)
    location = models.CharField(max_length=255)
    capacity = models.CharField(max_length=100, blank=True, null=True)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='active')
    date_added = models.DateField(auto_now_add=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if self.school and not self.school_name:
            self.school_name = self.school.school_name
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} ({self.category})"

    class Meta:
        db_table = 'campus_features'
        verbose_name = 'Campus Feature'
        verbose_name_plural = 'Campus Features'
        ordering = ['-date_added', '-created_at']
        unique_together = ['school', 'name']


class Teacher(models.Model):
    """Teacher model"""
    employee_no = models.CharField(max_length=50, primary_key=True, help_text='Employee number (unique identifier)')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='user_id',
        related_name='teacher_profiles',
        help_text='If teacher has login'
    )
    first_name = models.CharField(max_length=150, null=False, help_text='First name (required)')
    last_name = models.CharField(max_length=150, null=True, blank=True, help_text='Last name')
    qualification = models.CharField(max_length=255, null=True, blank=True, help_text='Educational qualifications')
    joining_date = models.DateField(null=True, blank=True, help_text='Date of joining')
    dob = models.DateField(null=True, blank=True, help_text='Date of Birth')
    
    GENDER_CHOICES = [
        ('Male', 'Male'),
        ('Female', 'Female'),
        ('Other', 'Other'),
    ]
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, null=True, blank=True, help_text='Gender')
    
    # Foreign key to Department
    department = models.ForeignKey(
        Department,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='department_id',
        related_name='teachers',
        help_text='Department assignment'
    )
    
    # Contact and personal information
    blood_group = models.CharField(max_length=10, null=True, blank=True, help_text='Blood group')
    nationality = models.CharField(max_length=100, null=True, blank=True, help_text='Nationality')
    mobile_no = models.CharField(max_length=20, null=True, blank=True, help_text='Mobile phone number')
    email = models.EmailField(null=True, blank=True, help_text='Email address')
    address = models.TextField(null=True, blank=True, help_text='Address')
    
    # Class teacher assignment fields
    class_teacher_class = models.CharField(max_length=50, null=True, blank=True, help_text='Class name for class teacher assignment (e.g., Grade 9, 10)')
    class_teacher_section = models.CharField(max_length=10, null=True, blank=True, help_text='Section for class teacher assignment (e.g., A, B, C, D)')
    subject_specialization = models.TextField(null=True, blank=True, help_text='Subject specialization details')
    emergency_contact = models.CharField(max_length=20, null=True, blank=True, help_text='Emergency contact number')
    emergency_contact_relation = models.CharField(max_length=50, null=True, blank=True, help_text='Relation with emergency contact')
    salary = models.CharField(max_length=50, null=True, blank=True, help_text='Salary information')
    experience = models.CharField(max_length=50, null=True, blank=True, help_text='Years of experience')
    marital_status = models.CharField(max_length=20, null=True, blank=True, help_text='Marital status')
    permanent_address = models.TextField(null=True, blank=True, help_text='Permanent address')
    
    profile_photo = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text='Profile photo URL or file path'
    )
    is_class_teacher = models.BooleanField(default=False, null=False, help_text='Whether the teacher is a class teacher')
    is_active = models.BooleanField(default=True, null=False, help_text='Active status')
    created_at = models.DateTimeField(auto_now_add=True, null=False)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id and school_name from department's school and sync profile_photo_id"""
        # Get school_id and school_name from department's school ForeignKey (same pattern as Student)
        # Try to access department.school - Django will lazy load if needed
        if self.department_id:
            try:
                # Access department - Django will lazy load if not already loaded
                department = self.department
                if department and hasattr(department, 'school'):
                    school = department.school
                    if school:
                        # Always update school_id if it's different
                        if not self.school_id or self.school_id != school.school_id:
                            self.school_id = school.school_id
                        # Always update school_name if it's different or missing (same pattern as Student.save)
                        if not self.school_name or self.school_name != school.school_name:
                            self.school_name = school.school_name
            except Exception:
                # If accessing department fails, skip - will be handled in views or serializer
                pass
        
        super().save(*args, **kwargs)
        
        # Update user's school_id if user is linked (signal will also handle this, but doing it here ensures it's immediate)
        if self.user:
            from main_login.utils import get_user_school_id
            school_id = get_user_school_id(self.user)
            if school_id and self.user.school_id != school_id:
                User.objects.filter(user_id=self.user.user_id).update(school_id=school_id)
    
    def __str__(self):
        name = f"{self.first_name} {self.last_name}".strip() or self.employee_no
        return f"{name} - {self.employee_no}"
    
    class Meta:
        db_table = 'teachers'
        verbose_name = 'Teacher'
        verbose_name_plural = 'Teachers'


class Student(models.Model):
    """Student (final admission) model — same fields as NewAdmission except status."""

    GENDER_CHOICES = [
        ('Male', 'Male'),
        ('Female', 'Female'),
        ('Other', 'Other'),
    ]

    CATEGORY_CHOICES = [
        ('General', 'General'),
        ('OBC', 'OBC'),
        ('SC', 'SC'),
        ('ST', 'ST'),
        ('EWS', 'EWS'),
        ('Other', 'Other'),
    ]

    # Email is now the primary key
    email = models.EmailField(
        primary_key=True,
        help_text='Primary key and used as login credential if account created'
    )

    # Student ID fetched from NewAdmission
    student_id = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="Student ID fetched from new_admissions table"
    )

    # Login reference (optional)
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='user_id',
        related_name='student_profiles',
        help_text='Linked login user account (if exists)'
    )

    # School link
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='students')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')

    # 🔥 SAME FIELDS AS NewAdmission (without status)
    student_name = models.CharField(max_length=255, default="")
    parent_name = models.CharField(max_length=255, default="")
    date_of_birth = models.DateField(default=date(2000, 1, 1))
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default="Male")
    applying_class = models.CharField(max_length=50, default="")
    section = models.CharField(max_length=50, null=True, blank=True, help_text="Section of the student")
    address = models.TextField(default="Address not provided")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default="General")
    

    admission_number = models.CharField(
        max_length=50, 
        unique=True, 
        null=True, 
        blank=True,
        help_text="Generated after approval"
    )

    parent_phone = models.CharField(max_length=20, null=True, blank=True)
    emergency_contact = models.CharField(max_length=20, null=True, blank=True)

    medical_information = models.TextField(
        null=True, 
        blank=True,
        help_text='Medical notes or allergies'
    )

    blood_group = models.CharField(max_length=10, null=True, blank=True)
    previous_school = models.CharField(max_length=255, null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    
    profile_photo = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text='Profile photo URL or file path'
    )
    activities = models.TextField(null=True, blank=True, help_text="Extracurricular activities")
    leadership = models.TextField(null=True, blank=True, help_text="Leadership roles")
    achievements = models.TextField(null=True, blank=True, help_text="Other achievements")
    participation = models.TextField(null=True, blank=True, help_text="Participation record")


    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate school_id and school_name from school ForeignKey"""
        # Auto-populate school_name from school ForeignKey
        if self.school:
            if not self.school_name or self.school_name != self.school.school_name:
                self.school_name = self.school.school_name
        
        super().save(*args, **kwargs)
        
        # Update user's school_id if user is linked (signal will also handle this, but doing it here ensures it's immediate)
        if self.user:
            from main_login.utils import get_user_school_id
            school_id = get_user_school_id(self.user)
            if school_id and self.user.school_id != school_id:
                User.objects.filter(user_id=self.user.user_id).update(school_id=school_id)

    def __str__(self):
        return f"{self.student_name} - {self.applying_class}"

    class Meta:
        db_table = 'students'
        verbose_name = 'Student'
        verbose_name_plural = 'Students'


class NewAdmission(models.Model):
    """New Admission model for managing student admissions - same fields as Student plus status"""
    STATUS_CHOICES = [
        ('Pending', 'Pending'),
        ('Approved', 'Approved'),
        ('Rejected', 'Rejected'),
        ('Under Review', 'Under Review'),
        ('Waitlisted', 'Waitlisted'),
        ('Enrolled', 'Enrolled'),
    ]
    
    GENDER_CHOICES = [
        ('Male', 'Male'),
        ('Female', 'Female'),
        ('Other', 'Other'),
    ]
    
    CATEGORY_CHOICES = [
        ('General', 'General'),
        ('OBC', 'OBC'),
        ('SC', 'SC'),
        ('ST', 'ST'),
        ('EWS', 'EWS'),
        ('Other', 'Other'),
    ]
    
    GRADE_CHOICES = [
        ('A', 'A'),
        ('B', 'B'),
        ('C', 'C'),
        ('D', 'D'),
    ]
    
    # Same fields as Student model
    student_name = models.CharField(max_length=255)
    parent_name = models.CharField(max_length=255)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    applying_class = models.CharField(max_length=50)
    section = models.CharField(max_length=1, choices=GRADE_CHOICES, null=True, blank=True, help_text="Section of the student (A, B, C, or D)")
    address = models.TextField(default="Address not provided")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='General')
    
    # Student ID field - Primary Key
    student_id = models.CharField(max_length=100, primary_key=True, help_text="Student ID (Primary Key)")
    
    # School ID for filtering (read-only, auto-populated)
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    
    # Status field - unique to NewAdmission (not in Student)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending')
    
    admission_number = models.CharField(
        max_length=50, 
        unique=True, 
        null=True, 
        blank=True,
        help_text="Generated after approval"
    )
    
    email = models.EmailField(
        unique=True,
        help_text='Required. Used to create login credentials.'
    )
    
    parent_phone = models.CharField(max_length=20, null=True, blank=True)
    emergency_contact = models.CharField(max_length=20, null=True, blank=True)
    
    medical_information = models.TextField(
        null=True, 
        blank=True,
        help_text='Medical information and allergies'
    )
    
    blood_group = models.CharField(max_length=10, null=True, blank=True)
    previous_school = models.CharField(max_length=255, null=True, blank=True)
    remarks = models.TextField(null=True, blank=True)
    
    # Password field - stores hashed password after user creates it
    password = models.CharField(max_length=128, null=True, blank=True, help_text='Hashed password created by user')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.student_name} - {self.applying_class} ({self.status})"
    
    @property
    def created_student(self):
        """
        Get the Student record created from this admission (if approved).
        Returns the Student instance if found, None otherwise.
        """
        if self.status != 'Approved':
            return None
        
        # Try to find student by admission number first, then by email
        if self.admission_number:
            try:
                return Student.objects.get(admission_number=self.admission_number)
            except Student.DoesNotExist:
                pass
        
        if self.email:
            try:
                return Student.objects.get(email=self.email)
            except Student.DoesNotExist:
                pass
        
        return None
    
    def create_student_from_admission(self):
        """
        Create a Student record from this approved NewAdmission.
        This method should be called when status changes to 'Approved'.
        Also creates a User account with credentials if it doesn't exist.
        Returns the created or updated Student instance.
        """
        from django.db import IntegrityError, transaction
        import datetime
        import random
        import string
        import logging
        from main_login.models import User, Role
        from super_admin.models import School
        
        logger = logging.getLogger(__name__)
        
        # Wrap everything in a transaction for atomicity
        with transaction.atomic():
            # Check if student already exists with this admission number or email
            existing_student = None
            if self.admission_number:
                existing_student = Student.objects.filter(admission_number=self.admission_number).first()
            if not existing_student and self.email:
                existing_student = Student.objects.filter(email=self.email).first()
            
            # Create or get user account for the student
            user = None
            if self.email:
                # Check if user already exists
                user = User.objects.filter(email=self.email).first()
                
                if not user:
                    # User doesn't exist, create it with credentials
                    try:
                        # Get or create student/parent role
                        role, _ = Role.objects.get_or_create(
                            name='student_parent',
                            defaults={'description': 'Student/Parent role'}
                        )
                        
                        # Generate unique username (optimized)
                        username = self.email.split("@")[0]
                        base_username = username
                        # Add random suffix upfront to reduce collisions
                        if User.objects.filter(username=username).exists():
                            random_suffix = random.randint(1000, 9999)
                            username = f'{base_username}{random_suffix}'
                            # Double check and add more random if still exists (rare)
                            if User.objects.filter(username=username).exists():
                                username = f'{base_username}_{random.randint(10000, 99999)}'
                        
                        # Generate 8-character password
                        characters = string.ascii_letters + string.digits
                        generated_password = ''.join(random.choice(characters) for _ in range(8))
                        
                        # Create user account
                        user = User.objects.create(
                            email=self.email,
                            username=username,
                            first_name=self.student_name,
                            role=role,
                            is_active=True,
                            has_custom_password=False
                        )
                        
                        # Set password_hash to the generated password
                        user.password_hash = generated_password
                        user.set_unusable_password()  # This sets password field to unusable
                        user.save()
                        
                    except IntegrityError as e:
                        # Handle race condition - user might have been created by another process
                        logger.warning(f"IntegrityError creating user during approval: {str(e)}")
                        # Try to get the user that was just created
                        user = User.objects.filter(email=self.email).first()
                        if not user:
                            raise  # Re-raise if we can't recover
            
            if existing_student:
                # Student already exists, update it with latest admission data
                for field in ['student_name', 'parent_name', 'date_of_birth', 'gender', 
                             'applying_class', 'section', 'address', 'category',
                             'parent_phone', 'emergency_contact', 'medical_information',
                             'blood_group', 'previous_school', 'remarks']:
                    if hasattr(self, field):
                        setattr(existing_student, field, getattr(self, field, None))
                
                # Update student_id from NewAdmission
                if self.student_id:
                    existing_student.student_id = self.student_id
                
                # Update admission number if not set
                if self.admission_number and not existing_student.admission_number:
                    existing_student.admission_number = self.admission_number
                
                # Link user to student if user exists and student doesn't have a user
                if user and not existing_student.user:
                    existing_student.user = user
                
                existing_student.save()
                
                # Create or update Parent record for existing student
                if user:
                    from student_parent.models import Parent
                    try:
                        parent = Parent.objects.get(user=user)
                    except Parent.DoesNotExist:
                        # Create parent first without accessing students
                        parent = Parent(
                            user=user,
                            phone=self.parent_phone or self.email or "N/A",
                            address=self.address or "Address not provided",
                        )
                        parent.save()  # Save first to get pk
                    
                    # Add the student to parent's students
                    if existing_student not in parent.students.all():
                        parent.students.add(existing_student)
                        parent.save()  # Save again to update school_id/school_name from student
                
                return existing_student
            
            # Generate admission number if not provided (optimized)
            admission_number = self.admission_number
            if not admission_number:
                now = datetime.datetime.now()
                # Use timestamp + random string for better uniqueness without many DB queries
                random_str = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
                admission_number = f'ADM-{now.year}-{now.strftime("%m%d%H%M%S")}{random_str}'
                
                # Quick check - if it exists, append more random chars (should be very rare)
                if Student.objects.filter(admission_number=admission_number).exists() or \
                   NewAdmission.objects.filter(admission_number=admission_number).exists():
                    admission_number = f'{admission_number}{random.randint(100,999)}'
                
                # Update the admission record with generated number
                self.admission_number = admission_number
                self.save(update_fields=['admission_number'])
            
            # Get school from NewAdmission's school_id if available
            school = None
            if self.school_id:
                try:
                    school = School.objects.get(school_id=self.school_id)
                except School.DoesNotExist:
                    logger.warning(f"School with ID {self.school_id} not found for admission {self.student_id}")
                    pass
            
            # If no school found, try to get default school
            if not school:
                school = School.objects.first()
                if not school:
                    logger.warning("No school found, creating default school")
                    # Create a default school if none exists
                    school = School.objects.create(
                        name='Default School',
                        location='Default Location',
                        status='active'
                    )
            
            student_data = {
            'school': school,
            'student_id': self.student_id,  # Fetch student_id from NewAdmission
            'student_name': self.student_name,
            'parent_name': self.parent_name,
            'date_of_birth': self.date_of_birth,
            'gender': self.gender,
            'applying_class': self.applying_class,
            'section': self.section if hasattr(self, 'section') else None,
            'address': self.address or "Address not provided",
            'category': self.category or "General",
            'admission_number': admission_number,
            'email': self.email,
            'parent_phone': self.parent_phone,
            'emergency_contact': self.emergency_contact,
            'medical_information': self.medical_information,
            'blood_group': self.blood_group,
            'previous_school': self.previous_school,
            'remarks': self.remarks,
                'user': user,  # Link the created user account to the student
            }
            
            try:
                # Create student
                student = Student.objects.create(**student_data)
                logger.info(f"Student created successfully: {student.student_id}")
                
                # Create Parent record for the same user (student and parent are the same user)
                if user:
                    from student_parent.models import Parent
                    # Check if parent already exists for this user
                    try:
                        parent = Parent.objects.get(user=user)
                    except Parent.DoesNotExist:
                        # Create parent first without accessing students
                        parent = Parent(
                            user=user,
                            phone=self.parent_phone or self.email or "N/A",
                            address=self.address or "Address not provided",
                        )
                        parent.save()  # Save first to get pk
                    
                    # Add the student to parent's students (ManyToMany relationship)
                    if student not in parent.students.all():
                        parent.students.add(student)
                        parent.save()  # Save again to update school_id/school_name from student
                    logger.info(f"Parent record linked to student: {student.student_id}")
                
                return student
            except IntegrityError as e:
                # Handle unique constraint violations (email or admission_number)
                logger.error(f"IntegrityError creating student: {str(e)}")
                # Try to get existing student by email or admission_number
                if self.email:
                    existing_student = Student.objects.filter(email=self.email).first()
                    if existing_student:
                        # Update the existing student
                        logger.info(f"Found existing student, updating: {existing_student.student_id}")
                        for key, value in student_data.items():
                            if key != 'email':  # Don't update email if it's the same
                                setattr(existing_student, key, value)
                        existing_student.save()
                        
                        # Create or update Parent record for existing student
                        if user:
                            from student_parent.models import Parent
                            parent, _ = Parent.objects.get_or_create(
                                user=user,
                                defaults={
                                    'phone': self.parent_phone or self.email or "N/A",
                                    'address': self.address or "Address not provided",
                                }
                            )
                            
                            # Add the student to parent's students if not already linked
                            if existing_student not in parent.students.all():
                                parent.students.add(existing_student)
                                parent.save()  # Save again to update school_id/school_name from student
                        
                        return existing_student
                
                # If we can't find existing student, re-raise the error
                logger.error(f"Could not recover from IntegrityError: {str(e)}")
                raise
    
    class Meta:
        db_table = 'new_admissions'
        verbose_name = 'New Admission'
        verbose_name_plural = 'New Admissions'
        ordering = ['-created_at']


class DashboardStats(models.Model):
    """Dashboard statistics for management admin"""
    school = models.OneToOneField(School, on_delete=models.CASCADE, related_name='dashboard_stats')
    total_teachers = models.IntegerField(default=0)
    total_students = models.IntegerField(default=0)
    total_departments = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'dashboard_stats'
        verbose_name = 'Dashboard Statistics'
        verbose_name_plural = 'Dashboard Statistics'

class Examination_management(models.Model):
    """Examination management model"""
    Exam_Title = models.CharField(max_length=255)
    Exam_Type = models.CharField(max_length=255)
    Exam_Date = models.DateTimeField()
    Exam_Time = models.TimeField()
    Exam_Subject = models.CharField(max_length=255, blank=True, default='')
    Exam_Class = models.CharField(max_length=255, blank=True, default='')
    Exam_Duration = models.IntegerField()
    Exam_Marks = models.IntegerField()
    Exam_Description = models.TextField(blank=True)
    Exam_Location = models.CharField(max_length=255)
    Exam_Status = models.CharField(max_length=255)
    Exam_Section = models.CharField(max_length=10, blank=True, default='ALL', help_text="Section: A, B, C, D, or ALL")
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    Exam_Created_At = models.DateTimeField(auto_now_add=True)
    Exam_Updated_At = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.Exam_Title} - {self.Exam_Type}"
    
    class Meta:
        db_table = 'examination_management'
        verbose_name = 'Examination Management'
        verbose_name_plural = 'Examination Management'
        ordering = ['-Exam_Created_At']


class Fee(models.Model):
    """Fee management model"""
    
    FEE_TYPE_CHOICES = [
        ('tuition', 'Tuition'),
        ('transport', 'Transport'),
        ('laboratory', 'Laboratory'),
        ('examination', 'Examination'),
        ('library', 'Library'),
        ('sports', 'Sports'),
        ('hostel', 'Hostel'),
        ('uniform', 'Uniform'),
        ('other', 'Other'),
    ]
    
    FREQUENCY_CHOICES = [
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('half-yearly', 'Half-Yearly'),
        ('yearly', 'Yearly'),
        ('one-time', 'One-Time'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('overdue', 'Overdue'),
    ]
    
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    # Note: Django automatically creates a 'student_id' field for the ForeignKey
    # We'll add a custom 'student_id_string' field to store the student ID as a string
    student_id_string = models.CharField(
        max_length=100,
        db_index=True,
        default='',
        blank=True,
        help_text='Student ID as string (e.g., STUD-005) - indexed for faster lookups'
    )
    student = models.ForeignKey(
        Student,
        on_delete=models.CASCADE,
        related_name='management_fees',
        help_text='Student associated with this fee'
    )
    student_name = models.CharField(max_length=255, blank=True, help_text='Student name (auto-populated from student)')
    applying_class = models.CharField(max_length=50, blank=True, help_text='Student class (auto-populated from student)')
    fee_type = models.CharField(max_length=50, choices=FEE_TYPE_CHOICES, default='tuition')
    section = models.CharField(max_length=50, help_text='Section of the student (A, B, C, D)')
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, help_text='Total amount of the fee')
    frequency = models.CharField(max_length=20, choices=FREQUENCY_CHOICES, default='monthly')
    due_date = models.DateField()
    late_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text='Late fee amount if payment is delayed')
    description = models.TextField(blank=True, help_text='Additional description for the fee')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    paid_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text='Total amount paid so far (sum of all payments)')
    due_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, help_text='Amount due (remaining to be paid)')
    last_paid_date = models.DateField(null=True, blank=True, help_text='Date of last payment')
    upload_receipt = models.CharField(max_length=100, blank=True, null=True, help_text='Uploaded receipt file path or URL')
    
    def save(self, *args, **kwargs):
        """Auto-calculate fields when saving"""
        # Auto-populate student_id_string from student if not set
        if self.student and not self.student_id_string:
            self.student_id_string = self.student.student_id or ''
        
        # Auto-populate student_name and applying_class from student if not set
        if self.student:
            if not self.student_name:
                self.student_name = self.student.student_name or ''
            if not self.applying_class:
                self.applying_class = self.student.applying_class or ''
            # Auto-populate section from student if not set
            if not self.section and hasattr(self.student, 'section') and self.student.section:
                self.section = self.student.section
            # Auto-populate school_id and school_name from student's school
            if self.student.school:
                if not self.school_id or self.school_id != self.student.school.school_id:
                    self.school_id = self.student.school.school_id
                if not self.school_name or self.school_name != self.student.school.school_name:
                    self.school_name = self.student.school.school_name
        
        # Calculate due_amount: total_amount - paid_amount (always recalculate)
        from decimal import Decimal
        self.due_amount = Decimal(str(self.total_amount)) - Decimal(str(self.paid_amount))
        
        # Update status based on payment
        if self.paid_amount >= self.total_amount:
            self.status = 'paid'
        elif self.paid_amount > 0:
            self.status = 'pending'
        else:
            self.status = 'pending'
        
        super().save(*args, **kwargs)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.student.student_name} - {self.get_fee_type_display()} - {self.total_amount}"
    
    class Meta:
        db_table = 'management_fees'
        verbose_name = 'Fee'
        verbose_name_plural = 'Fees'
        ordering = ['-due_date', '-created_at']
        # Note: student_id is the primary key, but a student can have multiple fees
        # Consider using a composite key (student_id, fee_type, due_date) if needed


class PaymentHistory(models.Model):
    """Model to track individual payment transactions for fees"""
    fee = models.ForeignKey(
        Fee,
        on_delete=models.CASCADE,
        related_name='payment_history',
        help_text='Fee associated with this payment'
    )
    payment_amount = models.DecimalField(max_digits=10, decimal_places=2, help_text='Amount paid in this transaction')
    payment_date = models.DateField(help_text='Date when payment was made')
    receipt_number = models.CharField(max_length=100, blank=True, help_text='Receipt number for this payment')
    upload_receipt = models.CharField(max_length=100, blank=True, null=True, help_text='Uploaded receipt file path or URL')
    notes = models.TextField(blank=True, help_text='Additional notes for this payment')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.fee.student_name} - ₹{self.payment_amount} on {self.payment_date}"
    
    class Meta:
        db_table = 'payment_history'
        verbose_name = 'Payment History'
        verbose_name_plural = 'Payment Histories'
        ordering = ['-payment_date', '-created_at']


class Bus(models.Model):
    """Bus model"""
    BUS_TYPE_CHOICES = [
        ('Mini Bus', 'Mini Bus'),
        ('Standard Bus', 'Standard Bus'),
        ('Large Bus', 'Large Bus'),
        ('AC Bus', 'AC Bus'),
    ]
    
    bus_number = models.CharField(max_length=100, primary_key=True, help_text='Unique bus number/identifier (Primary Key)')
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='buses')
    # Note: Django automatically creates 'school_id' field for ForeignKey which can be used for filtering
    bus_type = models.CharField(max_length=50, choices=BUS_TYPE_CHOICES, help_text='Type of bus')
    capacity = models.IntegerField(validators=[MinValueValidator(1)], help_text='Passenger capacity of the bus')
    registration_number = models.CharField(max_length=100, unique=True, help_text='Vehicle registration number')
    driver_name = models.CharField(max_length=255, help_text='Full name of the driver')
    driver_email = models.EmailField(max_length=254, blank=True, help_text='Driver login email; credentials created so driver can log in and see this bus')
    driver_phone = models.CharField(max_length=20, help_text='Driver contact phone number')
    driver_license = models.CharField(max_length=100, help_text='Driver license number')
    driver_experience = models.IntegerField(blank=True, null=True, validators=[MinValueValidator(0)], help_text='Years of driving experience')
    route_name = models.CharField(max_length=255, help_text='Name of the bus route')
    route_distance = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True, validators=[MinValueValidator(0)], help_text='Route distance in kilometers')
    start_location = models.CharField(max_length=255, blank=True, help_text='Starting location of the route')
    end_location = models.CharField(max_length=255, blank=True, help_text='Ending location of the route')
    morning_start_time = models.TimeField(help_text='Morning pickup start time')
    morning_end_time = models.TimeField(help_text='Morning pickup end time')
    afternoon_start_time = models.TimeField(help_text='Afternoon drop-off start time')
    afternoon_end_time = models.TimeField(help_text='Afternoon drop-off end time')
    notes = models.TextField(blank=True, help_text='Additional notes or comments about the bus')
    is_active = models.BooleanField(default=True, help_text='Whether the bus is currently active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Save method for Bus model"""
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.bus_number}"
    
    class Meta:
        db_table = 'buses'
        verbose_name = 'Bus'
        verbose_name_plural = 'Buses'


class BusStop(models.Model):
    """Bus Stop model"""
    stop_id = models.CharField(max_length=255, primary_key=True, editable=False, help_text='Stop ID in format: busnumber_routeprefix_stopnumber')
    bus = models.ForeignKey(Bus, on_delete=models.CASCADE, related_name='stops', db_column='bus_number')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    stop_name = models.CharField(max_length=255, help_text='Name of the bus stop')
    stop_address = models.TextField(blank=True, help_text='Address of the bus stop')
    notes = models.TextField(blank=True, help_text='Driver notes for this stop (e.g. gate code, landmarks)')
    stop_time = models.TimeField(blank=True, null=True, help_text='Time when bus arrives at this stop')
    route_type = models.CharField(
        max_length=20,
        choices=[('morning', 'Morning Route (Pick-up)'), ('afternoon', 'Afternoon Route (Drop-off)')],
        help_text='Type of route: morning (pick-up) or afternoon (drop-off)'
    )
    stop_order = models.IntegerField(validators=[MinValueValidator(1)], help_text='Order of stop in the route (1, 2, 3, ...)')
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, help_text='Latitude coordinate')
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, help_text='Longitude coordinate')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-generate stop_id and populate school_id from bus's school"""
        # Generate stop_id in format: busnumber_routeprefix_stopnumber (e.g., BUS001_mor_1)
        if not self.stop_id and self.bus and self.stop_order and self.route_type:
            route_prefix = self.route_type[:3] if len(self.route_type) >= 3 else self.route_type
            self.stop_id = f"{self.bus.bus_number}_{route_prefix}_{self.stop_order}"
        
        # Auto-populate school_id and school_name from bus's school
        if self.bus and self.bus.school:
            if not self.school_id or self.school_id != self.bus.school.school_id:
                self.school_id = self.bus.school.school_id
            if not self.school_name or self.school_name != self.bus.school.school_name:
                self.school_name = self.bus.school.school_name
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.stop_name} - {self.get_route_type_display()}"
    
    class Meta:
        db_table = 'bus_stops'
        verbose_name = 'Bus Stop'
        verbose_name_plural = 'Bus Stops'
        ordering = ['bus', 'route_type', 'stop_order']
        unique_together = ['bus', 'route_type', 'stop_order']


class BusStopStudent(models.Model):
    """Bus Stop Student model - links students to bus stops"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    bus_stop = models.ForeignKey(BusStop, on_delete=models.CASCADE, related_name='stop_students', db_column='stop_id')
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='bus_stops')
    school_id = models.CharField(max_length=100, db_index=True, null=True, blank=True, editable=False, help_text='School ID for filtering (read-only, fetched from schools table)')
    school_name = models.CharField(max_length=255, null=True, blank=True, editable=False, help_text='School name (read-only, auto-populated from schools table)')
    student_id_string = models.CharField(max_length=100, blank=True, help_text='Student ID as string (cached from student table)')
    student_name = models.CharField(max_length=255, blank=True, help_text='Student name (cached from student table)')
    student_class = models.CharField(max_length=50, blank=True, help_text='Student class (cached from student table)')
    student_section = models.CharField(max_length=50, blank=True, help_text='Student section (cached from student table)')
    pickup_time = models.TimeField(null=True, blank=True, help_text='Pickup time for this student at this stop')
    dropoff_time = models.TimeField(null=True, blank=True, help_text='Dropoff time for this student at this stop')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        """Auto-populate fields from student and bus_stop"""
        if self.student:
            if not self.student_id_string:
                self.student_id_string = self.student.student_id or ''
            if not self.student_name:
                self.student_name = self.student.student_name or ''
            if not self.student_class:
                self.student_class = self.student.applying_class or ''
            if not self.student_section:
                self.student_section = self.student.section or ''
            
            # Get school_id and school_name from student's school
            if self.student.school:
                if not self.school_id or self.school_id != self.student.school.school_id:
                    self.school_id = self.student.school.school_id
                if not self.school_name or self.school_name != self.student.school.school_name:
                    self.school_name = self.student.school.school_name
        elif self.bus_stop and self.bus_stop.bus and self.bus_stop.bus.school:
            # Fallback to bus's school
            if not self.school_id or self.school_id != self.bus_stop.bus.school.school_id:
                self.school_id = self.bus_stop.bus.school.school_id
            if not self.school_name or self.school_name != self.bus_stop.bus.school.school_name:
                self.school_name = self.bus_stop.bus.school.school_name
        
        # Auto-set pickup_time and dropoff_time from stop times so they always match bus creation/update
        if self.bus_stop and self.bus_stop.stop_time:
            if self.bus_stop.route_type == 'morning':
                # Morning stop: pickup = this stop's time, dropoff = corresponding afternoon stop's time
                self.pickup_time = self.bus_stop.stop_time
                try:
                    corresponding_afternoon_stop = BusStop.objects.filter(
                        bus=self.bus_stop.bus,
                        route_type='afternoon',
                        stop_name=self.bus_stop.stop_name
                    ).first()
                    if corresponding_afternoon_stop and corresponding_afternoon_stop.stop_time:
                        self.dropoff_time = corresponding_afternoon_stop.stop_time
                    # Sync the corresponding afternoon assignment (use update to avoid recursive save)
                    if corresponding_afternoon_stop:
                        from django.utils import timezone
                        dropoff = corresponding_afternoon_stop.stop_time
                        BusStopStudent.objects.filter(
                            bus_stop=corresponding_afternoon_stop,
                            student=self.student
                        ).update(
                            pickup_time=self.bus_stop.stop_time,
                            dropoff_time=dropoff,
                            updated_at=timezone.now(),
                        )
                except Exception:
                    pass
            elif self.bus_stop.route_type == 'afternoon':
                # Afternoon stop: dropoff = this stop's time, pickup = corresponding morning stop's time
                self.dropoff_time = self.bus_stop.stop_time
                try:
                    corresponding_morning_stop = BusStop.objects.filter(
                        bus=self.bus_stop.bus,
                        route_type='morning',
                        stop_name=self.bus_stop.stop_name
                    ).first()
                    if corresponding_morning_stop and corresponding_morning_stop.stop_time:
                        self.pickup_time = corresponding_morning_stop.stop_time
                    # Sync the corresponding morning assignment (use update to avoid recursive save)
                    if corresponding_morning_stop:
                        from django.utils import timezone
                        BusStopStudent.objects.filter(
                            bus_stop=corresponding_morning_stop,
                            student=self.student
                        ).update(
                            pickup_time=corresponding_morning_stop.stop_time,
                            dropoff_time=self.bus_stop.stop_time,
                            updated_at=timezone.now(),
                        )
                except Exception:
                    pass
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.student_name} - {self.bus_stop.stop_name}"
    
    class Meta:
        db_table = 'bus_stop_students'
        verbose_name = 'Bus Stop Student'
        verbose_name_plural = 'Bus Stop Students'
        ordering = ['bus_stop', 'student_name']
        unique_together = ['bus_stop', 'student']


class BusStopAttendance(models.Model):
    """Driver-recorded attendance (present/absent) per student per stop per date."""
    STATUS_CHOICES = [
        ('present', 'Present'),
        ('absent', 'Absent'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    bus_stop_student = models.ForeignKey(
        BusStopStudent,
        on_delete=models.CASCADE,
        related_name='attendance_records',
        help_text='Bus stop student assignment'
    )
    attendance_date = models.DateField(help_text='Date of attendance')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='present')
    # Denormalized from bus_stop_student for reporting/filtering
    student_name = models.CharField(max_length=255, blank=True, help_text='Student name (from bus stop student)')
    student_id = models.CharField(max_length=100, blank=True, db_index=True, help_text='Student ID (from bus stop student)')
    school_id = models.CharField(max_length=100, blank=True, null=True, db_index=True, help_text='School ID (from bus stop student)')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        """Auto-populate student_name, student_id, school_id from bus_stop_student."""
        if self.bus_stop_student_id:
            bss = self.bus_stop_student
            if not self.student_name:
                self.student_name = bss.student_name or (bss.student.student_name if bss.student_id else '') or ''
            if not self.student_id:
                self.student_id = bss.student_id_string or (bss.student.student_id if bss.student_id else '') or ''
            if self.school_id is None or self.school_id == '':
                self.school_id = bss.school_id or ''
        super().save(*args, **kwargs)

    class Meta:
        db_table = 'bus_stop_attendance'
        verbose_name = 'Bus Stop Attendance'
        verbose_name_plural = 'Bus Stop Attendances'
        ordering = ['attendance_date', 'bus_stop_student']
        unique_together = ['bus_stop_student', 'attendance_date']


class Driver(models.Model):
    """Links a User (with driver role) to an assigned Bus. One driver per bus."""
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='driver_profile',
        primary_key=True,
        help_text='User account with driver role'
    )
    bus = models.ForeignKey(
        Bus,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_driver',
        db_column='bus_number',
        help_text='Assigned bus (null if not yet assigned)'
    )
    employee_id = models.CharField(max_length=100, blank=True, help_text='Driver employee ID')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'drivers'
        verbose_name = 'Driver'
        verbose_name_plural = 'Drivers'

    def __str__(self):
        return f"Driver({self.user.email})"


class Event(models.Model):
    """Event model for managing school events"""
    
    CATEGORY_CHOICES = [
        ('Academic', 'Academic'),
        ('Sports', 'Sports'),
        ('Cultural', 'Cultural'),
        ('Administrative', 'Administrative'),
        ('Career', 'Career'),
        ('Other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('Upcoming', 'Upcoming'),
        ('Completed', 'Completed'),
        ('Cancelled', 'Cancelled'),
        ('Postponed', 'Postponed'),
    ]
    
    school_id = models.CharField(
        max_length=100, 
        db_index=True, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School ID for filtering (read-only, fetched from schools table)'
    )
    school_name = models.CharField(
        max_length=255, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School name (read-only, auto-populated from schools table)'
    )
    name = models.CharField(max_length=255, help_text='Event name')
    category = models.CharField(
        max_length=50, 
        choices=CATEGORY_CHOICES, 
        default='Other',
        help_text='Event category'
    )
    start_datetime = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Event start date and time'
    )
    end_datetime = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Event end date and time'
    )
    location = models.CharField(max_length=255, blank=True, help_text='Event location')
    organizer = models.CharField(max_length=255, blank=True, help_text='Event organizer')
    participants = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0)],
        help_text='Estimated number of participants'
    )
    status = models.CharField(
        max_length=50, 
        choices=STATUS_CHOICES, 
        default='Upcoming',
        help_text='Event status'
    )
    description = models.TextField(blank=True, help_text='Event description')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.name}"
    
    @property
    def computed_status(self):
        """Automatically compute event status based on current time and datetime fields"""
        from django.utils import timezone
        now = timezone.now()
        
        # If no datetime fields are set, return the manual status
        if not self.start_datetime and not self.end_datetime:
            return self.status
        
        # If only start_datetime is set
        if self.start_datetime and not self.end_datetime:
            if now < self.start_datetime:
                return 'Upcoming'
            else:
                return 'Ongoing'
        
        # If only end_datetime is set
        if not self.start_datetime and self.end_datetime:
            if now < self.end_datetime:
                return 'Upcoming'
            else:
                return 'Completed'
        
        # If both are set
        if self.start_datetime and self.end_datetime:
            if now < self.start_datetime:
                return 'Upcoming'
            elif self.start_datetime <= now < self.end_datetime:
                return 'Ongoing'
            else:
                return 'Completed'
        
        return self.status
    
    class Meta:
        db_table = 'events'
        verbose_name = 'Event'
        verbose_name_plural = 'Events'
        ordering = ['-start_datetime', '-created_at']


class Award(models.Model):
    """Award model for managing school achievements and recognitions"""
    
    LEVEL_CHOICES = [
        ('School', 'School'),
        ('District', 'District'),
        ('State', 'State'),
        ('National', 'National'),
        ('International', 'International'),
    ]
    
    CATEGORY_CHOICES = [
        ('Academic', 'Academic'),
        ('Sports', 'Sports'),
        ('Arts', 'Arts'),
        ('Leadership', 'Leadership'),
        ('Innovation', 'Innovation'),
        ('Community', 'Community'),
        ('Science Fair', 'Science Fair'),
        ('NSS', 'NSS'),
        ('NCC', 'NCC'),
        ('Other', 'Other'),
    ]
    
    school_id = models.CharField(
        max_length=100, 
        db_index=True, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School ID for filtering'
    )
    school_name = models.CharField(
        max_length=255, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School name'
    )
    
    title = models.CharField(max_length=255, help_text='Award title')
    category = models.CharField(
        max_length=50, 
        choices=CATEGORY_CHOICES, 
        default='Other',
        help_text='Award category'
    )
    recipient = models.CharField(max_length=255, help_text='Recipient name')
    student_ids = models.TextField(
        blank=True, 
        help_text='Comma-separated student IDs (for team awards)'
    )
    date = models.DateField(help_text='Award date')
    description = models.TextField(blank=True, help_text='Award description')
    level = models.CharField(
        max_length=50, 
        choices=LEVEL_CHOICES, 
        default='School',
        help_text='Award level'
    )
    presented_by = models.CharField(
        max_length=255, 
        blank=True, 
        help_text='Presented by (organization or person)'
    )
    document = models.FileField(
        upload_to='awards/certificates/', 
        blank=True, 
        null=True, 
        help_text='Direct award document/certificate (legacy or single)'
    )
    team_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Import-time grouping ID'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} - {self.recipient}"
    
    class Meta:
        db_table = 'awards'
        verbose_name = 'Award'
        verbose_name_plural = 'Awards'
        ordering = ['-date', '-created_at']


class AwardCertificate(models.Model):
    """Specific certificate for a student in a team or single award"""
    award = models.ForeignKey(
        Award,
        on_delete=models.CASCADE,
        related_name='certificates',
        help_text='Parent award'
    )
    document = models.FileField(
        upload_to='awards/certificates/',
        help_text='Certificate image/document'
    )
    student_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text='Student ID this certificate belongs to'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'award_certificates'
        verbose_name = 'Award Certificate'
        verbose_name_plural = 'Award Certificates'


class Activity(models.Model):
    """Activity Model"""
    CATEGORY_CHOICES = [
        ('Sports', 'Sports'),
        ('Academic', 'Academic'),
        ('Arts', 'Arts'),
        ('Games', 'Games'),
        ('Cultural', 'Cultural'),
        ('Technical', 'Technical'),
    ]

    STATUS_CHOICES = [
        ('Active', 'Active'),
        ('Inactive', 'Inactive'),
        ('Suspended', 'Suspended'),
        ('Completed', 'Completed'),
    ]

    id = models.AutoField(primary_key=True)
    school = models.ForeignKey(
        School,
        on_delete=models.CASCADE,
        related_name='school_activities',
        db_column='school_id'
    )
    school_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        editable=False,
        help_text='School name (read-only, auto-populated from schools table)'
    )
    name = models.CharField(max_length=255, help_text='Activity name')
    category = models.CharField(
        max_length=50,
        choices=CATEGORY_CHOICES,
        help_text='Activity category'
    )
    instructor = models.CharField(max_length=255, help_text='Instructor name')
    max_participants = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1)],
        help_text='Maximum number of participants'
    )
    schedule = models.CharField(
        max_length=255,
        help_text='Activity schedule (e.g., Monday, Wednesday 3:00 PM)'
    )
    location = models.CharField(max_length=255, help_text='Activity location')
    status = models.CharField(
        max_length=50,
        choices=STATUS_CHOICES,
        default='Active',
        help_text='Activity status'
    )
    start_date = models.DateField(null=True, blank=True, help_text='Activity start date')
    end_date = models.DateField(null=True, blank=True, help_text='Activity end date')
    description = models.TextField(help_text='Detailed activity description')
    requirements = models.TextField(blank=True, help_text='Requirements or prerequisites')
    notes = models.TextField(blank=True, help_text='Additional notes or comments')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if self.school and not self.school_name:
            self.school_name = self.school.school_name
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.category}"

    class Meta:
        db_table = 'school_activities'
        verbose_name = 'School Activity'
        verbose_name_plural = 'School Activities'
        ordering = ['-created_at']


class Gallery(models.Model):
    """Gallery model for photo albums/events"""
    
    CATEGORY_CHOICES = [
        ('Sports', 'Sports'),
        ('Academic', 'Academic'),
        ('Cultural', 'Cultural'),
        ('Awards', 'Awards'),
        ('Activities', 'Activities'),
        ('Other', 'Other'),
    ]

    school_id = models.CharField(
        max_length=100, 
        db_index=True, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School ID for filtering'
    )
    school_name = models.CharField(
        max_length=255, 
        null=True, 
        blank=True, 
        editable=False, 
        help_text='School name'
    )
    
    photo_id = models.CharField(max_length=100, blank=True, help_text='Gallery Photo ID (e.g., PID-123)')
    title = models.CharField(max_length=255, help_text='Gallery title')
    category = models.CharField(
        max_length=50, 
        choices=CATEGORY_CHOICES, 
        default='Other',
        help_text='Event category'
    )
    description = models.TextField(blank=True, help_text='Description')
    date = models.DateField(help_text='Event date')
    photographer = models.CharField(max_length=255, blank=True, help_text='Photographer name')
    location = models.CharField(max_length=255, blank=True, help_text='Location')
    emoji = models.CharField(max_length=10, blank=True, default='📷', help_text='Emoji icon')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} - {self.date}"
    
    class Meta:
        db_table = 'gallery'
        verbose_name = 'Gallery'
        verbose_name_plural = 'Galleries'
        ordering = ['-date', '-created_at']


class GalleryImage(models.Model):
    """Images for a gallery event"""
    gallery = models.ForeignKey(
        Gallery, 
        on_delete=models.CASCADE, 
        related_name='images',
        help_text='Parent gallery'
    )
    image = models.FileField(
        upload_to='gallery_photos/',
        validators=[
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'gif'])
        ],
        help_text='Gallery image (jpg/jpeg/png/gif only)'
    )
    alt_text = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'gallery_images'
        verbose_name = 'Gallery Image'
        verbose_name_plural = 'Gallery Images'


class PushNotificationLog(models.Model):
    """Log of push notifications sent from management to students/teachers."""
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True)
    audience = models.CharField(max_length=32)  # all_students, all_teachers, both
    sent_count = models.PositiveIntegerField(default=0)
    user_count = models.PositiveIntegerField(default=0)
    school_id = models.CharField(max_length=100, db_index=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='sent_push_notifications'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'push_notification_logs'
        verbose_name = 'Push Notification Log'
        verbose_name_plural = 'Push Notification Logs'
        ordering = ['-created_at']
