"""
Serializers for management_admin app
"""
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from .models import File, Department, Teacher, Student, DashboardStats, NewAdmission, Examination_management, Fee, PaymentHistory, Bus, BusStop, BusStopStudent, Event, Award, AwardCertificate, CampusFeature, Activity, Gallery, GalleryImage

from main_login.serializers import UserSerializer
from main_login.serializer_mixins import SchoolIdMixin
from main_login.utils import get_user_school_id
from super_admin.serializers import SchoolSerializer
from super_admin.models import School
