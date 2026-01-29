"""
Serializers for teacher app
"""
from rest_framework import serializers
from .models import (
    Class, ClassStudent, Attendance, Assignment,
    Exam, Grade, Timetable, StudyMaterial, Project, StudentProject, Task, Homework
)
from main_login.serializer_mixins import SchoolIdMixin
from management_admin.serializers import TeacherSerializer, StudentSerializer, DepartmentSerializer
from management_admin.models import Teacher

class ClassSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Class model"""
    teacher = TeacherSerializer(read_only=True)
    department = DepartmentSerializer(read_only=True)
    
    class Meta:
        model = Class
        fields = [
            'id', 'school_id', 'name', 'section', 'teacher', 'department',
            'academic_year', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ClassListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for Class list/dropdown - only essential fields"""
    
    class Meta:
        model = Class
        fields = ['id', 'name', 'section']
        read_only_fields = ['id']


class ClassStudentSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for ClassStudent model"""
    class_obj = ClassSerializer(read_only=True)
    student = StudentSerializer(read_only=True)
    
    class Meta:
        model = ClassStudent
        fields = ['id', 'school_id', 'class_obj', 'student', 'enrolled_date']


class AttendanceSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Attendance model"""
    class_obj = ClassSerializer(read_only=True)
    student = StudentSerializer(read_only=True)
    marked_by = TeacherSerializer(read_only=True)
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'school_id', 'class_obj', 'student', 'date', 'status',
            'marked_by', 'remarks', 'student_name', 'teacher_name', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class AssignmentSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Assignment model"""
    class_obj = ClassSerializer(read_only=True)
    teacher = TeacherSerializer(read_only=True)
    
    class Meta:
        model = Assignment
        fields = [
            'id', 'school_id', 'class_obj', 'teacher', 'title', 'description',
            'instructions', 'subject', 'assignment_type', 'total_marks',
            'due_date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ExamSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Exam model"""
    class_obj = ClassSerializer(read_only=True)
    teacher = TeacherSerializer(read_only=True)
    class_id = serializers.PrimaryKeyRelatedField(
        queryset=Class.objects.all(), source='class_obj', write_only=True
    )
    
    class Meta:
        model = Exam
        fields = [
            'id', 'school_id', 'class_obj', 'class_id', 'teacher', 'title', 
            'description', 'instructions', 'subject', 'exam_type', 
            'duration_minutes', 'room_no',
            'exam_date', 'total_marks', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
        
    def create(self, validated_data):
        # Auto-assign teacher
        user = self.context['request'].user
        try:
            teacher = Teacher.objects.get(user=user)
            validated_data['teacher'] = teacher
        except Teacher.DoesNotExist:
            raise serializers.ValidationError("Teacher profile not found for current user")
            
        return super().create(validated_data)


class GradeSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Grade model"""
    exam = ExamSerializer(read_only=True)
    student = StudentSerializer(read_only=True)
    
    class Meta:
        model = Grade
        fields = [
            'id', 'school_id', 'exam', 'student', 'marks_obtained',
            'remarks', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class TimetableSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Timetable model"""
    class_obj = ClassSerializer(read_only=True)
    class_id = serializers.PrimaryKeyRelatedField(
        queryset=Class.objects.all(), source='class_obj', write_only=True, required=False, allow_null=True
    )
    teacher = TeacherSerializer(read_only=True)
    teacher_id = serializers.PrimaryKeyRelatedField(
        queryset=Teacher.objects.all(), source='teacher', write_only=True
    )
    
    class Meta:
        model = Timetable
        fields = [
            'id', 'school_id', 'entry_type', 'class_obj', 'class_id', 'teacher', 'teacher_id',
            'day_of_week', 'start_time', 'end_time', 'subject', 'room', 'color',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']




class StudyMaterialSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for StudyMaterial model"""
    class_obj = ClassSerializer(read_only=True)
    teacher = TeacherSerializer(read_only=True)
    
    class Meta:
        model = StudyMaterial
        fields = [
            'id', 'school_id', 'class_obj', 'teacher', 'title', 'description',
            'file_url', 'file_path', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ProjectSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Project model"""
    id = serializers.IntegerField(read_only=True)
    school_id = serializers.CharField(read_only=True)
    teacher = TeacherSerializer(read_only=True)
    class_obj = serializers.PrimaryKeyRelatedField(queryset=Class.objects.all(), required=False, allow_null=True)
    
    class Meta:
        model = Project
        fields = [
            'id', 'school_id', 'class_obj', 'teacher', 'title', 'subject',
            'description', 'due_date', 'file', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_representation(self, instance):
        response = super().to_representation(instance)
        if instance.class_obj:
            response['class_obj'] = ClassSerializer(instance.class_obj).data
        else:
            response['class_obj'] = None
        return response


class StudentProjectSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for StudentProject model"""
    project = ProjectSerializer(read_only=True)
    student = StudentSerializer(read_only=True)
    
    class Meta:
        model = StudentProject
        fields = [
            'id', 'school_id', 'project', 'student', 'status', 'progress',
            'submission_date', 'grade', 'feedback'
        ]
        read_only_fields = ['id']


class TaskSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Task model"""
    teacher = TeacherSerializer(read_only=True)
    class_obj = serializers.PrimaryKeyRelatedField(queryset=Class.objects.all(), required=False, allow_null=True)
    
    class Meta:
        model = Task
        fields = [
            'id', 'school_id', 'class_obj', 'teacher', 'title', 'description',
            'category', 'priority', 'due_date', 'subject', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_representation(self, instance):
        response = super().to_representation(instance)
        if instance.class_obj:
            response['class_obj'] = ClassSerializer(instance.class_obj).data
        else:
            response['class_obj'] = None
        return response

class HomeworkSerializer(SchoolIdMixin, serializers.ModelSerializer):
    """Serializer for Homework model"""
    teacher = TeacherSerializer(read_only=True)
    class_id = serializers.PrimaryKeyRelatedField(
        queryset=Class.objects.all(), source='class_obj', write_only=True, required=False, allow_null=True
    )
    class_obj = ClassSerializer(read_only=True)
    
    class Meta:
        model = Homework
        fields = [
            'id', 'school_id', 'class_obj', 'class_id', 'teacher', 'title', 
            'subject', 'description', 'assigned_date', 'due_date', 
            'priority', 'is_completed', 'created_at', 'updated_at',
            'target_class', 'target_section'
        ]
        read_only_fields = ['id', 'school_id', 'teacher', 'created_at', 'updated_at']

    def to_representation(self, instance):
        response = super().to_representation(instance)
        if instance.class_obj:
            response['class_obj'] = ClassSerializer(instance.class_obj).data
        else:
            response['class_obj'] = None
        return response

    def create(self, validated_data):
        # Auto-assign teacher
        user = self.context['request'].user
        try:
            teacher = Teacher.objects.get(user=user)
            validated_data['teacher'] = teacher
        except Teacher.DoesNotExist:
            raise serializers.ValidationError("Teacher profile not found for current user")
            
        return super().create(validated_data)
