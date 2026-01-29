
from rest_framework.test import APIRequestFactory, force_authenticate
from main_login.views import create_financial_user
from main_login.models import User, Role, FinancialDetails
from rest_framework import status

def test_create_financial_user():
    print("Testing create_financial_user endpoint...")
    
    factory = APIRequestFactory()
    
    # Test data matching frontend payload
    data = {
        'email': 'test_financial_final@example.com',
        'password': 'testpassword123',
        'name': 'Test Financial Final',
        'phone': '9876543210',
        'address': 'Test Address Final',
        'date_of_birth': '1995-01-01',
        'gender': 'Male',
        'school_id': 'TEST_SCHOOL_ID_FINAL'
    }
    
    # Clean up
    User.objects.filter(email=data['email']).delete()
    FinancialDetails.objects.filter(email=data['email']).delete()
    
    request = factory.post('/api/auth/create-financial-user/', data, format='json')
    
    # Create valid user for permission check without using broken create_superuser
    try:
        # Try to find an existing user first
        admin_user = User.objects.filter(is_superuser=True).first()
        if not admin_user:
             # Create manual user with is_superuser=True (supported by PermissionsMixin)
             admin_user = User(
                 email='admin_fix@example.com', 
                 username='admin_fix',
                 is_superuser=True,
                 is_active=True
             )
             admin_user.set_password('adminpass')
             admin_user.save()
    except Exception as e:
         print(f"Error getting/creating user: {e}")
         # Fallback to simple user
         admin_user = User(
             email='admin_fallback@example.com',
             username='admin_fallback',
             is_active=True
         )
         admin_user.set_password('pass')
         admin_user.save()

    # Authenticate
    force_authenticate(request, user=admin_user)
    
    try:
        response = create_financial_user(request)
        
        print(f"Response status: {response.status_code}")
        print(f"Response data: {response.data}")
        
        if response.status_code == 201:
            print("SUCCESS: Endpoint returned 201 Created")
            
            # Verify User
            user = User.objects.get(email=data['email'])
            print(f"User created: {user.email} (Role: {user.role.name if user.role else 'None'})")
            
            # Verify FinancialDetails
            fin_exists = FinancialDetails.objects.filter(email=data['email']).exists()
            print(f"FinancialDetails created: {fin_exists}")
            
            if fin_exists:
                fin = FinancialDetails.objects.get(email=data['email'])
                print(f"  Name: {fin.full_name}")
                print(f"  Phone: {fin.phone}")
                print(f"  School ID: {fin.school_id}")
                
            if user and fin_exists:
                print("VERIFICATION PASSED: Both User and FinancialDetails records created.")
            else:
                print("VERIFICATION FAILED: Missing records.")
        else:
            print("FAILURE: Endpoint did not return 201")
            
    except Exception as e:
        print(f"Exception calling view: {e}")
        import traceback
        traceback.print_exc()

test_create_financial_user()
