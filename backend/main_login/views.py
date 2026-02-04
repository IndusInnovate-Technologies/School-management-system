"""
Views for main_login app - Authentication and JWT
"""
from rest_framework import status, generics, permissions
import logging
logger = logging.getLogger(__name__)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.conf import settings
from django.core.mail import send_mail
import random
from .models import Role, FCMDevice, UserNotificationSeen
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    RoleSerializer,
    ChangePasswordSerializer,
    CreatePasswordSerializer,
    FinancialDetailsSerializer
)

User = get_user_model()


def get_tokens_for_user(user):
    """Generate JWT tokens for user"""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register(request):
    """User registration endpoint"""
    serializer = UserRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        tokens = get_tokens_for_user(user)
        user_data = UserSerializer(user).data
        return Response({
            'user': user_data,
            'tokens': tokens,
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login(request):
    """User login endpoint"""
    serializer = UserLoginSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.validated_data['user']
        tokens = get_tokens_for_user(user)
        user_data = UserSerializer(user).data
        return Response({
            'user': user_data,
            'tokens': tokens,
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout(request):
    """User logout endpoint"""
    try:
        refresh_token = request.data.get('refresh_token')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
        return Response({'message': 'Logout successful'}, status=status.HTTP_200_OK)
    except Exception as e:
        # If blacklisting fails (e.g. token already blacklisted or expired), 
        # still return 200 because the client should still clear its local tokens.
        return Response({
            'message': 'Logout successful (local)',
            'warning': str(e)
        }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def profile(request):
    """Get current user profile"""
    serializer = UserSerializer(request.user)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['PUT', 'PATCH'])
@permission_classes([permissions.IsAuthenticated])
def update_profile(request):
    """Update current user profile"""
    serializer = UserSerializer(request.user, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response({
            'user': serializer.data,
            'message': 'Profile updated successfully'
        }, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def change_password(request):
    """Change user password"""
    serializer = ChangePasswordSerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': 'Wrong password.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        new_password = serializer.validated_data['new_password']
        user.set_password(new_password)
        # Store the user's created password (plain text) in updated_password field
        user.updated_password = new_password
        user.has_custom_password = True
        user.save()
        return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_password(request):
    """Create user password (first time after login with generated password)"""
    serializer = CreatePasswordSerializer(data=request.data)
    if serializer.is_valid():
        user = request.user
        password = serializer.validated_data['password']
        
        # When user creates a custom password, has_custom_password will be set to True
        # The old password will be updated/replaced with the new password in the database
        # Use the model's set_new_password method which handles:
        # 1. Setting has_custom_password = True
        # 2. Replacing old password with new password
        # 3. Removing temporary password_hash
        user.set_new_password(password)
        
        # Verify that has_custom_password is now True
        user.refresh_from_db()
        if not user.has_custom_password:
            return Response({
                'success': False,
                'message': 'Failed to set custom password flag'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Also save password in NewAdmission table if user has a matching admission record
        try:
            from management_admin.models import NewAdmission
            # Find NewAdmission by email (matching user's email)
            admission = NewAdmission.objects.filter(email=user.email).first()
            if admission:
                # Store hashed password in NewAdmission table
                # The password is already hashed by set_new_password
                admission.password = user.password
                admission.save()
        except Exception as e:
            # If NewAdmission doesn't exist or import fails, continue anyway
            # This allows the password creation to succeed even if there's no admission record
            pass
        
        return Response({
            'success': True,
            'message': 'Password created successfully. You can now use this password for future logins.',
            'has_custom_password': user.has_custom_password
        }, status=status.HTTP_200_OK)
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


class RoleListView(generics.ListAPIView):
    """List all available roles"""
    queryset = Role.objects.all()
    serializer_class = RoleSerializer
    permission_classes = [permissions.AllowAny]


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def refresh_token(request):
    """Refresh JWT token"""
    try:
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response(
                {'error': 'Refresh token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        token = RefreshToken(refresh_token)
        return Response({
            'access': str(token.access_token),
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response(
            {'error': 'Invalid or expired refresh token'},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_role_routes(request):
    """Get routing information for each role"""
    role_routes = {
        'admin': {
            'login_page': '/admin_login',
            'login_file': 'admin_login.dart',
            'dashboard_route': '/super-admin/dashboard',
            'api_base': '/api/super-admin/',
        },
        'management': {
            'login_page': '/management_login',
            'login_file': 'management_login.dart',
            'dashboard_route': '/management-admin/dashboard',
            'api_base': '/api/management-admin/',
        },
        'teacher': {
            'login_page': '/teacher_login',
            'login_file': 'teacher_login.dart',
            'dashboard_route': '/teacher/dashboard',
            'api_base': '/api/teacher/',
        },
        'parent': {
            'login_page': '/parent_login',
            'login_file': 'parent_login.dart',
            'dashboard_route': '/student-parent/dashboard',
            'api_base': '/api/student-parent/',
        },
        'student_parent': {
            'login_page': '/parent_login',
            'login_file': 'parent_login.dart',
            'dashboard_route': '/student-parent/dashboard',
            'api_base': '/api/student-parent/',
        },
        'driver': {
            'login_page': '/driver_login',
            'login_file': 'driver_login.dart',
            'dashboard_route': '/driver/dashboard',
            'api_base': '/api/driver/',
        },
        'financial': {
            'login_page': '/financial_login',
            'login_file': 'financial_login.dart',
            'dashboard_route': '/management-admin/fees',
            'api_base': '/api/management-admin/',
        },
    }
    
    role = request.query_params.get('role', '').lower()
    
    if role and role in role_routes:
        return Response({
            'success': True,
            'role': role,
            'route': role_routes[role],
        }, status=status.HTTP_200_OK)
    
    # Return all routes if no specific role requested
    return Response({
        'success': True,
        'routes': role_routes,
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def test_db_connection(request):
    """Test endpoint to verify database connection and list users"""
    try:
        from django.db import connection
        
        # Test database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT version();")
            db_version = cursor.fetchone()[0]
        
        # Get user count
        user_count = User.objects.count()
        role_count = Role.objects.count()
        
        # Get sample users
        users = User.objects.all()[:10]
        user_list = [
            {
                'email': user.email,
                'username': user.username,
                'role': user.role.name if user.role else None,
                'is_active': user.is_active
            }
            for user in users
        ]
        
        return Response({
            'success': True,
            'database': {
                'connected': True,
                'version': db_version.split(',')[0] if db_version else 'Unknown',
                'user_count': user_count,
                'role_count': role_count,
            },
            'users': user_list,
            'message': 'Database connection successful'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e),
            'message': 'Database connection failed'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def role_login(request):
    """Role-specific login endpoint that validates role and returns routing info"""
    try:
        # Safely get request data
        print(f"DEBUG: role_login started")
        try:
            request_data = request.data if hasattr(request, 'data') else {}
            print(f"DEBUG: request_data: {request_data}")
        except Exception as e:
            request_data = {}
            print(f"DEBUG: request_data failed: {str(e)}")
        
        try:
            serializer = UserLoginSerializer(data=request_data)
        except Exception as e:
            import traceback
            return Response({
                'success': False,
                'message': f'Error creating serializer: {str(e)}',
                'error': 'Serialization error',
                'traceback': traceback.format_exc() if settings.DEBUG else None
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        try:
            is_valid = serializer.is_valid()
        except Exception as e:
            import traceback
            return Response({
                'success': False,
                'message': f'Error validating credentials: {str(e)}',
                'error': 'Validation error',
                'traceback': traceback.format_exc() if settings.DEBUG else None
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        if is_valid:
            user = serializer.validated_data['user']
            print(f"DEBUG: user authenticated: {user}")
            requested_role = request_data.get('role', '')
            print(f"DEBUG: requested_role: {requested_role}")
            if isinstance(requested_role, str):
                requested_role = requested_role.lower()
            else:
                requested_role = str(requested_role).lower() if requested_role else ''
            
            # Map frontend role names to backend role names
            role_mapping = {
                'admin': 'super_admin',
                'management': 'management_admin',
                'teacher': 'teacher',
                'parent': 'student_parent',
                'financial': 'financial',
                'driver': 'driver',
            }
            
            backend_role = role_mapping.get(requested_role, requested_role)
            
            # Get current role name safely
            current_role_name = None
            if user.role:
                try:
                    current_role_name = user.role.name
                except Exception:
                    current_role_name = "Unknown"

            # Normalize driver_bus to driver (role should be "driver" only)
            if current_role_name == 'driver_bus':
                current_role_name = 'driver'

            # Verify user has the correct role
            if user.role and current_role_name == backend_role:
                try:
                    logger.error(f"DEBUG_LOGIN: Match found for {user.email}")
                    tokens = get_tokens_for_user(user)
                    logger.error(f"DEBUG_LOGIN: Tokens generated")
                    
                    user_data = UserSerializer(user).data
                    logger.error(f"DEBUG_LOGIN: UserSerializer success")
                    
                    # Get routing information for the role
                    route_info = {
                        'admin': {
                            'login_page': '/admin_login',
                            'dashboard_route': '/super-admin/dashboard',
                        },
                        'management': {
                            'login_page': '/management_login',
                            'dashboard_route': '/management-admin/dashboard',
                        },
                        'teacher': {
                            'login_page': '/teacher_login',
                            'dashboard_route': '/teacher/dashboard',
                        },
                        'parent': {
                            'login_page': '/parent_login',
                            'dashboard_route': '/student-parent/dashboard',
                        },
                        'financial': {
                            'login_page': '/financial_login',
                            'dashboard_route': '/management-admin/fees',
                        },
                        'driver': {
                            'login_page': '/driver_login',
                            'dashboard_route': '/driver/dashboard',
                        },
                    }
                    
                    # Check if user needs to create their own password
                    needs_password_creation = user.needs_password_creation()
                    
                    return Response({
                        'success': True,
                        'user': user_data,
                        'tokens': tokens,
                        'role': requested_role,
                        'routes': route_info.get(requested_role, {}),
                        'needs_password_creation': needs_password_creation,
                        'message': f'Login successful as {requested_role}'
                    }, status=status.HTTP_200_OK)
                except Exception as e:
                    import traceback
                    return Response({
                        'success': False,
                        'message': f'Error during login: {str(e)}',
                        'error': 'Internal server error',
                        'traceback': traceback.format_exc() if settings.DEBUG else None
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            else:
                return Response({
                    'success': False,
                    'message': f'User does not have {requested_role} role. Current role: {current_role_name or "None"}'
                }, status=status.HTTP_403_FORBIDDEN)
        
        return Response({
            'success': False,
            'errors': serializer.errors,
            'message': 'Invalid credentials'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        import traceback
        return Response({
            'success': False,
            'message': f'Unexpected error: {str(e)}',
            'error': 'Internal server error',
            'traceback': traceback.format_exc() if settings.DEBUG else None
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ==========================================
# PASSWORD RESET & OTP SECTION
# ==========================================

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def request_otp(request):
    """Generate and send OTP to user's email"""
    email = request.data.get('email')
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email)
        otp = str(random.randint(100000, 999999))
        user.reset_otp = otp
        user.save()
        
        # Send email
        subject = '🔐 Security Code for Password Reset'
        message = (
            f"Dear User,\n\n"
            f"A password reset was requested for your account. Please use the following 6-digit verification code to proceed:\n\n"
            f"OTP CODE: {otp}\n\n"
            f"If you did not request this, please ignore this email. This is a system-generated email, please do not reply.\n\n"
            f"Regards,\n"
            f"School Management System Security Team"
        )
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [email]
        
        # We print to console ALWAYS for development as requested
        print(f"\n\n{'*' * 40}")
        print(f"FORGOT PASSWORD OTP FOR {email}: {otp}")
        print(f"{'*' * 40}\n\n")

        try:
            send_mail(subject, message, from_email, recipient_list)
            email_sent = True
        except Exception as e:
            import traceback
            print(f"FAILED TO SEND EMAIL TO {email}:")
            traceback.print_exc()
            email_sent = False
        
        return Response({
            'success': True, 
            'message': 'OTP sent successfully to your email and terminal.',
            'email_sent': email_sent
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'User with this email does not exist'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def reset_password_with_otp(request):
    """Verify OTP and reset password"""
    email = request.data.get('email')
    otp = request.data.get('otp')
    new_password = request.data.get('new_password')
    
    if not all([email, otp, new_password]):
        return Response({'error': 'Email, OTP, and new password are required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email, reset_otp=otp)
        
        # OTP is valid, reset password
        user.set_new_password(new_password)
        user.reset_otp = None # Clear OTP after use
        user.save()
        
        return Response({
            'success': True,
            'message': 'Password has been reset successfully.'
        }, status=status.HTTP_200_OK)
        
    except User.DoesNotExist:
        return Response({'error': 'Invalid OTP or email'}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==========================================
# FINANCIAL STAFF MANAGEMENT SECTION
# ==========================================

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_financial_user(request):
    """Create financial staff user in User table AND FinancialDetails table"""
    from django.db import transaction
    from .models import FinancialDetails
    from django.contrib.auth.hashers import make_password
    
    try:
        print("=" * 80)
        print("CREATE FINANCIAL USER - Request received")
        print(f"Request user: {request.user}")
        print(f"Request data: {request.data}")
        print("=" * 80)
        
        # Prepare data for serializer
        data = request.data.copy()
        
        # 1. Handle Name (Split into first_name and last_name)
        full_name = ''
        if 'name' in data:
            full_name = data['name'].strip()
            # Also remove name from data to avoid serializer errors if it doesn't expect it
            # But UserRegistrationSerializer doesn't have 'name', so we keep it for FinancialDetails
            name_parts = full_name.split(' ', 1)
            data['first_name'] = name_parts[0]
            data['last_name'] = name_parts[1] if len(name_parts) > 1 else ''
        
        # 2. Map 'phone' to 'mobile'
        if 'phone' in data:
            data['mobile'] = data['phone']
        
        # 3. Set username (use email if not provided)
        if 'username' not in data and 'email' in data:
            data['username'] = data['email']
        
        # 4. Set role to 'financial'
        data['role'] = 'financial'
        
        # 5. Handle password confirmation
        if 'password' in data and 'password2' not in data:
            data['password2'] = data['password']
        
        print(f"Processed data: {data}")
        
        # Ensure 'financial' role exists
        financial_role, created = Role.objects.get_or_create(
            name='financial',
            defaults={'description': 'Financial Staff'}
        )
        if created:
            print("Created 'financial' role")
        
        # USE ATOMIC TRANSACTION
        with transaction.atomic():
            # Use existing UserRegistrationSerializer
            serializer = UserRegistrationSerializer(data=data)
            if serializer.is_valid():
                print("Serializer validation passed")
                user = serializer.save()
                print(f"Financial user created in User table: {user.email}")
                
                # --- CREATE FINANCIAL DETAILS RECORD ---
                # Extract fields needed for FinancialDetails
                email = data.get('email')
                password = data.get('password')
                phone = data.get('phone', data.get('mobile', ''))
                address = data.get('address', '')
                date_of_birth = data.get('date_of_birth')
                gender = data.get('gender')
                school_id = data.get('school_id', '')
                
                # Create the financial record
                fin_details, fin_created = FinancialDetails.objects.get_or_create(
                    email=email,
                    defaults={
                        'full_name': full_name or f"{user.first_name} {user.last_name}".strip(),
                        'phone': phone,
                        'address': address,
                        'date_of_birth': date_of_birth,
                        'gender': gender,
                        'school_id': school_id,
                        'is_active': True
                    }
                )
                
                # Set password (hashed)
                if password:
                    fin_details.password = make_password(password)
                    fin_details.save()
                
                print(f"FinancialDetails record {'created' if fin_created else 'fetched'} for {email}")
                
                return Response({
                    'success': True,
                    'message': 'Financial staff created successfully',
                    'user_id': str(user.user_id),
                    'financial_id': str(fin_details.financial_id),
                    'email': user.email,
                    'username': user.username
                }, status=status.HTTP_201_CREATED)
            
            print(f"Serializer validation FAILED: {serializer.errors}")
            return Response({
                'success': False,
                'errors': serializer.errors,
                'message': 'Validation failed'
            }, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        import traceback
        print(f"Exception occurred: {str(e)}")
        print(traceback.format_exc())
        return Response({
            'success': False,
            'message': f'Error creating financial user: {str(e)}',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class FinancialUserListView(generics.ListAPIView):
    """List all financial users"""
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter users by financial role and optional school_id"""
        queryset = User.objects.filter(role__name='financial', is_active=True)
        
        # Filter by school_id if available in request user or params
        # This assumes User model might have school_id or we filter by context
        return queryset


# -------------------------
# FCM Push Notification (register/unregister device tokens)
# -------------------------

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def fcm_register(request):
    """Register FCM token for current user (Android/iOS). Call after login."""
    token = (request.data.get('token') or request.data.get('fcm_token') or '').strip()
    platform = (request.data.get('platform') or 'android').lower()
    if platform not in ('android', 'ios'):
        platform = 'android'
    if not token:
        return Response({'error': 'token is required'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        device, created = FCMDevice.objects.update_or_create(
            token=token,
            defaults={'user': request.user, 'platform': platform}
        )
        return Response({
            'message': 'FCM token registered',
            'created': created,
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.exception('FCM register failed: %s', e)
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def fcm_unregister(request):
    """Remove FCM token (e.g. on logout)."""
    token = (request.data.get('token') or request.data.get('fcm_token') or '').strip()
    if not token:
        return Response({'error': 'token is required'}, status=status.HTTP_400_BAD_REQUEST)
    deleted, _ = FCMDevice.objects.filter(token=token, user=request.user).delete()
    return Response({
        'message': 'FCM token removed',
        'deleted': deleted,
    }, status=status.HTTP_200_OK)


# -------------------------
# My push notifications (for student/parent and teacher portals)
# -------------------------

def _get_notification_audience(user):
    """Return list of audience values relevant to this user (for filtering PushNotificationLog)."""
    from management_admin.models import Teacher
    from student_parent.models import Parent
    if Teacher.objects.filter(user=user).exists():
        return ['all_teachers', 'both']
    if Parent.objects.filter(user=user).exists():
        return ['all_students', 'both']
    # Student (user linked to Student)
    from management_admin.models import Student
    if Student.objects.filter(user=user).exists():
        return ['all_students', 'both']
    return ['both']


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def my_push_notifications(request):
    """List push notifications for the current user (by audience + school) and unread count."""
    from .utils import get_user_school_id
    from management_admin.models import PushNotificationLog

    school_id = get_user_school_id(request.user)
    if not school_id:
        return Response({'notifications': [], 'unread_count': 0}, status=status.HTTP_200_OK)

    audience_list = _get_notification_audience(request.user)
    from django.utils import timezone as tz
    from datetime import timedelta
    since = tz.now() - timedelta(days=1)

    logs_list = list(
        PushNotificationLog.objects.filter(
            school_id=school_id,
            audience__in=audience_list,
            created_at__gte=since,
        ).order_by('-created_at')[:50]
    )

    try:
        last_seen = request.user.notification_seen.last_seen_at
    except Exception:
        last_seen = None

    unread_count = 0
    if last_seen:
        for log in logs_list:
            created = log.created_at
            if created and tz.is_naive(created):
                created = tz.make_aware(created)
            if created and last_seen and created > last_seen:
                unread_count += 1
    else:
        unread_count = len(logs_list)

    notifications = [
        {
            'id': log.id,
            'title': log.title,
            'body': log.body,
            'audience': log.audience,
            'created_at': log.created_at.isoformat() if log.created_at else None,
        }
        for log in logs_list
    ]

    return Response({
        'notifications': notifications,
        'unread_count': unread_count,
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def my_push_notifications_mark_read(request):
    """Mark push notifications as read for the current user (resets unread count)."""
    from django.utils import timezone
    UserNotificationSeen.objects.update_or_create(
        user=request.user,
        defaults={'last_seen_at': timezone.now()},
    )
    return Response({'message': 'Marked as read'}, status=status.HTTP_200_OK)
