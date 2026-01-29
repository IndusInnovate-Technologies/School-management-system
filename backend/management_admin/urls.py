"""
URLs for management_admin app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'management_admin'

router = DefaultRouter()
router.register(r'files', views.FileViewSet, basename='file')
router.register(r'departments', views.DepartmentViewSet, basename='department')
router.register(r'teachers', views.TeacherViewSet, basename='teacher')
router.register(r'students', views.StudentViewSet, basename='student')
router.register(r'admissions', views.NewAdmissionViewSet, basename='admission')
router.register(r'examinations', views.ExaminationManagementViewSet, basename='examination')
router.register(r'fees', views.FeeViewSet, basename='fee')
router.register(r'buses', views.BusViewSet, basename='bus')
router.register(r'bus-stops', views.BusStopViewSet, basename='busstop')
router.register(r'bus-stop-students', views.BusStopStudentViewSet, basename='busstopstudent')
router.register(r'schools', views.SchoolViewSet, basename='school')
router.register(r'events', views.EventViewSet, basename='event')
router.register(r'awards', views.AwardViewSet, basename='award')
router.register(r'campus-features', views.CampusFeatureViewSet, basename='campusfeature')
router.register(r'activities', views.ActivityViewSet, basename='activity')
router.register(r'financial-users', views.FinancialUserViewSet, basename='financial_user')
# router.register(r'notifications', views.NotificationViewSet, basename='notification')
# router.register(r'calendar', views.CalendarViewSet, basename='calendar')
# router.register(r'timetables', views.TimetableViewSet, basename='timetable')
router.register(r'galleries', views.GalleryViewSet, basename='gallery')

urlpatterns = [
    path('', include(router.urls)),
]

