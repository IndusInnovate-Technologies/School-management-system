
import os
import django
from django.urls import reverse, get_resolver

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

print("--- Debugging URLs ---")
try:
    url = reverse('management_admin:gallery-list')
    print(f"Successfully resolved 'management_admin:gallery-list': {url}")
except Exception as e:
    print(f"Failed to resolve 'management_admin:gallery-list': {e}")

print("\n--- Listing management_admin urls ---")
resolver = get_resolver()
url_patterns = resolver.url_patterns

def print_urls(patterns, prefix=''):
    for pattern in patterns:
        if hasattr(pattern, 'url_patterns'):
            print_urls(pattern.url_patterns, prefix + pattern.pattern.regex.pattern)
        elif hasattr(pattern, 'name') and pattern.name:
            if 'management_admin' in prefix or (hasattr(pattern, 'app_name') and pattern.app_name == 'management_admin'):
                pass # it's hard to filter purely by app_name in recursive print depending on structure
            
            # Simple check if it looks like management api
            full_path = prefix + pattern.pattern.regex.pattern
            if 'management-admin' in full_path:
                print(f"{pattern.name}: {full_path}")

# Since the structure is complex, let's just look for management_admin in the resolver
for patterns in url_patterns:
    if hasattr(patterns, 'pattern') and 'management-admin' in str(patterns.pattern):
        print(f"Found management-admin include: {patterns}")
        if hasattr(patterns, 'url_patterns'):
            for p in patterns.url_patterns:
                if hasattr(p, 'name'):
                    print(f"  - {p.name} -> {p.pattern}")

