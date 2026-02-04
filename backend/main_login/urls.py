"""
URLs for main_login app
"""
from django.urls import path
from . import views

app_name = 'main_login'

urlpatterns = [
    # Authentication endpoints
    path('register/', views.register, name='register'),
    path('login/', views.login, name='login'),
    path('role-login/', views.role_login, name='role_login'),
    path('logout/', views.logout, name='logout'),
    path('refresh/', views.refresh_token, name='refresh_token'),
    
    # Routing endpoints
    path('routes/', views.get_role_routes, name='get_role_routes'),
    
    # Database test endpoint
    path('test-db/', views.test_db_connection, name='test_db_connection'),
    
    # User profile endpoints
    path('profile/', views.profile, name='profile'),
    path('profile/update/', views.update_profile, name='update_profile'),
    path('change-password/', views.change_password, name='change_password'),
    path('create-password/', views.create_password, name='create_password'),
    path('request-otp/', views.request_otp, name='request_otp'),
    path('reset-password-otp/', views.reset_password_with_otp, name='reset_password_with_otp'),
    path('create-financial-user/', views.create_financial_user, name='create_financial_user'),
    
    # Roles
    path('roles/', views.RoleListView.as_view(), name='roles_list'),

    # FCM push notification device registration
    path('fcm/register/', views.fcm_register, name='fcm_register'),
    path('fcm/unregister/', views.fcm_unregister, name='fcm_unregister'),

    # My push notifications (student/parent and teacher portals)
    path('my-push-notifications/', views.my_push_notifications, name='my_push_notifications'),
    path('my-push-notifications/mark-read/', views.my_push_notifications_mark_read, name='my_push_notifications_mark_read'),
]

