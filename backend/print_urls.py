
import os
import sys
import django

# Setup Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from django.urls import get_resolver

def print_urls(url_patterns, prefix=''):
    for pattern in url_patterns:
        if hasattr(pattern, 'url_patterns'):
            # It's an include
            new_prefix = prefix
            if hasattr(pattern, 'pattern'):
                new_prefix += str(pattern.pattern)
            print_urls(pattern.url_patterns, new_prefix)
        elif hasattr(pattern, 'pattern'):
            # It's a leaf
            print(f"{prefix}{pattern.pattern} -> {pattern.name}")

print("Dumping all URL patterns:")
resolver = get_resolver()
print_urls(resolver.url_patterns)
