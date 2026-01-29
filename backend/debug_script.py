from django.contrib.auth import get_user_model
from main_login.serializers import UserSerializer
from main_login.views import get_tokens_for_user
import json

User = get_user_model()
user = User.objects.get(email='sairam@mgmt.com')
print(f"Testing for user: {user.email}")

try:
    tokens = get_tokens_for_user(user)
    print("Tokens generated successfully")
except Exception as e:
    print(f"Tokens generation failed: {e}")

try:
    user_data = UserSerializer(user).data
    print("UserSerializer data retrieved successfully")
    print(json.dumps(user_data, indent=2, default=str))
except Exception as e:
    print(f"UserSerializer failed: {e}")
