from django.urls import re_path
from .consumers import TeacherStudentChatConsumer

websocket_urlpatterns = [
    re_path(
        r'ws/teacher-student/(?P<room_id>[^/]+)/$', 
        TeacherStudentChatConsumer.as_asgi()
    ),
    re_path(
        r'ws/teacher-parent/(?P<room_id>[^/]+)/$', 
        TeacherStudentChatConsumer.as_asgi()
    ),
]