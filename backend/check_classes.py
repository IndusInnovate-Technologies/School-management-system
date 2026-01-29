import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Class
from super_admin.models import School

def list_classes():
    print(f"Total classes: {Class.objects.count()}")
    for cls in Class.objects.all().order_by('name', 'section'):
        print(f"Class: {cls.name}, Section: {cls.section}, School: {cls.school_id}")

if __name__ == "__main__":
    list_classes()
