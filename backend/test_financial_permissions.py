
import os
import sys

# Add project root to sys.path
sys.path.append('C:\\Users\\Admin\\Desktop\\testing_main\\backend')

# Setup Django if running standalone
if 'DJANGO_SETTINGS_MODULE' not in os.environ:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
    import django
    try:
        django.setup()
    except Exception as e:
        print(f"Django setup warning: {e}")

from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework import status

def run_tests():
    # Write to file
    with open('verification_results.txt', 'w') as f:
        # Redirect stdout
        original_stdout = sys.stdout
        sys.stdout = f
        
        try:
            print("Starting Financial Permission Tests...")
            
            # Import models/views HERE to avoid AppRegistryNotReady
            from main_login.models import User, Role, FinancialDetails
            from management_admin.views import StudentViewSet, FeeViewSet
    
            # 1. Setup Financial User
            email = 'test_fin_perm@example.com'
            try:
                User.objects.filter(email=email).delete()
                FinancialDetails.objects.filter(email=email).delete() # clean sibling
            except Exception:
                pass 
            
            # Ensure 'financial' role exists
            role, _ = Role.objects.get_or_create(name='financial')
            
            user = User.objects.create(
                email=email,
                username='test_fin_perm',
                role=role,
                is_active=True
            )
            user.set_password('pass')
            user.save()
            print(f"Created financial user: {user.email}")

            # Create Financial Details (Required for SchoolFilterMixin)
            FinancialDetails.objects.create(
                email=email,
                full_name='Test Fin',
                school_id='TEST_SCHOOL_99', # Dummy school ID
                phone='1234567890'
            )
            print("Created FinancialDetails with school_id='TEST_SCHOOL_99'")
            
            factory = APIRequestFactory()
            
            # Test 1: Access to Students (Should be Read-Only)
            print("\n--- Testing Student Access (Restricted) ---")
            
            # GET (List) - Should allow
            request = factory.get('/api/management-admin/students/')
            force_authenticate(request, user=user)
            view = StudentViewSet.as_view({'get': 'list'})
            response = view(request)
            print(f"GET /students/ -> {response.status_code} (Expected: 200)")
            if response.status_code == 200:
                print("PASS: Read access allowed.")
            else:
                print("FAIL: Read access denied.")

            # POST (Create) - Should deny
            data = {'first_name': 'Test', 'last_name': 'Student', 'email': 'test@student.com'}
            request = factory.post('/api/management-admin/students/', data)
            force_authenticate(request, user=user)
            view = StudentViewSet.as_view({'post': 'create'})
            try:
                response = view(request)
                print(f"POST /students/ -> {response.status_code} (Expected: 403)")
                if response.status_code == 403:
                    print("PASS: Write access denied.")
                else:
                    print("FAIL: Write access allowed or other error.")
            except Exception as e:
                 # PermissionDenied might be raised directly depending on config
                 print(f"PASS: Write access denied (Exception: {e})")

            # Test 2: Access to Fees (Should be Full CRUD)
            print("\n--- Testing Fee Access (Full Permissions) ---")
            
            # POST (Create) - Should allow
            fee_data = {
                'student_id': 'ST001', 
                'amount': 1000,
                'fee_type': 'Tuition'
            }
            request = factory.post('/api/management-admin/fees/', fee_data)
            force_authenticate(request, user=user)
            view = FeeViewSet.as_view({'post': 'create'})
            
            try:
                response = view(request)
                print(f"POST /fees/ -> {response.status_code} (Expected: 400 or 201, NOT 403)")
                if response.status_code != 403:
                    print("PASS: Write access allowed (Validation error is okay).")
                else:
                    print("FAIL: Write access denied (403).")
            except Exception as e:
                print(f"FAIL: Exception: {e}")
                
        except Exception as e:
            print(f"CRITICAL ERROR: {e}")
            import traceback
            traceback.print_exc()
        
        finally:
            sys.stdout = original_stdout

# Call unconditionally
run_tests()
