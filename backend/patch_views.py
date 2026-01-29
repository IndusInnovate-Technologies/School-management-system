import re

# Read the file
with open(r'c:\Users\Admin\Desktop\Narasimha\backend\management_admin\views.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Check if already patched
if 'def get_serializer_class(self):' in content and 'FinancialUserViewSet' in content:
    print("Already patched!")
else:
    # Find the FinancialUserViewSet class and add methods
    pattern = r'(class FinancialUserViewSet.*?pagination_class = None\s+)(def get_queryset\(self\):)'
    
    replacement = r'''\1
    def get_serializer_class(self):
        """Use UserRegistrationSerializer for create action"""
        if self.action == 'create':
            from main_login.serializers import UserRegistrationSerializer
            return UserRegistrationSerializer
        return UserSerializer

    def perform_create(self, serializer):
        """Force role to be 'financial' and set school_id"""
        school_id = self.get_school_id()
        serializer.save(role='financial', school_id=school_id)
    
    \2'''
    
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    if new_content != content:
        # Write back
        with open(r'c:\Users\Admin\Desktop\Narasimha\backend\management_admin\views.py', 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Successfully patched!")
    else:
        print("Pattern not found!")
