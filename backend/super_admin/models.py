"""
Models for super_admin app - API layer for App 1
"""
import uuid
from django.db import models
from main_login.models import User
from PIL import Image
import io
from django.core.files.base import ContentFile
import os


class School(models.Model):
    """School model for super admin"""
    school_id = models.CharField(max_length=200, primary_key=True, editable=False, help_text='Auto-generated school identifier (Primary Key) - Format: StateCode + DistrictCode + RegistrationNumber')
    school_name = models.CharField(max_length=255)
    location = models.CharField(max_length=255)
    # Fields for auto-generating school_id
    statecode = models.CharField(max_length=100, help_text='State code (e.g., TG) - used for school_id generation')
    districtcode = models.CharField(max_length=100, help_text='District code (e.g., HYD) - used for school_id generation')
    registration_number = models.CharField(max_length=100, unique=True, help_text='School registration number - used for school_id generation')
    email = models.EmailField(unique=True, null=True, blank=True, help_text='School email address - used for login credentials')
    phone = models.CharField(max_length=20, null=True, blank=True, help_text='School contact phone number')
    address = models.TextField(null=True, blank=True, help_text='Full address of the school')
    principal_name = models.CharField(max_length=255, null=True, blank=True, help_text='Name of the principal')
    established_year = models.IntegerField(null=True, blank=True, help_text='Year the school was established')
    status = models.CharField(
        max_length=20,
        choices=[
            ('active', 'Active'),
            ('inactive', 'Inactive'),
            ('suspended', 'Suspended'),
        ],
        default='active'
    )
    license_expiry = models.DateField(null=True, blank=True)
    logo = models.FileField(upload_to='school_logos/', null=True, blank=True, help_text='School logo image')
    # Link to user account created for this school
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='school_account',
        help_text='User account created for this school (for login)'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_school_id(self):
        """Generate school_id from statecode, districtcode, and registration_number"""
        # Normalize the values: remove spaces, convert to uppercase
        state_normalized = (self.statecode or '').strip().upper().replace(' ', '')
        district_normalized = (self.districtcode or '').strip().upper().replace(' ', '')
        reg_normalized = (self.registration_number or '').strip().upper().replace(' ', '')
        
        # Generate school_id in format: StateCode + DistrictCode + RegistrationNumber
        school_id = f"{state_normalized}{district_normalized}{reg_normalized}"
        return school_id
    
    def save(self, *args, **kwargs):
        """Override save to auto-generate school_id"""
        # Only generate school_id for new instances (when pk is None or not in database)
        if not self.pk or self._state.adding:
            # Strip whitespace and check if fields are not empty
            statecode = (self.statecode or '').strip()
            districtcode = (self.districtcode or '').strip()
            registration_number = (self.registration_number or '').strip()
            
            if not statecode or not districtcode or not registration_number:
                raise ValueError("statecode, districtcode, and registration_number are required to generate school_id. Received: statecode='{}', districtcode='{}', registration_number='{}'".format(
                    statecode, districtcode, registration_number
                ))
            
            # Ensure the stripped values are set back
            self.statecode = statecode
            self.districtcode = districtcode
            self.registration_number = registration_number
            
            # Generate school_id if not already set
            if not self.school_id:
                self.school_id = self.generate_school_id()
        else:
            # For existing instances, prevent changes to statecode/districtcode/registration_number
            # that would change school_id (to maintain referential integrity)
            if self.pk:
                old_instance = School.objects.get(pk=self.pk)
                if (old_instance.statecode != self.statecode or 
                    old_instance.districtcode != self.districtcode or 
                    old_instance.registration_number != self.registration_number):
                    raise ValueError("Cannot change statecode, districtcode, or registration_number after school creation. This would change the school_id and break data relationships.")
        
        # Image Resizing Logic
        if self.logo:
            try:
                # Open image using Pillow
                img = Image.open(self.logo)
                
                # Convert to RGB if necessary (e.g. for PNGs with transparency)
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                
                # Check if image needs resizing (e.g. max width 800px)
                max_width = 800
                if img.width > max_width:
                    # Calculate new height to maintain aspect ratio
                    ratio = max_width / float(img.width)
                    new_height = int((float(img.height) * float(ratio)))
                    img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                    
                    # Save resized image to BytesIO object
                    img_io = io.BytesIO()
                    img.save(img_io, format='JPEG', quality=85)
                    
                    # Create a new Django ContentFile
                    new_image = ContentFile(img_io.getvalue())
                    
                    # Update the file field
                    # Use original filename but ensure .jpg extension
                    original_name = os.path.basename(self.logo.name)
                    name_base, _ = os.path.splitext(original_name)
                    new_filename = f"{name_base}.jpg"
                    
                    self.logo.save(new_filename, new_image, save=False)
            except Exception as e:
                # Log error but don't stop save? Or print for now.
                print(f"Error resizing image: {e}")

        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.school_name
    
    class Meta:
        db_table = 'schools'
        verbose_name = 'School'
        verbose_name_plural = 'Schools'
        ordering = ['-created_at']


