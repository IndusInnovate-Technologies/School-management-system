"""
Utility functions for school-based data isolation
"""
from super_admin.models import School


def get_user_school_id(user):
    """
    Get the school_id for a given user.
    
    For management_admin users: Get from School.user relationship (school_account)
    For teacher users: Get from Teacher -> Department -> School
    For student/parent users: Get from Student -> School or Parent -> Student -> School
    Also checks Parent.school_id directly for efficiency
    
    Returns:
        str: school_id if found, None otherwise
    """
    if not user or not user.is_authenticated:
        return None
        
    # First priority: check direct school_id field on User model if available
    if hasattr(user, 'school_id') and user.school_id:
        return user.school_id
    
    # Check if user is a management admin (has school_account)
    try:
        school = School.objects.filter(user=user).first()
        if school:
            return school.school_id
    except Exception:
        pass
    
    # Check if user is a teacher
    try:
        from management_admin.models import Teacher
        teacher = Teacher.objects.filter(user=user).first()
        if teacher:
            # First check if teacher has school_id directly (more reliable)
            if teacher.school_id:
                return teacher.school_id
            
            # Fallback: get from department's school
            if teacher.department and teacher.department.school:
                return teacher.department.school.school_id
    except Exception:
        pass
    
    # Check if user is a student
    try:
        from management_admin.models import Student
        student = Student.objects.filter(user=user).first()
        if student and student.school:
            return student.school.school_id
    except Exception:
        pass
    
    # Check if user is a parent (first check direct school_id field, then through students)
    try:
        from student_parent.models import Parent
        parent = Parent.objects.filter(user=user).first()
        if parent:
            # First, check if parent has school_id directly (more efficient)
            if parent.school_id:
                return parent.school_id
            
            # Fallback: get from first student's school
            if parent.students.exists():
                first_student = parent.students.first()
                if first_student and first_student.school:
                    return first_student.school.school_id
    except Exception:
        pass

    # Check if user is financial staff
    try:
        from main_login.models import FinancialDetails
        fin_details = FinancialDetails.objects.filter(email=user.email).first()
        if fin_details and fin_details.school_id:
            return fin_details.school_id
    except Exception:
        pass
    
    return None


def get_user_school(user):
    """
    Get the School object for a given user.
    
    Returns:
        School: School object if found, None otherwise
    """
    school_id = get_user_school_id(user)
    if school_id:
        try:
            return School.objects.get(school_id=school_id)
        except School.DoesNotExist:
            pass
    return None

