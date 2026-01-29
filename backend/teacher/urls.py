"""
URLs for teacher app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'teacher'

router = DefaultRouter()
router.register(r'classes', views.ClassViewSet, basename='class')
router.register(r'class-students', views.ClassStudentViewSet, basename='classstudent')
router.register(r'attendance', views.AttendanceViewSet, basename='attendance')
router.register(r'assignments', views.AssignmentViewSet, basename='assignment')
router.register(r'exams', views.ExamViewSet, basename='exam')
router.register(r'grades', views.GradeViewSet, basename='grade')
router.register(r'timetable', views.TimetableViewSet, basename='timetable')
router.register(r'study-materials', views.StudyMaterialViewSet, basename='studymaterial')
router.register(r'projects', views.ProjectViewSet, basename='project')
router.register(r'student-projects', views.StudentProjectViewSet, basename='studentproject')
router.register(r'tasks', views.TaskViewSet, basename='task')
router.register(r'homework', views.HomeworkViewSet, basename='homework')

urlpatterns = [
    path('', include(router.urls)),
    path('profile/', views.teacher_profile, name='teacher-profile'),
    path('communications/', views.teacher_communications, name='teacher-communications'),
    path('chat-history/', views.teacher_chat_history, name='teacher-chat-history'),
    path('school-details/', views.school_details, name='school-details'),
    path('dashboard-stats/', views.dashboard_stats, name='dashboard-stats'),
    path('timetables/template/', views.TimetableTemplateView.as_view(), name='timetable-template'),
    path('timetables/import/', views.TimetableImportView.as_view(), name='timetable-import'),
]

