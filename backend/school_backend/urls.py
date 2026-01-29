"""
URL configuration for school_backend project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Main Login - Authentication & JWT
    path('api/auth/', include('main_login.urls')),
    
    # API layers for each app
    path('api/super-admin/', include('super_admin.urls')),
    path('api/management-admin/', include('management_admin.urls')),
    path('api/teacher/', include('teacher.urls')),
    path('api/student-parent/', include('student_parent.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)


# Trigger reload
