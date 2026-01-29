
import os
import sys

sys.path.append('C:\\Users\\Admin\\Desktop\\testing_main\\backend')

if 'DJANGO_SETTINGS_MODULE' not in os.environ:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
    import django
    try:
        django.setup()
    except Exception as e:
        print(f"Setup error: {e}")

from rest_framework.test import APIRequestFactory
from rest_framework.request import Request
from main_login.permissions import IsManagementAdmin, IsFinancial
from main_login.models import User, Role

def debug():
    with open('debug_output.txt', 'w') as f:
        sys.stdout = f
        
        print("\n--- Testing Permission Logic ---")
        
        # Setup User
        role, _ = Role.objects.get_or_create(name='financial')
        user = User(email='debug_fin@test.com', username='debug_fin', role=role)
        # mock save not needed for simple check if we attach role, but let's be safe
        # We won't save to DB to avoid constraints, just use the object
        
        # Create Request
        factory = APIRequestFactory()
        wsgi_request = factory.get('/')
        wsgi_request.user = user
        request = Request(wsgi_request)
        
        print(f"DEBUG: request.user: {request.user}")
        print(f"DEBUG: request.user.is_authenticated: {request.user.is_authenticated}")
        if request.user and request.user.is_authenticated:
             print(f"DEBUG: request.user.role: {request.user.role}")
             if request.user.role:
                 print(f"DEBUG: request.user.role.name: '{request.user.role.name}'")
                 print(f"DEBUG: Match? {request.user.role.name == 'financial'}")
        
        # Test IsFinancial
        fin_perm = IsFinancial()
        result_fin = fin_perm.has_permission(request, None)
        print(f"IsFinancial.has_permission: {result_fin}")
        
        # Test IsManagementAdmin
        mgr = IsManagementAdmin()
        result_mgr = mgr.has_permission(request, None)
        print(f"IsManagementAdmin.has_permission: {result_mgr}")
        
        # Test Combined
        combined = (IsManagementAdmin | IsFinancial)()
        try:
            result_combined = combined.has_permission(request, None)
            print(f"Combined.has_permission: {result_combined}")
            
            if result_combined and not result_fin:
                 print("STRANGE: Combined is True but IsFinancial is False?")
        except Exception as e:
            print(f"Combined ERROR: {e}")
        
        sys.stdout = sys.__stdout__

if __name__ == "__main__":
    debug()
