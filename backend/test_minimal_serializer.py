"""
Minimal test serializer
"""
from rest_framework import serializers
from teacher.models import Project

class MinimalProjectSerializer(serializers.ModelSerializer):
    """Absolutely minimal serializer"""
    
    class Meta:
        model = Project
        fields = ['id', 'title', 'subject']
        read_only_fields = ['id']
