import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from teacher.views import ClassViewSet
from rest_framework.test import APIRequestFactory
from rest_framework.request import Request

User = get_user_model()

# Get the management user
user = User.objects.get(username='sairam')

# Create a mock request
factory = APIRequestFactory()
request = factory.get('/api/teacher/classes/')
request.user = user

# Create the viewset and get the response
viewset = ClassViewSet.as_view({'get': 'list'})
response = viewset(Request(request))

print(f"Response status: {response.status_code}")
print(f"Response data type: {type(response.data)}")
if hasattr(response, 'data'):
    if isinstance(response.data, dict):
        print(f"Response keys: {response.data.keys()}")
        if 'results' in response.data:
            print(f"Number of results: {len(response.data['results'])}")
            if response.data['results']:
                print(f"First result: {response.data['results'][0]}")
    elif isinstance(response.data, list):
        print(f"Number of items: {len(response.data)}")
        if response.data:
            print(f"First item: {response.data[0]}")
