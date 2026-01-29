import os
import django
import json
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()

from teacher.models import Class
from teacher.serializers import ClassSerializer, ClassListSerializer

def measure_size():
    classes = Class.objects.all()
    count = classes.count()
    print(f"Total classes: {count}")

    # Heavy serializer
    heavy_data = ClassSerializer(classes, many=True).data
    heavy_json = json.dumps(heavy_data)
    heavy_size = sys.getsizeof(heavy_json)
    print(f"Heavy Serializer Size: {heavy_size} bytes ({heavy_size/1024:.2f} KB)")

    # Light serializer
    light_data = ClassListSerializer(classes, many=True).data
    light_json = json.dumps(light_data)
    light_size = sys.getsizeof(light_json)
    print(f"Light Serializer Size: {light_size} bytes ({light_size/1024:.2f} KB)")
    
    reduction = (1 - light_size/heavy_size) * 100
    print(f"Size Reduction: {reduction:.2f}%")

if __name__ == "__main__":
    measure_size()
