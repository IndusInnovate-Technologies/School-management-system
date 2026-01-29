"""
Views for teacher app - API layer for App 3
"""
from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
try:
    import pandas as pd
except ImportError:
    # Fallback for Python 3.14/Pandas 3.0 dev environment issues
    import logging
    logging.getLogger(__name__).warning("Pandas could not be imported. Excel features will be disabled.")
    pd = None
import openpyxl
from io import BytesIO
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser

# Combine models: Standard ones + Projects/Tasks from gudisa
from .models import (
    Class, ClassStudent, Attendance, Assignment,
    Exam, Grade, Timetable, StudyMaterial, Project, StudentProject, Task, Homework
)

# Combine serializers: ClassList from HEAD + Project serializers from gudisa
from .serializers import (
    ClassSerializer, ClassListSerializer, ClassStudentSerializer, AttendanceSerializer,
    AssignmentSerializer, ExamSerializer, GradeSerializer,
    TimetableSerializer, StudyMaterialSerializer,
    ProjectSerializer, StudentProjectSerializer, TaskSerializer, HomeworkSerializer
)

from main_login.permissions import IsTeacher, IsAdminOrTeacher
from main_login.mixins import SchoolFilterMixin
from management_admin.models import Teacher, Student
from management_admin.serializers import TeacherSerializer
from student_parent.models import Communication
from student_parent.serializers import CommunicationSerializer
from django.db.models import Q


class ClassViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Class management"""
    queryset = Class.objects.all()
    serializer_class = ClassSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['teacher', 'department', 'academic_year']
    search_fields = ['name', 'section']
    ordering_fields = ['name', 'created_at']
    ordering = ['-created_at']
    pagination_class = None # Show all classes for dropdowns

    
    def get_queryset(self):
        """Filter classes by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
             # Return all classes for the school, not just assigned classes
            if teacher.school_id:
                return Class.objects.filter(school_id=teacher.school_id)
            return Class.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return Class.objects.none()
        """Filter classes by current teacher or school_id"""
        return Class.objects.all()


class ClassStudentViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for ClassStudent management"""
    queryset = ClassStudent.objects.all()
    serializer_class = ClassStudentSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['class_obj', 'student']
    
    def get_queryset(self):
        # Force reload
        """Filter class students by teacher's school"""
        queryset = super().get_queryset()
        
        # Get school_id for current teacher
        school_id = self.get_school_id()
        
        if school_id:
            # Filter by school_id (ClassStudent has school_id field)
            queryset = queryset.filter(school_id=school_id)
        else:
            # If no school_id, try to filter by teacher's classes
            try:
                teacher = Teacher.objects.get(user=self.request.user)
                if teacher:
                    # Get classes for this teacher and filter students in those classes
                    class_ids = Class.objects.filter(teacher=teacher).values_list('id', flat=True)
                    queryset = queryset.filter(class_obj_id__in=class_ids)
            except Teacher.DoesNotExist:
                queryset = queryset.none()
        
        return queryset


class AttendanceViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Attendance management"""
    queryset = Attendance.objects.all()
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'student', 'date', 'status']
    ordering_fields = ['date', 'created_at']
    ordering = ['-date']

    @action(detail=False, methods=['get'])
    def get_students_for_attendance(self, request):
        """
        Get students for a specific class and section for attendance marking.
        Query params: class_name, section, date (optional)
        """
        class_name = request.query_params.get('class_name', '').strip()
        section = request.query_params.get('section', '').strip()
        date_str = request.query_params.get('date')
        
        # 1. Get Teacher Profile FIRST to check permissions
        user = request.user
        teacher = Teacher.objects.filter(user=user).first()
        if not teacher:
            return Response({'error': 'Teacher profile not found'}, status=status.HTTP_404_NOT_FOUND)

        # 2. Enforce Assignment for Class Teachers
        # If teacher is assigned a specific class/section, VALIDATE they are requesting it.
        # Don't silently switch it, as that confuses the user if they selected Class 6.
        if teacher.is_class_teacher and teacher.class_teacher_class and teacher.class_teacher_section:
            assigned_class = teacher.class_teacher_class
            assigned_section = teacher.class_teacher_section
            
            # If params are provided, check if they match
            if class_name and class_name != assigned_class:
                return Response(
                    {'error': f'You are only authorized to view {assigned_class} - {assigned_section}'},
                    status=status.HTTP_403_FORBIDDEN
                )
            if section and section != assigned_section:
                return Response(
                    {'error': f'You are only authorized to view {assigned_class} - {assigned_section}'},
                    status=status.HTTP_403_FORBIDDEN 
                )
                
            # If params missing, default to assigned (convenience)
            if not class_name: class_name = assigned_class
            if not section: section = assigned_section
        
        # 3. Check if we have valid params
        if not class_name or not section:
            return Response(
                {'error': 'class_name and section are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            # Find or create the class
            # Find or create the class
            # Modified to handle MultipleObjectsReturned by being more specific and using filter()
            current_academic_year = '2025-2026'
            
            # Search for existing class with school context
            classes_query = Class.objects.filter(
                name=class_name,
                section=section
            )
            
            # Filter by school to avoid cross-school conflicts
            if teacher.school_id:
                classes_query = classes_query.filter(school_id=teacher.school_id)
            
            # Filter by academic year
            classes_query = classes_query.filter(academic_year=current_academic_year)
            
            if classes_query.exists():
                # If multiple found (e.g. data consistency issue), confidently pick the first one
                class_obj = classes_query.first()
                if classes_query.count() > 1:
                    print(f"DEBUG_ATTENDANCE: Warning - Found {classes_query.count()} classes for {class_name} {section} {current_academic_year}. Using first ID: {class_obj.id}")
            else:
                # Create if not found
                class_obj = Class.objects.create(
                    name=class_name,
                    section=section,
                    teacher=teacher,
                    academic_year=current_academic_year,
                    school_id=teacher.school_id,
                    school_name=teacher.school_name
                )
            
            # DEBUGGING LOGIC
            print(f"DEBUG_ATTENDANCE: Request for Class='{class_name}', Sec='{section}'")
            print(f"DEBUG_ATTENDANCE: Teacher SchoolID='{teacher.school_id}'")

            # 2. Fetch Students from Student model directly
            # Relaxed filtering to handle case sensitivity and formatting differences
            # Try to find ANY students in this class first
            all_class_students = Student.objects.filter(applying_class__iexact=class_name)
            
            # Fallback logic REMOVED for strict matching
            if not all_class_students.exists():
                print(f"DEBUG_ATTENDANCE: No students found for strict class match '{class_name}'")
            
            print(f"DEBUG_ATTENDANCE: Found {all_class_students.count()} students in class (before section/school filter)")
            
            # Print sample to see what data looks like
            if all_class_students.exists():
                s = all_class_students.first()
                print(f"DEBUG_ATTENDANCE: Sample Student - Name: {s.student_name}, Grade(field): '{s.section}', School: {s.school_id}")

            students = all_class_students
            
            # Apply section filter if provided
            if section:
                # FIRST: Try strict match
                # Check for "A", "Section A", "a"
                section_students = students.filter(
                    Q(section__iexact=section) | 
                    Q(section__iexact=f"Section {section}")
                ).distinct()
                
                print(f"DEBUG_ATTENDANCE: Filtering for section '{section}'")
                print(f"DEBUG_ATTENDANCE: Found {section_students.count()} strictly matching students.")
                
                # Update students queryset
                # If 0 found, we return 0. NO FALLBACKS.
                students = section_students

            # Filter by school if possible to avoid cross-school data leak
            if teacher.school_id:
                students = students.filter(school__school_id=teacher.school_id)
                print(f"DEBUG_ATTENDANCE: Count after School ID filter: {students.count()}")

            
            # 3. Fetch existing attendance for the date
            attendance_map = {}
            if date_str:
                attendances = Attendance.objects.filter(
                    class_obj=class_obj,
                    date=date_str
                )
                for att in attendances:
                    attendance_map[att.student_id] = {
                        'status': att.status,
                        'id': att.id,
                        'remarks': att.remarks
                    }
            
            # 4. Construct Response
            student_data = []
            for student in students:
                # Generate a roll number if not existing (UI needs it)
                roll_no = student.admission_number or f"ROLL-{student.pk}"
                
                att_info = attendance_map.get(str(student.pk), {}) # pk is email/string usually
                if not att_info:
                    # check integer id if pk is not matching
                    att_info = attendance_map.get(student.user_id, {})
                
                student_data.append({
                    'id': student.pk, # This is the email or primary key
                    'name': student.student_name,
                    'rollNo': roll_no,
                    'avatarInitials': "".join([n[0] for n in student.student_name.split()[:2]]).upper(),
                    'status': att_info.get('status', 'present'), # Default to present
                    'attendance_id': att_info.get('id'),
                    'remarks': att_info.get('remarks', '')
                })
                
            return Response({
                'class_id': class_obj.id,
                'students': student_data
            })
            
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error fetching students for attendance: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'])
    def bulk_save_attendance(self, request):
        """
        Bulk save attendance records.
        Body: {
            "class_id": 1,
            "date": "2025-01-08",
            "records": [
                {"student_id": "email@example.com", "status": "present"},
                ...
            ]
        }
        """
        class_id = request.data.get('class_id')
        date_str = request.data.get('date')
        records = request.data.get('records', [])
        
        if not class_id or not date_str:
            return Response({'error': 'class_id and date are required'}, status=status.HTTP_400_BAD_REQUEST)

        # Validate Date: Attendance can only be marked for TODAY
        try:
            from datetime import datetime
            request_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            today = timezone.now().date()
            if request_date != today:
                return Response(
                    {'error': f'Attendance can only be marked for today ({today}). You cannot mark for {request_date}.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except ValueError:
            return Response({'error': 'Invalid date format. Use YYYY-MM-DD'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            teacher = Teacher.objects.get(user=request.user)
            class_obj = Class.objects.get(id=class_id)
            
            created_count = 0
            updated_count = 0
            
            for record in records:
                student_id = record.get('student_id')
                status_val = record.get('status')
                
                # Verify student exists
                try:
                    student = Student.objects.get(pk=student_id)
                except Student.DoesNotExist:
                    continue
                
                # Update or Create
                obj, created = Attendance.objects.update_or_create(
                    class_obj=class_obj,
                    student=student,
                    date=date_str,
                    defaults={
                        'status': status_val,
                        'remarks': record.get('remarks', ''),
                        'student_name': student.student_name,
                        'teacher_name': f"{teacher.first_name} {teacher.last_name or ''}".strip() or teacher.employee_no,
                        'marked_by': teacher,
                        'school_id': teacher.school_id,
                        'school_name': teacher.school_name
                    }
                )
                
                if created:
                    created_count += 1
                else:
                    updated_count += 1
                    
            return Response({
                'message': 'Attendance saved successfully',
                'created': created_count,
                'updated': updated_count
            })
            
        except Class.DoesNotExist:
            return Response({'error': 'Class not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class AssignmentViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Assignment management"""
    queryset = Assignment.objects.all()
    serializer_class = AssignmentSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher']
    search_fields = ['title', 'description']
    ordering_fields = ['due_date', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter assignments by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
            return Assignment.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return Assignment.objects.none()


class ExamViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Exam management"""
    queryset = Exam.objects.all()
    serializer_class = ExamSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher']
    search_fields = ['title', 'description']
    ordering_fields = ['exam_date', 'created_at']
    ordering = ['-exam_date']
    
    def get_queryset(self):
        """Filter exams by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
            return Exam.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return Exam.objects.none()
            
    def perform_create(self, serializer):
        """Create exam and corresponding assignment"""
        exam = serializer.save()
        
        # Auto-create assignment for this exam
        try:
            # Ensure school info is present
            school_id = exam.school_id
            school_name = exam.school_name
            if not school_id and exam.class_obj and exam.class_obj.school_id:
                 school_id = exam.class_obj.school_id
                 school_name = exam.class_obj.school_name

            # Pack all data into description (single line as requested)
            desc_parts = []
            if exam.description:
                desc_parts.append(f"{exam.description}")
            if exam.instructions:
                desc_parts.append(f"Instructions: {exam.instructions}")
            if exam.exam_type:
                desc_parts.append(f"Type: {exam.exam_type}")
            if exam.duration_minutes:
                desc_parts.append(f"Duration: {exam.duration_minutes} min")
            if exam.total_marks:
                desc_parts.append(f"Marks: {exam.total_marks}")
            if exam.room_no:
                desc_parts.append(f"Room: {exam.room_no}")

            full_description = " | ".join(desc_parts)

            Assignment.objects.create(
                class_obj=exam.class_obj,
                teacher=exam.teacher,
                school_id=school_id,
                school_name=school_name,
                title=f"Exam: {exam.title}",
                description=full_description,
                due_date=exam.exam_date
            )
        except Exception as e:
            # Log error but don't fail the request if assignment creation fails
            print(f"Failed to auto-create assignment for exam {exam.id}: {e}")


class GradeViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Grade management"""
    queryset = Grade.objects.all()
    serializer_class = GradeSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['exam', 'student']
    ordering_fields = ['created_at']
    ordering = ['-created_at']


class TimetableViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Timetable management"""
    queryset = Timetable.objects.all()
    serializer_class = TimetableSerializer
    permission_classes = [IsAuthenticated, IsAdminOrTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher', 'day_of_week']
    search_fields = ['subject']
    ordering_fields = ['day_of_week', 'start_time']
    ordering = ['day_of_week', 'start_time']
    pagination_class = None  # Disable pagination to return all entries
    
    def get_queryset(self):
        """Filter timetables"""
        # Prepare optimized queryset
        # Start with base queryset (filters by school)
        queryset = super().get_queryset().select_related(
            'teacher', 'teacher__user', 'teacher__department',
            'class_obj', 'class_obj__department',
            'class_obj__teacher', 'class_obj__teacher__user', 'class_obj__teacher__department'
        )
        
        # Support filtering by teacher_id (useful for Management viewing a specific teacher)
        teacher_id = self.request.query_params.get('teacher_id')
        if teacher_id:
            return queryset.filter(teacher__employee_no=teacher_id)
            
        # Fallback: try to filter by current user as teacher
        try:
            teacher = Teacher.objects.get(user=self.request.user)
            return queryset.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            # If management/admin and didn't specify teacher, return the school-filtered queryset
            return queryset

    
    @action(detail=False, methods=['delete'], url_path='delete-by-teacher')
    def delete_by_teacher(self, request):
        """Delete all timetable entries for a specific teacher"""
        teacher_id = request.query_params.get('teacher_id')
        if not teacher_id:
            return Response({'error': 'teacher_id parameter required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Find teacher by employee_no
        try:
            teacher = Teacher.objects.get(employee_no=teacher_id)
        except Teacher.DoesNotExist:
            return Response({'error': f'Teacher {teacher_id} not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Delete all timetables for this teacher
        deleted_info = Timetable.objects.filter(teacher=teacher).delete()
        deleted_count = deleted_info[0] if deleted_info else 0
        
        return Response({
            'message': f'Deleted {deleted_count} timetable entries for teacher {teacher.first_name} {teacher.last_name}',
            'deleted_count': deleted_count
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'], url_path='delete-selected')
    def delete_selected(self, request):
        """Delete specific timetable entries by their IDs"""
        entry_ids = request.data.get('entry_ids', [])
        
        if not entry_ids:
            return Response({'error': 'entry_ids required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not isinstance(entry_ids, list):
            return Response({'error': 'entry_ids must be a list'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Delete the specified entries
        deleted_info = Timetable.objects.filter(id__in=entry_ids).delete()
        deleted_count = deleted_info[0] if deleted_info else 0
        
        return Response({
            'message': f'Deleted {deleted_count} timetable entries',
            'deleted_count': deleted_count
        }, status=status.HTTP_200_OK)




class StudyMaterialViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for StudyMaterial management"""
    queryset = StudyMaterial.objects.all()
    serializer_class = StudyMaterialSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter study materials by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
            return StudyMaterial.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return StudyMaterial.objects.none()


class ProjectViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Project management"""
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher', 'subject']
    search_fields = ['title', 'description']
    ordering_fields = ['due_date', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter projects by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
            return Project.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return Project.objects.none()

    def perform_create(self, serializer):
        """Auto-assign teacher on create"""
        try:
            # Use filter().first() to be safe against multiple objects (though unlikely)
            teacher = Teacher.objects.filter(user=self.request.user).first()
            if teacher:
                serializer.save(teacher=teacher)
            else:
                from rest_framework.exceptions import ValidationError
                raise ValidationError({"detail": "No Teacher profile found for this user."})
        except Exception as e:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({"detail": f"Failed to assign teacher: {str(e)}"})


class StudentProjectViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Student Project Status management"""
    queryset = StudentProject.objects.all()
    serializer_class = StudentProjectSerializer
    permission_classes = [IsAuthenticated] # Allow both teachers and students
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['project', 'student', 'status']
    
    def get_queryset(self):
        """Filter projects based on user role"""
        user = self.request.user
        
        # If student, return their own projects
        if hasattr(user, 'student_profile'):
            return StudentProject.objects.filter(student=user.student_profile)
            
        # If teacher, return projects for their classes
        if hasattr(user, 'teacher_profile'):
            return StudentProject.objects.filter(project__teacher=user.teacher_profile)
            
        return StudentProject.objects.none()


class TaskViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Task management"""
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated] # Allow both teachers and students
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher', 'category', 'priority']
    search_fields = ['title', 'description', 'subject']
    ordering_fields = ['due_date', 'created_at']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Filter tasks based on user role"""
        user = self.request.user
        
        # If student, return tasks for their class
        if hasattr(user, 'student_profile') and user.student_profile.current_class:
            return Task.objects.filter(class_obj=user.student_profile.current_class)
            
        # If teacher, return tasks created by them
        # Safe lookup for teacher
        teacher = Teacher.objects.filter(user=user).first()
        if teacher:
            return Task.objects.filter(teacher=teacher)
            
        return Task.objects.none()

    def perform_create(self, serializer):
        """Auto-assign teacher on create"""
        try:
            teacher = Teacher.objects.filter(user=self.request.user).first()
            if teacher:
                serializer.save(teacher=teacher)
            else:
                from rest_framework.exceptions import ValidationError
                raise ValidationError({"detail": "No Teacher profile found for this user."})
        except Exception as e:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({"detail": f"Failed to assign teacher: {str(e)}"})


class HomeworkViewSet(SchoolFilterMixin, viewsets.ModelViewSet):
    """ViewSet for Homework management"""
    queryset = Homework.objects.all()
    serializer_class = HomeworkSerializer
    permission_classes = [IsAuthenticated, IsTeacher]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['class_obj', 'teacher', 'priority', 'is_completed']
    search_fields = ['title', 'description', 'subject']
    ordering_fields = ['due_date', 'assigned_date', 'created_at']
    ordering = ['-assigned_date', '-created_at']
    
    def get_queryset(self):
        """Filter homework by current teacher"""
        user = self.request.user
        try:
            teacher = Teacher.objects.get(user=user)
            return Homework.objects.filter(teacher=teacher)
        except Teacher.DoesNotExist:
            return Homework.objects.none()

    def create(self, request, *args, **kwargs):
        """
        Override create to handle unassigned classes.
        """
        data = request.data.copy()
        
        # Handle priority case (just in case frontend sends Title Case)
        if 'priority' in data:
            data['priority'] = data['priority'].lower()

        # Handle unassigned classes (class_id missing or null)
        class_id_val = data.get('class_id')
        if (not class_id_val or class_id_val == 'null' or class_id_val == None) and data.get('target_class') and data.get('target_section'):
            try:
                teacher = Teacher.objects.filter(user=request.user).first()
                if teacher:
                    class_name = data.get('target_class')
                    section = data.get('target_section')
                    
                    # Search for existing class
                    classes = Class.objects.filter(name__iexact=class_name, section__iexact=section)
                    if teacher.school_id:
                        classes = classes.filter(school_id=teacher.school_id)
                    
                    target_class_obj = classes.order_by('-created_at').first()
                    
                    if not target_class_obj:
                        # Create the class on the fly if it doesn't exist
                        school_name_val = None
                        if teacher.department and teacher.department.school:
                            school_name_val = teacher.department.school.school_name
                        elif hasattr(teacher, 'school') and teacher.school:
                            school_name_val = teacher.school.school_name

                        target_class_obj = Class.objects.create(
                            name=class_name,
                            section=section,
                            teacher=teacher,
                            school_id=teacher.school_id,
                            school_name=school_name_val,
                            academic_year='2025-2026' 
                        )
                        print(f"DEBUG: Created new class {class_name}-{section} for Homework")
                    
                    if target_class_obj:
                        data['class_id'] = target_class_obj.id
                        # Also sync target_class/section fields for redundancy
                        data['target_class'] = target_class_obj.name
                        data['target_section'] = target_class_obj.section

            except Exception as e:
                import traceback
                print(f"CRITICAL ERROR in Homework Class Resolution: {e}")
                traceback.print_exc()

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        """Auto-assign teacher on create"""
        try:
            teacher = Teacher.objects.filter(user=self.request.user).first()
            if teacher:
                serializer.save(teacher=teacher)
            else:
                from rest_framework.exceptions import ValidationError
                raise ValidationError({"detail": "No Teacher profile found for this user."})
        except Exception as e:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({"detail": f"Failed to assign teacher: {str(e)}"})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def teacher_profile(request):
    """Get current logged-in teacher's profile"""
    # First try to find by user relationship (use first() since ForeignKey allows multiple)
    teacher = Teacher.objects.filter(user=request.user).first()
    
    if teacher:
        serializer = TeacherSerializer(teacher, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    # If not found by user, try to find by email
    if request.user.email:
        teacher = Teacher.objects.filter(email=request.user.email).first()
        if teacher:
            # Auto-link the user if not already linked
            if not teacher.user:
                teacher.user = request.user
                teacher.save()
            serializer = TeacherSerializer(teacher, context={'request': request})
            return Response(serializer.data, status=status.HTTP_200_OK)
    
    return Response(
        {'error': 'Teacher profile not found for this user'},
        status=status.HTTP_404_NOT_FOUND
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def teacher_communications(request):
    """Get all communications for the current teacher"""
    # Get communications where teacher is sender or recipient
    communications = Communication.objects.filter(
        Q(sender=request.user) | Q(recipient=request.user)
    ).order_by('-created_at')
    
    serializer = CommunicationSerializer(communications, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def teacher_chat_history(request):
    """Get chat history with a specific user"""
    user_id = request.query_params.get('user_id')
    if not user_id:
        return Response(
            {'error': 'user_id parameter is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        from main_login.models import User
        import uuid
        
        # Try to parse as UUID first
        try:
            uuid_obj = uuid.UUID(user_id)
            other_user = User.objects.get(user_id=uuid_obj)
        except (ValueError, User.DoesNotExist):
            # If not a valid UUID, try to find by email or username
            other_user = User.objects.filter(
                Q(email=user_id) | Q(username=user_id)
            ).first()
            
            if not other_user:
                return Response(
                    {'error': 'User not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f'Error finding user for chat history: {str(e)}')
        return Response(
            {'error': f'Error finding user: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    # Get messages where current user is sender or recipient
    messages = Communication.objects.filter(
        (Q(sender=request.user) & Q(recipient=other_user)) |
        (Q(sender=other_user) & Q(recipient=request.user))
    ).order_by('created_at')
    
    serializer = CommunicationSerializer(messages, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def school_details(request):
    """Get school details including logo for the current teacher"""
    try:
        from super_admin.serializers import SchoolSerializer
        
        from main_login.utils import get_user_school
        school = get_user_school(request.user)
            
        if not school:
            return Response(
                {'error': 'School not found for this teacher'},
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Serialize school data with request context for absolute URLs
        serializer = SchoolSerializer(school, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f'Error fetching school details: {str(e)}')
@api_view(['GET'])
@permission_classes([IsAuthenticated, IsTeacher])
def dashboard_stats(request):
    """Get aggregated dashboard statistics for the teacher"""
    try:
        # Use filter().first() to match the pattern in ViewSets
        teacher = Teacher.objects.filter(user=request.user).first()
        if not teacher:
            return Response(
                {'error': 'Teacher profile not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # 1. Classes and Students
        classes = Class.objects.filter(teacher=teacher)
        total_classes = classes.count()
        
        # Get unique student count across all classes
        # ClassStudent -> student
        student_ids = ClassStudent.objects.filter(
            class_obj__in=classes
        ).values_list('student_id', flat=True).distinct()
        total_students = student_ids.count()
        
        # 2. Upcoming Exams (future dates)
        now = timezone.now()
        upcoming_exams = Exam.objects.filter(
            teacher=teacher,
            exam_date__gte=now
        ).count()
        
        # 3. Pending Assignments (due date in future)
        pending_assignments = Assignment.objects.filter(
            teacher=teacher,
            due_date__gte=now
        ).count()
        
        # 4. Total Results (Grades given)
        # Assuming simple count of grades created by this teacher? 
        # Or distinct exams graded? The mock said "Total Results". 
        # Let's count total grades marked.
        total_results = Grade.objects.filter(
            exam__teacher=teacher
        ).count()
        
        # 5. Attendance Rate (Last 30 days)
        thirty_days_ago = now.date() - timezone.timedelta(days=30)
        attendances = Attendance.objects.filter(
            class_obj__in=classes,
            date__gte=thirty_days_ago
        )
        total_recs = attendances.count()
        present_recs = attendances.filter(status='present').count()
        
        attendance_rate_str = "0%"
        if total_recs > 0:
            rate = (present_recs / total_recs) * 100
            attendance_rate_str = f"{round(rate, 1)}%"
            
        # 6. Class Breakdown for UI
        classes_data = []
        for cls in classes:
            # Count students in this class
            cnt = ClassStudent.objects.filter(class_obj=cls).count()
            # Get subject if possible - Class model behaves like subject-based class in some systems,
            # but here Class model has 'name' (e.g. 10A).
            # The mock had 'subjects' list. Here we assume the class itself covers generalized subjects?
            # Or maybe we fetch subjects from Timetable?
            # For MVP, let's just return the class name and student count.
            subjects = Timetable.objects.filter(class_obj=cls).values_list('subject', flat=True).distinct()
            
            classes_data.append({
                'name': f"{cls.name} - {cls.section}",
                'students': cnt,
                'subjects': list(subjects) if subjects else ['General']
            })
            
        # 7. Other metrics for mock parity
        total_attendance_records = Attendance.objects.filter(class_obj__in=classes).count()
        total_study_materials = StudyMaterial.objects.filter(teacher=teacher).count()
        total_communications = Communication.objects.filter(
            Q(sender=request.user) | Q(recipient=request.user)
        ).count()
        total_timetable = Timetable.objects.filter(teacher=teacher).count()
        
        # New metrics for Projects and Tasks
        total_projects = Project.objects.filter(teacher=teacher).count()
        total_tasks = Task.objects.filter(teacher=teacher).count()
        total_homework = Homework.objects.filter(teacher=teacher).count()
        
        data = {
            'totalStudents': total_students,
            'totalClasses': total_classes,
            'upcomingExams': upcoming_exams,
            'pendingAssignments': pending_assignments,
            'totalResults': total_results,
            'attendanceRate': attendance_rate_str,
            'avgGrade': 'B+', # Placeholder as grade calculation is complex
            'classes': classes_data,
            'totalAttendanceRecords': total_attendance_records,
            'totalStudyMaterials': total_study_materials,
            'totalGradesPending': 0, # Placeholder
            'totalCommunication': total_communications,
            'totalTimetableSlots': total_timetable,
            'projectsCount': total_projects,
            'tasksCount': total_tasks,
            'homeworkCount': total_homework
        }
        
        return Response(data, status=status.HTTP_200_OK)
        
    except Teacher.DoesNotExist:
        return Response(
            {'error': 'Teacher profile not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f'Error aggregating dashboard stats: {str(e)}')
        return Response(
            {'error': 'Failed to load dashboard stats'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

class TimetableTemplateView(APIView):
    """View to download Excel template for Timetable import"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        buffer = BytesIO()
        with pd.ExcelWriter(buffer, engine='openpyxl') as writer:
            # Instructions Sheet
            instructions = pd.DataFrame({
                'Field': ['day_of_week', 'start_time', 'end_time', 'subject', 'class_name', 'section', 'room', 'teacher_employee_no'],
                'Description': [
                    'Day names (e.g., Mon, Tue) - separate multiple with comma',
                    'Format: HH:MM AM/PM (12-hour)',
                    'Format: HH:MM AM/PM (12-hour)',
                    'Subject Name (e.g., Mathematics)',
                    'Exact Class Name (e.g., Class 10)',
                    'Exact Section (e.g., A)',
                    'Room Number (Optional)',
                    'Employee Number of the Teacher'
                ],
                'Required': ['Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'No', 'Yes']
            })
            instructions.to_excel(writer, sheet_name='Instructions', index=False)
            
            # Data Template Sheet
            columns = ['day_of_week', 'start_time', 'end_time', 'subject', 'class_name', 'section', 'room', 'teacher_employee_no']
            df = pd.DataFrame(columns=columns)
            # Add sample row
            sample = pd.DataFrame([{
                'day_of_week': 'Mon, Wed, Fri',
                'start_time': '09:00 AM',
                'end_time': '10:00 AM',
                'subject': 'Mathematics',
                'class_name': 'Class 10',
                'section': 'A',
                'room': '101',
                'teacher_employee_no': 'EMP001'
            }])
            df = pd.concat([df, sample], ignore_index=True)
            df.to_excel(writer, sheet_name='Timetable_Data', index=False)
            
        buffer.seek(0)
        from django.http import HttpResponse
        response = HttpResponse(buffer.read(), content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        response['Content-Disposition'] = 'attachment; filename=timetable_template.xlsx'
        return response

class TimetableImportView(APIView):
    """View to import Timetable from Excel"""
    permission_classes = [IsAuthenticated]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser]
    
    def post(self, request):
        import logging
        logger = logging.getLogger(__name__)
        logger.error('DEBUG: Timetable Import POST started')
        
        file = request.FILES.get('file')
        if not file:
            logger.error('DEBUG: No file uploaded')
            return Response({'error': 'No file uploaded'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            df = pd.read_excel(file, sheet_name='Timetable_Data')
            logger.error(f'DEBUG: DataFrame read. Rows: {len(df)}')
            
            created_count = 0
            updated_count = 0
            errors = []
            
            # refined day mapping
            DAYS_MAP = {
                'mon': 0, 'monday': 0,
                'tue': 1, 'tuesday': 1,
                'wed': 2, 'wednesday': 2,
                'thu': 3, 'thursday': 3, 'thur': 3,
                'fri': 4, 'friday': 4,
                'sat': 5, 'saturday': 5,
                'sun': 6, 'sunday': 6
            }
            
            # Determine which teacher's data we're importing
            # Case 1: Teacher importing their own data (logged in as teacher)
            # Case 2: Management admin importing for a specific teacher (teacher_id in query params)
            
            teacher_id_param = request.query_params.get('teacher_id')
            logger.error(f'DEBUG IMPORT: teacher_id parameter = {teacher_id_param}')
            
            if teacher_id_param:
                # Management admin is importing for a specific teacher
                allowed_teacher_id = teacher_id_param
                import_context = f"teacher {allowed_teacher_id}"
                logger.error(f'DEBUG IMPORT: Using teacher_id from parameter: {allowed_teacher_id}')
            else:
                # Teacher is importing their own data
                try:
                    logged_in_teacher = Teacher.objects.get(user=request.user)
                    allowed_teacher_id = logged_in_teacher.employee_no
                    import_context = "your own teacher ID"
                    logger.error(f'DEBUG IMPORT: Using logged-in teacher: {allowed_teacher_id}')
                except Teacher.DoesNotExist:
                    logger.error('DEBUG IMPORT: No teacher found for user')
                    return Response(
                        {'error': 'You must be logged in as a teacher or provide a teacher_id parameter'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            
            for index, row in df.iterrows():
                try:
                    # Validate mandatory fields
                    if pd.isna(row['class_name']) or pd.isna(row['section']):
                        errors.append(f"Row {index+2}: Missing Class or Section")
                        continue

                    # Find Teacher First (to get school_id context)
                    teacher = None
                    if not pd.isna(row['teacher_employee_no']):
                        teacher_employee_no = str(row['teacher_employee_no']).strip()
                        logger.error(f'DEBUG IMPORT Row {index+2}: Found teacher_employee_no in Excel: {teacher_employee_no}')
                        
                        # SECURITY CHECK: Ensure the teacher_id in Excel matches the allowed teacher
                        if teacher_employee_no != allowed_teacher_id:
                            error_msg = (
                                f"Row {index+2}: You can only import data for {import_context} ({allowed_teacher_id}). "
                                f"Found '{teacher_employee_no}' in the file."
                            )
                            logger.error(f'DEBUG IMPORT VALIDATION FAILED: {error_msg}')
                            errors.append(error_msg)
                            continue
                        
                        logger.error(f'DEBUG IMPORT Row {index+2}: Validation passed, teacher_id matches')
                        teacher = Teacher.objects.filter(employee_no=teacher_employee_no).first()
                        if not teacher:
                            errors.append(f"Row {index+2}: Teacher with ID '{teacher_employee_no}' not found")
                            continue
                    
                    if not teacher:
                         errors.append(f"Row {index+2}: Teacher is required")
                         continue

                    # Find Class matched to Teacher's School
                    class_name = str(row['class_name']).strip()
                    section = str(row['section']).strip()
                    
                    class_obj = Class.objects.filter(
                        name__iexact=class_name, 
                        section__iexact=section,
                        school_id=teacher.school_id
                    ).first()
                    
                    # Fallback: Try removing "Class " or "Grade " prefix
                    if not class_obj:
                        cleaned_name = class_name.lower().replace('class ', '').replace('grade ', '').strip()
                        class_obj = Class.objects.filter(
                            name__iexact=cleaned_name, 
                            section__iexact=section,
                            school_id=teacher.school_id
                        ).first()
                    
                    if not class_obj:
                        errors.append(f"Row {index+2}: Class '{row['class_name']} {row['section']}' not found in teacher's school ({teacher.school_id})")
                        continue
                    
                    # Parse Days (handle multiple comma-separated)
                    raw_days_str = str(row['day_of_week'])
                    days_to_create = []
                    
                    # check if integer or single digit string
                    if isinstance(row['day_of_week'], int) or (raw_days_str.isdigit() and len(raw_days_str) == 1):
                         days_to_create.append(int(row['day_of_week']))
                    else:
                        # Split by comma
                        raw_parts = [p.strip().lower() for p in raw_days_str.split(',')]
                        for part in raw_parts:
                            day_val = DAYS_MAP.get(part)
                            if day_val is not None:
                                days_to_create.append(day_val)
                            else:
                                # Try as int fallback for each part
                                try:
                                    d = int(part)
                                    if 0 <= d <= 6:
                                        days_to_create.append(d)
                                except:
                                    pass

                    if not days_to_create:
                        errors.append(f"Row {index+2}: Invalid day format '{row['day_of_week']}'. Use Mon, Tue (comma separated).")
                        continue

                    # Create or Update Timetable Entry for each day
                    for day_val in days_to_create:
                        try:
                            # Parse times once
                            start_time = pd.to_datetime(str(row['start_time'])).time()
                            end_time = pd.to_datetime(str(row['end_time'])).time()
                            
                            # CHECK FOR OVERLAPPING TIME RANGES
                            # Two time ranges overlap if:
                            # (start1 < end2) AND (end1 > start2)
                            # We need to check all existing entries for this teacher on this day
                            
                            overlapping_entries = Timetable.objects.filter(
                                teacher=teacher,
                                day_of_week=day_val
                            )
                            
                            logger.error(f'DEBUG IMPORT Row {index+2} Day {day_val}: Found {overlapping_entries.count()} existing entries to check for overlap')
                            
                            conflict_found = False
                            conflicting_entry = None
                            
                            for existing in overlapping_entries:
                                logger.error(f'DEBUG IMPORT: Checking overlap - Existing: {existing.start_time}-{existing.end_time}, New: {start_time}-{end_time}')
                                # Check if time ranges overlap
                                # New entry: start_time to end_time
                                # Existing: existing.start_time to existing.end_time
                                
                                # Convert to comparable format (datetime for comparison)
                                from datetime import datetime, date
                                
                                # Use a dummy date for time comparison
                                dummy_date = date(2000, 1, 1)
                                new_start = datetime.combine(dummy_date, start_time)
                                new_end = datetime.combine(dummy_date, end_time)
                                existing_start = datetime.combine(dummy_date, existing.start_time)
                                existing_end = datetime.combine(dummy_date, existing.end_time)
                                
                                # Check for overlap: (start1 < end2) AND (end1 > start2)
                                if (new_start < existing_end) and (new_end > existing_start):
                                    conflict_found = True
                                    conflicting_entry = existing
                                    logger.error(f'DEBUG IMPORT: OVERLAP DETECTED!')
                                    break
                            
                            if conflict_found:
                                # Time ranges overlap
                                error_msg = (
                                    f"Row {index+2}: Time conflict detected! "
                                    f"Teacher {teacher.employee_no} already has a timetable entry on day {day_val} "
                                    f"from {conflicting_entry.start_time} to {conflicting_entry.end_time} "
                                    f"({conflicting_entry.subject}, Class: {conflicting_entry.class_obj.name if conflicting_entry.class_obj else 'N/A'}). "
                                    f"This overlaps with the new entry ({start_time} to {end_time}). "
                                    f"Cannot import overlapping entry."
                                )
                                logger.error(f'DEBUG IMPORT TIME OVERLAP: {error_msg}')
                                errors.append(error_msg)
                                continue
                            
                            # No conflict, create new entry
                            Timetable.objects.create(
                                class_obj=class_obj,
                                teacher=teacher,
                                day_of_week=day_val,
                                start_time=start_time,
                                end_time=end_time,
                                subject=row['subject'],
                                room=str(row['room']) if not pd.isna(row['room']) else '',
                                school_id=teacher.school_id,
                                school_name=getattr(teacher.school, 'school_name', None) if hasattr(teacher, 'school') else None
                            )
                            created_count += 1
                            logger.error(f'DEBUG IMPORT Row {index+2}: Created new entry for day {day_val}')
                            
                        except Exception as entry_error:
                            logger.error(f"Error processing entry for row {index+2}: {entry_error}", exc_info=True)
                            errors.append(f"Row {index+2}: {str(entry_error)}")
                        
                except Exception as e:
                    import traceback
                    logger.error(f'Row Error: {e}', exc_info=True)
                    errors.append(f"Row {index+2}: {str(e)}")
            
            logger.error(f"DEBUG PROCESSED: Created {created_count}, Updated {updated_count}")
            if errors:
                logger.error(f"DEBUG IMPORT ERRORS: {errors}")

            return Response({
                'message': f'Imported {created_count + updated_count} entries ({created_count} created, {updated_count} updated)',
                'errors': errors
            }, status=status.HTTP_201_CREATED if (created_count + updated_count) > 0 else status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"DEBUG IMPORT ERROR: {e}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

