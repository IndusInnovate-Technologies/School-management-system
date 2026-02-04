"""
Serializers for management_admin app
"""
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from django.utils import timezone
from .models import File, Department, Teacher, Student, DashboardStats, NewAdmission, Examination_management, Fee, PaymentHistory, Bus, BusStop, BusStopStudent, BusStopAttendance, Event, Award, AwardCertificate, CampusFeature, Activity, Gallery, GalleryImage, PushNotificationLog

from main_login.serializers import UserSerializer
from main_login.serializer_mixins import SchoolIdMixin
from main_login.utils import get_user_school_id
from super_admin.serializers import SchoolSerializer
from super_admin.models import School





class AwardCertificateSerializer(serializers.ModelSerializer):
    """Serializer for AwardCertificate model"""
    document_url = serializers.SerializerMethodField()
    
    class Meta:
        model = AwardCertificate
        fields = ['id', 'document', 'document_url', 'student_id', 'created_at']
        read_only_fields = ['id', 'created_at']

    def get_document_url(self, obj):
        if obj.document:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.document.url)
            return obj.document.url
        return None


class FileSerializer(serializers.ModelSerializer):
    """Serializer for File model"""
    file_url = serializers.SerializerMethodField()
    
    class Meta:
        model = File
        fields = [
            'file_id', 'file', 'file_url', 'file_name', 'file_type', 'file_size',
            'school_id', 'uploaded_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['file_id', 'school_id', 'created_at', 'updated_at']
    
    def get_file_url(self, obj):
        """Get the URL to access the file"""
        if obj.file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.file.url)
            return obj.file.url
        return None


