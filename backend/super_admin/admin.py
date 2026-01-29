"""
Admin configuration for super_admin app
"""
from django.contrib import admin
from .models import School, SchoolStats, Activity


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ['school_name', 'location', 'status', 'license_expiry', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['school_name', 'location']


@admin.register(SchoolStats)
class SchoolStatsAdmin(admin.ModelAdmin):
    list_display = ['school', 'total_students', 'total_teachers', 'total_revenue', 'updated_at']
    search_fields = ['school__school_name']


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['user', 'school', 'activity_type', 'created_at']
    list_filter = ['activity_type', 'created_at']
    search_fields = ['user__username', 'school__name', 'description']

