"""
Admin configuration for management_admin app
"""
from django.contrib import admin
from .models import (
    Department, Teacher, Student, DashboardStats, NewAdmission, 
    Examination_management, Fee, Award, AwardCertificate, 
    Activity, Event, Gallery, GalleryImage, Driver
)


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ['name', 'school', 'head', 'created_at']
    list_filter = ['school', 'created_at']
    search_fields = ['name', 'school__name', 'head__username']


@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ['employee_no', 'first_name', 'last_name', 'user', 'department', 'joining_date', 'is_active']
    list_filter = ['department', 'gender', 'is_active', 'joining_date']
    search_fields = ['employee_no', 'first_name', 'last_name', 'email', 'user__username', 'user__email']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['email', 'student_id', 'admission_number', 'student_name', 'parent_name', 'user', 'school', 'applying_class', 'gender', 'category', 'created_at']
    list_filter = ['school', 'gender', 'category', 'applying_class', 'created_at']
    search_fields = ['admission_number', 'student_name', 'email', 'parent_name', 'parent_phone', 'user__username', 'user__email', 'student_id']
    readonly_fields = ['email', 'created_at', 'updated_at']


@admin.register(NewAdmission)
class NewAdmissionAdmin(admin.ModelAdmin):
    list_display = ['student_name', 'parent_name', 'applying_class', 'status', 'created_at']
    list_filter = ['status', 'applying_class', 'category', 'gender']
    search_fields = ['student_name', 'parent_name', 'email', 'admission_number']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'created_at'


@admin.register(DashboardStats)
class DashboardStatsAdmin(admin.ModelAdmin):
    list_display = ['school', 'total_teachers', 'total_students', 'total_departments', 'updated_at']
    search_fields = ['school__name']


@admin.register(Examination_management)
class ExaminationManagementAdmin(admin.ModelAdmin):
    list_display = ['Exam_Title', 'Exam_Type', 'Exam_Date', 'Exam_Time', 'Exam_Status', 'Exam_Created_At']
    list_filter = ['Exam_Type', 'Exam_Status', 'Exam_Date']
    search_fields = ['Exam_Title', 'Exam_Description', 'Exam_Location']
    readonly_fields = ['Exam_Created_At', 'Exam_Updated_At']
    date_hierarchy = 'Exam_Date'


@admin.register(Fee)
class FeeAdmin(admin.ModelAdmin):
    list_display = ['student', 'fee_type', 'section', 'total_amount', 'frequency', 'due_date', 'status', 'paid_amount', 'due_amount', 'created_at']
    list_filter = ['fee_type', 'status', 'frequency', 'section', 'due_date']
    search_fields = ['student__student_name', 'description', 'fee_type', 'section']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'due_date'

@admin.register(Award)
class AwardAdmin(admin.ModelAdmin):
    list_display = ['title', 'recipient', 'category', 'date', 'level', 'team_id']
    list_filter = ['category', 'level', 'date']
    search_fields = ['title', 'recipient', 'student_ids', 'team_id']
    
    class AwardCertificateInline(admin.TabularInline):
        model = AwardCertificate
        extra = 0
    
    inlines = [AwardCertificateInline]

@admin.register(AwardCertificate)
class AwardCertificateAdmin(admin.ModelAdmin):
    list_display = ['award', 'student_id', 'created_at']
    search_fields = ['student_id', 'award__title']

@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['name', 'status', 'created_at']
    list_filter = ['status']
    search_fields = ['title']

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['name', 'start_datetime', 'end_datetime', 'location']
    list_filter = ['start_datetime']
    search_fields = ['name', 'location']

@admin.register(Gallery)
class GalleryAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'date']
    
    class GalleryImageInline(admin.TabularInline):
        model = GalleryImage
        extra = 0
    
    inlines = [GalleryImageInline]


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ['user', 'bus', 'employee_id', 'created_at']
    list_filter = ['bus']
    search_fields = ['user__email', 'user__username', 'employee_id']
    raw_id_fields = ['user', 'bus']
    readonly_fields = ['created_at', 'updated_at']