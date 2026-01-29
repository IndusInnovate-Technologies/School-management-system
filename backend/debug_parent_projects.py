"""
Debug script to test parent project API endpoint
"""
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from student_parent.views import StudentProjectViewSet
from rest_framework.test import APIRequestFactory
from rest_framework.request import Request

User = get_user_model()

# Get parent user
try:
    user = User.objects.get(email='harika.k@gmail.com')
    print(f"User found: {user.email}, Role: {user.role.name if user.role else 'No role'}")
    
    # Create a mock request with proper authentication
    factory = APIRequestFactory()
    request = factory.get('/api/student/projects/')
    
    # Force authenticate the request
    from rest_framework.test import force_authenticate
    force_authenticate(request, user=user)
    
    # Create viewset instance
    view = StudentProjectViewSet()
    view.request = request
    view.format_kwarg = None
    
    # Get queryset
    print("\n[1] Testing get_queryset()...")
    qs = view.get_queryset()
    print(f"QuerySet Count: {qs.count()}")
    
    if qs.count() > 0:
        print(f"Projects found: {qs.count()}")
        for proj in qs[:3]:
            print(f"  - Project ID: {proj.id}, Title: {proj.title}, Class: {proj.class_obj}")
    
    # Test serialization
    print("\n[2] Testing Serialization...")
    from test_minimal_serializer import MinimalProjectSerializer
    
    for obj in qs[:1]:
        print(f"Serializing Project ID: {obj.id}")
        print(f"  - Title: {obj.title}")
        
        try:
            print("  - Creating MINIMAL serializer...")
            s = MinimalProjectSerializer(obj)
            print("  - Serializer created successfully")
            
            print("  - Getting serializer data...")
            data = s.data
            print(f"  - Data: {data}")
            print("MINIMAL SERIALIZATION SUCCESS")
        except Exception as e:
            print(f"!!! MINIMAL SERIALIZATION FAILED !!! : {e}")
            import traceback
            traceback.print_exc()

except User.DoesNotExist:
    print("User not found")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()

print("\nDEBUG_END")
