
import os
import django
import sys

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from main_login.models import User

try:
    user = User.objects.get(username='tinku')
    user.set_password('123456')
    user.has_custom_password = True
    user.updated_password = '123456'
    user.save()
    print(f"Password for user '{user.username}' has been reset to: 123456")
except User.DoesNotExist:
    print("User 'tinku' not found.")
except Exception as e:
    print(f"Error: {e}")
