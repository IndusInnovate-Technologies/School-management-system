"""
URLs for super_admin app
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'super_admin'

router = DefaultRouter()
router.register(r'schools', views.SchoolViewSet, basename='school')
router.register(r'activities', views.ActivityViewSet, basename='activity')
router.register(r'support-tickets', views.SupportTicketViewSet, basename='support-ticket')

urlpatterns = [
    path('', include(router.urls)),
]