class DepartmentSerializer(serializers.ModelSerializer):
    """Serializer for Department model"""
    head = UserSerializer(read_only=True)
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    school_id = serializers.CharField(source='school.school_id', read_only=True, help_text='School ID (read-only)')
    
    class Meta:
        model = Department
        fields = [
            'id', 'school', 'school_id', 'school_name', 'name', 'description',
            'head', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school_id', 'created_at', 'updated_at']



class TeacherSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Teacher model"""
    user = UserSerializer(read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    department = serializers.CharField(
        required=False,
        allow_null=True,
        help_text='Department Name (string)'
    )
    # Forced reload comment to ensure changes are picked up
    profile_photo_url = serializers.SerializerMethodField()
    
    # Make employee_no required but allow auto-generation if not provided
    employee_no = serializers.CharField(max_length=50, required=False, help_text='Employee number (auto-generated if not provided)')
    
    # First and last name fields - read-write so they appear in responses
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    
    class Meta:
        model = Teacher
        fields = [
            'employee_no', 'school_id', 'school_name', 'user', 'department', 'department_name',
            'first_name', 'last_name', 'qualification',
            'joining_date', 'dob', 'gender',
            'blood_group', 'nationality', 'mobile_no', 'email', 'address',
            'class_teacher_class', 'class_teacher_section', 'subject_specialization',
            'emergency_contact', 'emergency_contact_relation', 'experience', 'salary',
            'marital_status', 'permanent_address',
            'profile_photo', 'profile_photo_url',
            'is_class_teacher', 'is_active',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at', 'user', 'profile_photo_url']
    
    def get_profile_photo_url(self, obj):
        if obj.profile_photo:
            request = self.context.get('request')
            if request:
                # If it's already a full URL, return it
                if obj.profile_photo.startswith('http://') or obj.profile_photo.startswith('https://'):
                    return obj.profile_photo
                # If it starts with /media/, it's a media file URL - build absolute URI
                if obj.profile_photo.startswith('/media/'):
                    return request.build_absolute_uri(obj.profile_photo)
                # If it doesn't start with /, add /media/ prefix (for relative paths like 'profile_photos/...')
                if not obj.profile_photo.startswith('/'):
                    media_path = f'/media/{obj.profile_photo}'
                    return request.build_absolute_uri(media_path)
                # For other absolute paths, build absolute URI
                return request.build_absolute_uri(obj.profile_photo)
            # If no request context, return as-is (may be used in management commands)
            return obj.profile_photo
        return None
    
    def _handle_department(self, validated_data):
        """
        Helper to find or create department from string name in validated_data.
        Returns the Department instance or None.
        """
        department_input = validated_data.get('department')
        
        # If department is not in validated_data or is None, do nothing
        if 'department' not in validated_data:
            return None
            
        # Remove raw string from validated_data so it doesn't cause issues
        department_name = validated_data.pop('department')
        
        if not department_name or not isinstance(department_name, str):
            return None
            
        request = self.context.get('request')
        if not request or not request.user:
            return None
            
        school_id = get_user_school_id(request.user)
        if not school_id:
            return None
            
        try:
            school = School.objects.get(school_id=school_id)
            # Find or create department
            department, _ = Department.objects.get_or_create(
                school=school,
                name=department_name.strip(),
                defaults={'description': f'Department of {department_name}'}
            )
            return department
        except Exception:
            return None

    def create(self, validated_data):
        import random
        import string
        from django.utils import timezone
        
        first_name = validated_data.get('first_name', '')
        last_name = validated_data.get('last_name', '')
        email = validated_data.get('email', '')
        
        # Auto-generate employee_no if not provided
        employee_no = validated_data.get('employee_no')
        if not employee_no or employee_no.strip() == '':
            # Generate unique employee number: EMP + timestamp + random suffix
            timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
            random_suffix = ''.join(random.choices(string.digits, k=4))
            employee_no = f'EMP{timestamp}{random_suffix}'
            
            # Ensure uniqueness
            while Teacher.objects.filter(employee_no=employee_no).exists():
                random_suffix = ''.join(random.choices(string.digits, k=4))
                employee_no = f'EMP{timestamp}{random_suffix}'
            
            validated_data['employee_no'] = employee_no
        else:
            # Ensure uniqueness of provided employee_no
            employee_no = employee_no.strip().upper()
            if Teacher.objects.filter(employee_no=employee_no).exists():
                raise serializers.ValidationError({'employee_no': f'Employee number {employee_no} already exists.'})
            validated_data['employee_no'] = employee_no
        
        # Create user account for the teacher if email is provided
        user = None
        if email:
            from django.db import IntegrityError, transaction
            from main_login.models import User, Role
            import logging
            
            logger = logging.getLogger(__name__)
            
            # Check if user already exists with this email
            user = User.objects.filter(email=email).first()
            
            if not user:
                # User doesn't exist, create it with credentials
                try:
                    with transaction.atomic():
                        # Get or create teacher role (role_id should be 3)
                        role, _ = Role.objects.get_or_create(
                            name='teacher',
                            defaults={'description': 'Teacher role'}
                        )
                        
                        # Generate unique username
                        username = email.split("@")[0]
                        base_username = username
                        # Add random suffix upfront to reduce collisions
                        if User.objects.filter(username=username).exists():
                            random_suffix = random.randint(1000, 9999)
                            username = f'{base_username}{random_suffix}'
                            # Double check and add more random if still exists (rare)
                            if User.objects.filter(username=username).exists():
                                username = f'{base_username}_{random.randint(10000, 99999)}'
                        
                        # Generate 8-character password for password_hash
                        characters = string.ascii_letters + string.digits
                        generated_password = ''.join(random.choice(characters) for _ in range(8))
                        
                        # Create user account
                        user = User.objects.create(
                            email=email,
                            username=username,
                            first_name=first_name,
                            last_name=last_name or '',
                            role=role,
                            is_active=True,
                            has_custom_password=False,
                            password_hash=generated_password
                        )
                        
                        # Set password field to unusable (user will login with password_hash first time)
                        user.set_unusable_password()
                        user.save()
                        
                        logger.info(f"User account created for teacher: {email} with role_id={role.id}")
                        
                except IntegrityError as e:
                    # Handle race condition - user might have been created by another process
                    logger.warning(f"IntegrityError creating user for teacher: {str(e)}")
                    # Try to get the user that was just created
                    user = User.objects.filter(email=email).first()
                    if not user:
                        raise serializers.ValidationError({
                            'email': f'Failed to create user account. Please try again.'
                        })
            else:
                logger.info(f"User account already exists for teacher email: {email}")
        
        if 'is_class_teacher' not in validated_data:
            validated_data['is_class_teacher'] = False
            
        # Handle department - lookup or create
        department = self._handle_department(validated_data)
        if department:
            validated_data['department'] = department
        
        teacher = Teacher.objects.create(user=user, **validated_data)
        return teacher

    def update(self, instance, validated_data):
        """Update teacher"""
        # Handle department
        if 'department' in validated_data:
            department = self._handle_department(validated_data)
            instance.department = department
            # If department was processed, it's already popped from validated_data in _handle_department
        
        # Update other fields standard way
        return super().update(instance, validated_data)


class StudentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    school_id = serializers.CharField(source='school.school_id', read_only=True)
    total_fee_amount = serializers.SerializerMethodField()
    paid_fee_amount = serializers.SerializerMethodField()
    due_fee_amount = serializers.SerializerMethodField()
    fees_count = serializers.SerializerMethodField()
    profile_photo_url = serializers.SerializerMethodField()
    
    class_name = serializers.SerializerMethodField()
    section = serializers.SerializerMethodField()
    awards = serializers.SerializerMethodField()
    
    bus_route = serializers.SerializerMethodField()
    attendance = serializers.SerializerMethodField()
    grade = serializers.SerializerMethodField()
    student_classes = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = [
            'email', 'user', 'school', 'school_id', 'school_name', 'student_id',
            'student_name', 'parent_name', 'date_of_birth', 'gender',
            'applying_class', 'address', 'category', 'admission_number',
            'parent_phone', 'emergency_contact', 'medical_information',
            'blood_group', 'previous_school', 'remarks',
            'profile_photo', 'profile_photo_url',
            'activities', 'leadership', 'achievements', 'participation',
            'total_fee_amount', 'paid_fee_amount', 'due_fee_amount', 'fees_count',
            'bus_route', 'class_name', 'section', 'awards',
            'attendance', 'grade', 'student_classes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['email', 'school_id', 'created_at', 'updated_at', 'user', 'profile_photo_url']

    def get_bus_route(self, obj):
        # Find the student's bus route via BusStopStudent -> BusStop -> Bus
        bus_stop_student = obj.bus_stops.first()
        if bus_stop_student and bus_stop_student.bus_stop and bus_stop_student.bus_stop.bus:
            return bus_stop_student.bus_stop.bus.route_name
        return None

    def get_bus_number(self, obj):
        # Find the student's bus number via BusStopStudent -> BusStop -> Bus
        bus_stop_student = obj.bus_stops.first()
        if bus_stop_student and bus_stop_student.bus_stop and bus_stop_student.bus_stop.bus:
            return bus_stop_student.bus_stop.bus.bus_number
        return None
    
    def get_profile_photo_url(self, obj):
        if obj.profile_photo:
            request = self.context.get('request')
            if request:
                # If it's already a full URL, return it
                if obj.profile_photo.startswith('http://') or obj.profile_photo.startswith('https://'):
                    return obj.profile_photo
                # If it starts with /media/, it's a media file URL - build absolute URI
                if obj.profile_photo.startswith('/media/'):
                    return request.build_absolute_uri(obj.profile_photo)
                # If it doesn't start with /, add /media/ prefix (for relative paths like 'profile_photos/...')
                if not obj.profile_photo.startswith('/'):
                    media_path = f'/media/{obj.profile_photo}'
                    return request.build_absolute_uri(media_path)
                # For other absolute paths, build absolute URI
                return request.build_absolute_uri(obj.profile_photo)
            # If no request context, return as-is
            return obj.profile_photo
        return None

    def get_student_classes(self, obj):
        """Get summarized class info for the student without circular imports"""
        try:
            # Safely fetch student_classes (related name from teacher.models.ClassStudent)
            # We don't import ClassStudent here to avoid circular dependencies
            classes = []
            for sc in obj.student_classes.all():
                classes.append({
                    'id': sc.id,
                    'class_id': sc.class_obj.id,
                    'class_name': sc.class_obj.name,
                    'section': sc.class_obj.section,
                    'enrolled_date': sc.enrolled_date
                })
            return classes
        except:
            return []
    
    def get_total_fee_amount(self, obj):
        from django.db.models import Sum
        try:
            total = obj.management_fees.aggregate(Sum('total_amount'))['total_amount__sum'] or 0
            return float(total)
        except:
            return 0.0
    
    def get_paid_fee_amount(self, obj):
        from django.db.models import Sum
        try:
            paid = obj.management_fees.aggregate(Sum('paid_amount'))['paid_amount__sum'] or 0
            return float(paid)
        except:
            return 0.0
    
    def get_due_fee_amount(self, obj):
        from django.db.models import Sum
        try:
            due = obj.management_fees.aggregate(Sum('due_amount'))['due_amount__sum'] or 0
            return float(due)
        except:
            return 0.0
    
    def get_fees_count(self, obj):
        try:
            return obj.management_fees.count()
        except:
            return 0

    def get_class_name(self, obj):
        """Get class name from latest enrollment"""
        try:
            # Use the most recent enrollment
            enrollment = obj.student_classes.order_by('-enrolled_date').first()
            if enrollment and enrollment.class_obj:
                return enrollment.class_obj.name
            # Fallback to applying_class or section fields if no enrollment
            return obj.applying_class or obj.section or ""
        except Exception:
            return ""

    def get_section(self, obj):
        """Get section from latest enrollment"""
        try:
            enrollment = obj.student_classes.order_by('-enrolled_date').first()
            if enrollment and enrollment.class_obj:
                return enrollment.class_obj.section
            return ""
        except Exception:
            return ""

    def get_awards(self, obj):
        from .models import Award
        try:
             # Find awards where student_ids contains the student_id
             if not obj.student_id: return []
             awards = Award.objects.filter(student_ids__icontains=obj.student_id).order_by('-id')
             
             request = self.context.get('request')
             
             # Return needed fields manually to avoid heavy nested serialization (no student_details)
             result = []
             for a in awards:
                 award_data = {
                     'id': a.id,
                     'title': a.title,
                     'category': a.category,
                     'level': a.level,
                     'date': a.date.isoformat() if a.date else None,
                     'description': a.description,
                     'presented_by': a.presented_by,
                     'recipient': a.recipient,
                     'team_id': a.team_id,
                     'student_ids': a.student_ids,
                     'document': a.document.url if a.document else None,
                     'document_url': request.build_absolute_uri(a.document.url) if a.document and request else (a.document.url if a.document else None),
                     'certificates': AwardCertificateSerializer(a.certificates.all(), many=True, context=self.context).data
                 }
                 result.append(award_data)
             return result
        except:
            return []

    def get_attendance(self, obj):
        """Get attendance summary"""
        try:
            # Import here to avoid circular import
            from teacher.models import Attendance
            
            total_days = Attendance.objects.filter(student=obj).count()
            present_days = Attendance.objects.filter(student=obj, status='present').count()
            
            if total_days > 0:
                percentage = (present_days / total_days) * 100
                return f"{percentage:.1f}%"
            return "0%"
        except Exception:
            return "0%"

    def get_grade(self, obj):
        """Get grade summary (GPA or average)"""
        try:
            # Import here to avoid circular import
            from teacher.models import Grade
             # Basic implementation - average of marks obtained
            grades = Grade.objects.filter(student=obj)
            if grades.exists():
                 total_marks = 0
                 count = 0 
                 for g in grades:
                     if g.marks_obtained:
                         try:
                             total_marks += float(g.marks_obtained)
                             count += 1
                         except: pass
                 
                 if count > 0:
                     avg = total_marks / count
                     # Convert to GPA scale 4.0 approx logic or just return avg string
                     if avg >= 90: return "4.0"
                     if avg >= 80: return "3.5"
                     if avg >= 70: return "3.0"
                     if avg >= 60: return "2.5"
                     return "2.0"
            return "N/A"
        except Exception:
            return "N/A"


class NewAdmissionSerializer(SchoolIdMixin, serializers.ModelSerializer):
    generated_password = serializers.CharField(read_only=True)
    created_student = StudentSerializer(read_only=True)
    
    class Meta:
        model = NewAdmission
        fields = [
            'student_id', 'school_id', 'student_name', 'parent_name',
            'date_of_birth', 'gender', 'applying_class', 'section',
            'address', 'category', 'status',
            'admission_number', 'email', 'parent_phone', 'emergency_contact',
            'medical_information', 'blood_group', 'previous_school', 'remarks',
            'created_at', 'updated_at', 'generated_password', 'created_student'
        ]
        read_only_fields = ['created_at', 'updated_at', 'generated_password', 'created_student']

    def create(self, validated_data):
        import random, string, datetime, logging
        from django.db import transaction, IntegrityError
        from main_login.models import User, Role

        logger = logging.getLogger(__name__)

        with transaction.atomic():
            # auto school
            request = self.context.get("request")
            if request and request.user.is_authenticated:
                sid = get_user_school_id(request.user)
                if sid:
                    validated_data["school_id"] = sid

            # student id
            if not validated_data.get("student_id"):
                validated_data["student_id"] = f"STUD-{random.randint(100000,999999)}"

            # Generate password for when admission is approved (user will be created then)
            generated_password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8))
            self.generated_password = generated_password

            admission = NewAdmission.objects.create(**validated_data)
            admission.generated_password = generated_password
            return admission


# ---------------- remaining serializers unchanged -------------------

class DashboardStatsSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    
    class Meta:
        model = DashboardStats
        fields = [
            'school', 'total_teachers', 'total_students',
            'total_departments', 'updated_at'
        ]


class ExaminationManagementSerializer(SchoolIdMixin, serializers.ModelSerializer):
    class Meta:
        model = Examination_management
        fields = '__all__'


class PaymentHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentHistory
        fields = '__all__'


class FeeSerializer(SchoolIdMixin, serializers.ModelSerializer):
    student_id = serializers.SerializerMethodField()
    student_email = serializers.SerializerMethodField()
    payment_history = PaymentHistorySerializer(many=True, read_only=True)

    class Meta:
        model = Fee
        fields = '__all__'

    def get_student_id(self, obj):
        return str(obj.student.student_id) if obj.student else ''

    def get_student_email(self, obj):
        return obj.student.email if obj.student else ''


class BusStopStudentSerializer(SchoolIdMixin, serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.student_name', read_only=True)
    bus_stop_name = serializers.CharField(source='bus_stop.stop_name', read_only=True)
    bus_number = serializers.SerializerMethodField()
    bus_stop_detail = serializers.SerializerMethodField()

    class Meta:
        model = BusStopStudent
        fields = '__all__'
    
    def get_bus_number(self, obj):
        """Get bus number from bus_stop's bus"""
        if obj.bus_stop and obj.bus_stop.bus:
            return obj.bus_stop.bus.bus_number
        return None
    
    def get_bus_stop_detail(self, obj):
        """Get bus_stop details including bus information"""
        if obj.bus_stop:
            return {
                'stop_id': obj.bus_stop.stop_id,
                'stop_name': obj.bus_stop.stop_name,
                'bus': {
                    'bus_number': obj.bus_stop.bus.bus_number if obj.bus_stop.bus else None,
                    'id': obj.bus_stop.bus.bus_number if obj.bus_stop.bus else None,
                } if obj.bus_stop.bus else None,
            }
        return None


class BusStopSerializer(SchoolIdMixin, serializers.ModelSerializer):
    bus_name = serializers.CharField(source='bus.bus_number', read_only=True)

    class Meta:
        model = BusStop
        fields = '__all__'


class BusSerializer(SchoolIdMixin, serializers.ModelSerializer):
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    morning_stops = serializers.SerializerMethodField()
    afternoon_stops = serializers.SerializerMethodField()

    class Meta:
        model = Bus
        fields = '__all__'

    def get_morning_stops(self, obj):
        """Get morning stops with their students"""
        # Get all morning stops for this bus, ordered by stop_order
        morning_stops = obj.stops.filter(route_type='morning').order_by('stop_order')
        
        stops_data = []
        for stop in morning_stops:
            # Get students for this stop
            students = stop.stop_students.all()
            
            # Serialize students
            students_data = []
            for student_link in students:
                students_data.append({
                    'id': str(student_link.id),
                    'student_id_string': student_link.student_id_string or '',
                    'student_name': student_link.student_name or '',
                    'student_class': student_link.student_class or '',
                    'student_section': student_link.student_section or '',
                    'pickup_time': student_link.pickup_time.strftime('%H:%M:%S') if student_link.pickup_time else None,
                    'dropoff_time': student_link.dropoff_time.strftime('%H:%M:%S') if student_link.dropoff_time else None,
                    'bus_stop_name': stop.stop_name,
                })
            
            # Serialize stop with students
            stop_data = {
                'stop_id': stop.stop_id,
                'stop_name': stop.stop_name,
                'stop_address': stop.stop_address,
                'stop_time': stop.stop_time.strftime('%H:%M:%S') if stop.stop_time else None,
                'route_type': stop.route_type,
                'stop_order': stop.stop_order,
                'latitude': float(stop.latitude) if stop.latitude else None,
                'longitude': float(stop.longitude) if stop.longitude else None,
                'students': students_data,
                'student_count': len(students_data),
                'created_at': stop.created_at.isoformat() if stop.created_at else None,
                'updated_at': stop.updated_at.isoformat() if stop.updated_at else None,
            }
            stops_data.append(stop_data)
        
        return stops_data

    def get_afternoon_stops(self, obj):
        """Get afternoon stops with their students"""
        # Get all afternoon stops for this bus, ordered by stop_order
        afternoon_stops = obj.stops.filter(route_type='afternoon').order_by('stop_order')
        
        stops_data = []
        for stop in afternoon_stops:
            # Get students for this stop
            students = stop.stop_students.all()
            
            # Serialize students
            students_data = []
            for student_link in students:
                students_data.append({
                    'id': str(student_link.id),
                    'student_id_string': student_link.student_id_string or '',
                    'student_name': student_link.student_name or '',
                    'student_class': student_link.student_class or '',
                    'student_section': student_link.student_section or '',
                    'pickup_time': student_link.pickup_time.strftime('%H:%M:%S') if student_link.pickup_time else None,
                    'dropoff_time': student_link.dropoff_time.strftime('%H:%M:%S') if student_link.dropoff_time else None,
                    'bus_stop_name': stop.stop_name,
                })
            
            # Serialize stop with students
            stop_data = {
                'stop_id': stop.stop_id,
                'stop_name': stop.stop_name,
                'stop_address': stop.stop_address,
                'stop_time': stop.stop_time.strftime('%H:%M:%S') if stop.stop_time else None,
                'route_type': stop.route_type,
                'stop_order': stop.stop_order,
                'latitude': float(stop.latitude) if stop.latitude else None,
                'longitude': float(stop.longitude) if stop.longitude else None,
                'students': students_data,
                'student_count': len(students_data),
                'created_at': stop.created_at.isoformat() if stop.created_at else None,
                'updated_at': stop.updated_at.isoformat() if stop.updated_at else None,
            }
            stops_data.append(stop_data)
        
        return stops_data


class EventSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Event model"""
    computed_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Event
        fields = [
            'id', 'school_id', 'school_name', 'name', 'category', 'start_datetime',
            'end_datetime', 'location', 'organizer', 'participants', 'status',
            'computed_status', 'description', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school_id', 'school_name', 'created_at', 'updated_at', 'computed_status']
    
    def get_computed_status(self, obj):
        return obj.computed_status
    
    def update(self, instance, validated_data):
        """Update event instance"""
        # Update all fields except read-only ones
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class DepartmentSerializer(serializers.ModelSerializer):
    """Serializer for Department model"""
    school_id = serializers.ReadOnlyField(source='school.school_id')
    
    class Meta:
        model = Department
        fields = [
            'id', 'school', 'school_id', 'school_name', 'name', 'code', 'description',
            'head_name', 'email', 'phone', 'faculty_count', 'student_count',
            'course_count', 'established_date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school', 'school_id', 'school_name', 'created_at', 'updated_at']

    def update(self, instance, validated_data):
        """Update department instance"""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class CampusFeatureSerializer(serializers.ModelSerializer):
    """Serializer for CampusFeature model"""
    school_id = serializers.ReadOnlyField(source='school.school_id')
    
    class Meta:
        model = CampusFeature
        fields = [
            'id', 'school', 'school_id', 'school_name', 'name', 'category', 'description',
            'location', 'capacity', 'status', 'date_added', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school', 'school_id', 'school_name', 'date_added', 'created_at', 'updated_at']

    def update(self, instance, validated_data):
        """Update campus feature instance"""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance




class AwardSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Award model"""
    document_url = serializers.SerializerMethodField()
    certificates = AwardCertificateSerializer(many=True, read_only=True)
    student_details = serializers.SerializerMethodField()
    
    class Meta:
        model = Award
        fields = [
            'id', 'school_id', 'school_name', 'title', 'category', 'recipient', 
            'student_ids', 'date', 'description', 'level', 'presented_by', 'document',
            'document_url', 'certificates', 'team_id', 'student_details', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school_id', 'school_name', 'created_at', 'updated_at']

    def get_document_url(self, obj):
        if obj.document:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.document.url)
            return obj.document.url
        return None

    def get_student_details(self, obj):
        if not obj.student_ids:
            return []
        ids = [i.strip() for i in obj.student_ids.split(',') if i.strip()]
        # Fetch students. We can't import at top to avoid circular dependency if any, 
        # but Student is already imported at line 5.
        students = Student.objects.filter(student_id__in=ids)
        name_map = {s.student_id: s.student_name for s in students}
        return [{"student_id": id, "student_name": name_map.get(id, "")} for id in ids]

    def update(self, instance, validated_data):
        """Update award instance"""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance

    def validate_student_ids(self, value):
        """
        Validate that all provided student IDs exist and belong to the user's school.
        """
        if not value:
            # If blank is allowed (blank=True in model), just return
            return value
            
        request = self.context.get('request')
        if not request:
            return value
            
        school_id = get_user_school_id(request.user)
        # If no school_id and not super_admin, we can't strictly validate scope, 
        # but usually permissions handle that. We'll proceed if school_id checks out.
        
        ids = [s.strip() for s in value.split(',') if s.strip()]
        
        for student_id in ids:
            # Check existence and school scope combined
            query = Student.objects.filter(student_id=student_id)
            
            if school_id:
                query = query.filter(school__school_id=school_id)
            
            if not query.exists():
                # Provide the specific error message requested
                raise serializers.ValidationError(f"There is no student on this id: {student_id}")
                
        return value



class ActivitySerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Activity model"""
    
    class Meta:
        model = Activity
        fields = [
            'id', 'school_id', 'school_name', 'name', 'category', 'instructor',
            'max_participants', 'schedule', 'location', 'status', 'start_date', 'end_date',
            'description', 'requirements', 'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school_id', 'school_name', 'created_at', 'updated_at']
    
    def update(self, instance, validated_data):
        """Update activity instance"""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class GalleryImageSerializer(serializers.ModelSerializer):
    """Serializer for GalleryImage model"""
    class Meta:
        model = GalleryImage
        fields = ['id', 'gallery', 'image', 'alt_text', 'created_at']
        read_only_fields = ['id', 'created_at']


class GallerySerializer(serializers.ModelSerializer):
    """Serializer for Gallery model"""
    images = GalleryImageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Gallery
        fields = [
           'id', 'school_id', 'school_name', 'photo_id', 'title', 'category',
            'description', 'date', 'photographer', 'location', 
            'emoji', 'images', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'school_id', 'school_name', 'created_at', 'updated_at']

    def update(self, instance, validated_data):
        """Update gallery instance"""
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        return instance


class PushNotificationLogSerializer(serializers.ModelSerializer):
    """Serializer for PushNotificationLog (read-only list of sent push notifications)."""
    class Meta:
        model = PushNotificationLog
        fields = [
            'id', 'title', 'body', 'audience', 'sent_count', 'user_count',
            'school_id', 'created_by', 'created_at'
        ]
        read_only_fields = fields


class BusStopStudentSerializer(serializers.ModelSerializer):
    """Serializer for BusStopStudent model - handles student assignment to bus stops"""
    student_id = serializers.CharField(write_only=True, required=True, help_text='Student ID string')
    stop = serializers.CharField(write_only=True, required=True, help_text='Bus stop ID')
    
    # Add nested details for student/parent portal
    bus_details = serializers.SerializerMethodField()
    stop_details = serializers.SerializerMethodField()
    attendance_status_today = serializers.SerializerMethodField()
    
    class Meta:
        model = BusStopStudent
        fields = [
            'id', 'bus_stop', 'student', 'student_id', 'stop', 'school_id', 'school_name',
            'student_id_string', 'student_name', 'student_class', 'student_section',
            'pickup_time', 'dropoff_time', 'created_at', 'updated_at',
            'bus_details', 'stop_details', 'attendance_status_today'
        ]
        read_only_fields = [
            'id', 'bus_stop', 'student', 'school_id', 'school_name',
            'student_id_string', 'student_name', 'student_class', 'student_section',
            'pickup_time', 'dropoff_time', 'created_at', 'updated_at',
            'bus_details', 'stop_details', 'attendance_status_today'
        ]
    
    def get_attendance_status_today(self, obj):
        """Today's bus attendance (present/absent) from driver portal."""
        today = timezone.now().date()
        att = BusStopAttendance.objects.filter(
            bus_stop_student=obj, attendance_date=today
        ).first()
        return att.status if att else None
    
    def get_bus_details(self, obj):
        """Get bus details from the stop's bus"""
        if obj.bus_stop and obj.bus_stop.bus:
            bus = obj.bus_stop.bus
            return {
                'bus_number': bus.bus_number,
                'route': bus.route_name,
                'driver_name': bus.driver_name,
                'driver_contact': bus.driver_phone,
                'capacity': bus.capacity,
                'status': 'Active' if bus.is_active else 'Inactive',
            }
        return None
    
    def get_stop_details(self, obj):
        """Get stop details"""
        if obj.bus_stop:
            stop = obj.bus_stop
            return {
                'stop_id': stop.stop_id,
                'stop_name': stop.stop_name,
                'address': stop.stop_address,
                'stop_time': str(stop.stop_time) if stop.stop_time else None,
                'route_type': stop.route_type,
                'stop_order': stop.stop_order,
            }
        return None
    
    def create(self, validated_data):
        """Create BusStopStudent instance by resolving student_id and stop_id to objects"""
        student_id_str = validated_data.pop('student_id')
        stop_id_str = validated_data.pop('stop')
        school_id = validated_data.pop('school_id', None)
        
        # Lookup student by student_id
        student_query = Student.objects.filter(student_id=student_id_str)
        if school_id:
            student_query = student_query.filter(school__school_id=school_id)
        
        student = student_query.first()
        if not student:
            raise ValidationError({
                'student_id': f'Student with ID {student_id_str} not found' + 
                             (f' in school {school_id}' if school_id else '')
            })
        
        # Lookup bus stop by stop_id
        bus_stop = BusStop.objects.filter(stop_id=stop_id_str).first()
        if not bus_stop:
            raise ValidationError({'stop': f'Bus stop with ID {stop_id_str} not found'})
        
        # Check if student is already assigned to this stop
        existing = BusStopStudent.objects.filter(bus_stop=bus_stop, student=student).first()
        if existing:
            # Return existing assignment instead of creating duplicate
            return existing
        
        # Create the assignment
        validated_data['student'] = student
        validated_data['bus_stop'] = bus_stop
        
        return super().create(validated_data)