class SchoolStats(models.Model):
    """School statistics"""
    school = models.OneToOneField(School, on_delete=models.CASCADE, related_name='stats')
    # Note: Django automatically creates 'school_id' field for ForeignKey/OneToOneField
    # Since School's primary key is 'school_id', this will contain the school's school_id value
    total_students = models.IntegerField(default=0)
    total_teachers = models.IntegerField(default=0)
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'school_stats'
        verbose_name = 'School Statistics'
        verbose_name_plural = 'School Statistics'


class Activity(models.Model):
    """Activity log for super admin"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    school = models.ForeignKey(School, on_delete=models.CASCADE, null=False, blank=False)
    # Note: Django automatically creates 'school_id' field for ForeignKey
    # Since School's primary key is 'school_id', this will contain the school's school_id value
    # school_id is now required for data isolation
    activity_type = models.CharField(max_length=100)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'activities'
        verbose_name = 'Activity'
        verbose_name_plural = 'Activities'
        ordering = ['-created_at']


class SupportTicket(models.Model):
    """Model for support tickets raised by schools"""
    STATUS_CHOICES = [
        ('new', 'New 🔴'),
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
    ]
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]

    ticket_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='support_tickets')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='raised_tickets', null=True, blank=True)
    user_role = models.CharField(max_length=100, default='Management')
    category = models.CharField(max_length=200)
    description = models.TextField()
    attachment = models.ImageField(upload_to='support_attachments/', null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'support_tickets'
        verbose_name = 'Support Ticket'
        verbose_name_plural = 'Support Tickets'
        ordering = ['-created_at']

    def __str__(self):
        return f"Ticket {self.ticket_id} - {self.school.school_name}"


class TicketReply(models.Model):
    """Model for replies to support tickets"""
    SENDER_ROLE_CHOICES = [
        ('Management', 'Management'),
        ('SuperAdmin', 'SuperAdmin'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='replies')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ticket_replies')
    sender_role = models.CharField(max_length=20, choices=SENDER_ROLE_CHOICES)
    message = models.TextField()
    attachment = models.ImageField(upload_to='support_attachments/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'support_ticket_replies'
        verbose_name = 'Ticket Reply'
        verbose_name_plural = 'Ticket Replies'
        ordering = ['created_at'] # Chronological order

    def __str__(self):
        return f"Reply from {self.sender_role} on Ticket {self.ticket.ticket_id}"


class TicketAttachment(models.Model):
    """Model for multiple attachments to support tickets"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='support_attachments/')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'support_ticket_attachments'
        verbose_name = 'Ticket Attachment'
        verbose_name_plural = 'Ticket Attachments'
        ordering = ['created_at']

    def __str__(self):
        return f"Attachment {self.id} for Ticket {self.ticket.ticket_id}"
