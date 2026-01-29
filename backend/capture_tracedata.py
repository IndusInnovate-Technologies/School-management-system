
import os
import django
import sys
import traceback

# Setup Django environment
sys.path.append(r'c:\Users\Admin\Desktop\testing_main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from student_parent.views import StudentProjectViewSet
from django.test import RequestFactory
from rest_framework.request import Request

User = get_user_model()
email = "harika.k@gmail.com"

with open("trace.log", "w") as f:
    try:
        user = User.objects.get(email=email)
        factory = RequestFactory()
        request = factory.get('/api/student-parent/projects/')
        request.user = user
        
        view = StudentProjectViewSet()
        view.request = Request(request)
        view.format_kwarg = None
        
        # Trigger the error
        view.get_queryset()
        
    except Exception:
        traceback.print_exc(file=f)
