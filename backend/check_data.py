
import os
import django
import sys

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'school_backend.settings')
django.setup()


try:
    with open('db_state.txt', 'w', encoding='utf-8') as f:
        f.write("--- USERS ---\n")
        from main_login.models import User
        for u in User.objects.all():
             f.write(f"User: {u.username}, ID: {u.pk}, Role: {u.role_name}\n")

        f.write("\n--- TEACHERS ---\n")
        from management_admin.models import Teacher
        from teacher.models import Class
        
        for t in Teacher.objects.all():
            user_str = t.user.username if t.user else "No User"
            f.write(f"Teacher: {t.first_name} {t.last_name}, User: {user_str}\n")
            f.write(f"  Is Class Teacher: {t.is_class_teacher}\n")
            f.write(f"  Class Assigned (String): {t.class_teacher_class}\n")
            
            # Check linked classes
            classes = Class.objects.filter(teacher=t)
            if classes.exists():
                f.write(f"  Linked 'Class' objects: {[c.name for c in classes]}\n")
            else:
                f.write("  Linked 'Class' objects: None\n")

        f.write("\n--- CLASSES ---\n")
        for c in Class.objects.all():
            teacher_str = f"{c.teacher.first_name}" if c.teacher else "None"
            f.write(f"Class: {c.name} {c.section}, Teacher: {teacher_str}\n")
except Exception as e:
    import traceback
    with open('db_state.txt', 'a', encoding='utf-8') as f:
        f.write(f"\nERROR: {str(e)}\n")
        f.write(traceback.format_exc())


