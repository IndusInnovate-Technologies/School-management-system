from django.contrib.auth import authenticate

user = authenticate(username='admin@school.com', password='admin123')
print('authenticate returned ->', user)
if user:
    print('user.email:', user.email)
    print('user.is_active:', user.is_active)
    print('user.role:', user.role.name if user.role else None)
else:
    print('Authentication failed for admin@school.com')
