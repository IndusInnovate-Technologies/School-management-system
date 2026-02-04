from django.urls import path
from . import views

app_name = 'driver'

urlpatterns = [
    path('route/', views.route, name='route'),
    path('stops/', views.stops_with_students, name='stops'),
    path('stops/<str:stop_id>/', views.stop_notes, name='stop_notes'),
    path('stops/<str:stop_id>/attendance/', views.save_attendance, name='save_attendance'),
    path('ride/start/', views.ride_start, name='ride_start'),
    path('ride/end/', views.ride_end, name='ride_end'),
]
