"""
Admin configuration for teacher app
"""
from django.contrib import admin
from .models import (
    Class, ClassStudent, Attendance, Assignment,
    Exam, Grade, Timetable, StudyMaterial, Project, StudentProject, Task
)


@admin.register(Class)
class ClassAdmin(admin.ModelAdmin):
    list_display = ['name', 'section', 'teacher', 'department', 'academic_year', 'created_at']
    list_filter = ['department', 'academic_year', 'created_at']
    search_fields = ['name', 'section', 'teacher__user__username']


@admin.register(ClassStudent)
class ClassStudentAdmin(admin.ModelAdmin):
    list_display = ['class_obj', 'student', 'enrolled_date']
    list_filter = ['enrolled_date']
    search_fields = ['class_obj__name', 'student__user__username']


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['class_obj', 'student', 'date', 'status', 'marked_by', 'created_at']
    list_filter = ['status', 'date', 'created_at']
    search_fields = ['class_obj__name', 'student__user__username']


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = ['title', 'subject', 'assignment_type', 'class_obj', 'teacher', 'due_date', 'total_marks', 'created_at']
    list_filter = ['assignment_type', 'teacher', 'due_date', 'created_at']
    search_fields = ['title', 'description', 'instructions', 'subject']


@admin.register(Exam)
class ExamAdmin(admin.ModelAdmin):
    list_display = ['title', 'class_obj', 'teacher', 'exam_date', 'total_marks', 'created_at']
    list_filter = ['teacher', 'exam_date', 'created_at']
    search_fields = ['title', 'description']


@admin.register(Grade)
class GradeAdmin(admin.ModelAdmin):
    list_display = ['exam', 'student', 'marks_obtained', 'created_at']
    list_filter = ['exam', 'created_at']
    search_fields = ['student__user__username', 'remarks']


@admin.register(Timetable)
class TimetableAdmin(admin.ModelAdmin):
    list_display = ['class_obj', 'teacher', 'day_of_week', 'subject', 'start_time', 'end_time']
    list_filter = ['day_of_week', 'teacher', 'class_obj']
    search_fields = ['subject', 'class_obj__name']


@admin.register(StudyMaterial)
class StudyMaterialAdmin(admin.ModelAdmin):
    list_display = ['title', 'class_obj', 'teacher', 'created_at']
    list_filter = ['teacher', 'created_at']
    search_fields = ['title', 'description']


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ['title', 'class_obj', 'teacher', 'due_date', 'created_at']
    list_filter = ['teacher', 'due_date', 'created_at']
    search_fields = ['title', 'description']


@admin.register(StudentProject)
class StudentProjectAdmin(admin.ModelAdmin):
    list_display = ['project', 'student', 'status', 'progress', 'grade', 'submission_date']
    list_filter = ['status', 'submission_date']
    search_fields = ['student__user__username', 'project__title']


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'class_obj', 'teacher', 'category', 'priority', 'due_date']
    list_filter = ['category', 'priority', 'due_date', 'teacher']
    search_fields = ['title', 'description', 'subject']

