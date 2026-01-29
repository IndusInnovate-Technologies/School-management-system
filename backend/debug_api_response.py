
import os
import django
import sys
import json
from django.test import RequestFactory
from rest_framework.request import Request

# Setup Django environment
sys.path.append(r'c:\Users\Admin\Desktop\testing_main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from student_parent.views import StudentProjectViewSet
from student_parent.serializers import StudentProjectViewSerializer

User = get_user_model()
email = "harika.k@gmail.com"

print("--- Debugging Full ViewSet Response ---")
try:
    user = User.objects.get(email=email)
    print(f"User: {user.email}")
    
    # Mock Request
    factory = RequestFactory()
    request = factory.get('/api/student-parent/projects/')
    request.user = user
    
    # Initialize ViewSet
    view = StudentProjectViewSet()
    view.request = Request(request)
    view.format_kwarg = None
    
    # 1. Test get_queryset (with Mixin logic manually applied if needed, or relying on view's get_queryset)
    # StudentProjectViewSet inherits SchoolFilterMixin, so full get_queryset should run both logics if super() is called correctly
    
    print("\n[1] Calling view.get_queryset()...")
    qs = view.get_queryset()
    print(f"QuerySet Count: {qs.count()}")
    
    if qs.exists():
        print(f"First Project: {qs.first().title}")
        print(f"School ID check: {qs.first().class_obj.school_id}")
    
    # 2. Test Serialization
    print("\n[2] Testing Serialization...")
    # serializer = StudentProjectViewSerializer(qs, many=True, context={'request': view.request})
    # data = serializer.data
    
    # 2. Test Serialization
    print("\n[2] Testing Serialization...")
    
    # IMPORT STUDENT SERIALIZER (which now doesn't inherit from ProjectSerializer)
    from student_parent.serializers import StudentProjectViewSerializer
    
    for obj in qs:
        print(f"Serializing Project ID: {obj.id} using StudentProjectViewSerializer")
        try:
             s = StudentProjectViewSerializer(obj, context={'request': view.request})
             print(f" - Fields: {s.fields}")
             print(f" - Data: {s.data}")
             print("STUDENT SERIALIZER SUCCESS")
        except Exception as e:
             print(f"!!! STUDENT SERIALIZER FAILED !!! : {e}")
             import traceback
             traceback.print_exc()

except Exception:
    import traceback
    traceback.print_exc()



except Exception:
    import traceback
    traceback.print_exc()


