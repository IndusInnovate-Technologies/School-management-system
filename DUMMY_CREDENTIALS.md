# Dummy Credentials for Testing

This document contains dummy user credentials for testing all login pages in the School Management System.

## How to Create/Update Dummy Users

Run the following command from the `backend` directory:

```bash
python manage.py create_dummy_users
```

This command will:
- Create all required roles if they don't exist
- Create dummy users for each role
- Set passwords for all users
- Update existing users if they already exist

## Login Credentials

### 🔴 Admin Login
**Role:** Super Admin  
**Email:** `admin@school.com`  
**Password:** `admin123`  
**Login Page:** `admin_login.dart`

---

### 🟠 Management Login
**Role:** Management Admin  
**Email:** `management@school.com`  
**Password:** `management123`  
**Login Page:** `management_login.dart`

---

### 🟡 Teacher Login
**Role:** Teacher  
**Email:** `teacher@school.com`  
**Password:** `teacher123`  
**Login Page:** `teacher_login.dart`

**Additional Teacher Account:**
- **Email:** `teacher2@school.com`
- **Password:** `teacher123`

---

### 🟢 Parent/Student Login
**Role:** Student/Parent  
**Email:** `parent@school.com`  
**Password:** `parent123`  
**Login Page:** `parent_login.dart`

**Additional Parent Account:**
- **Email:** `parent2@school.com`
- **Password:** `parent123`

---

## Quick Reference Table

| Role | Email | Password | Login Page |
|------|-------|----------|------------|
| Admin | `admin@school.com` | `admin123` | `admin_login.dart` |
| Management | `management@school.com` | `management123` | `management_login.dart` |
| Teacher | `teacher@school.com` | `teacher123` | `teacher_login.dart` |
| Parent | `parent@school.com` | `parent123` | `parent_login.dart` |

## Notes

- All users are created with `is_active=True` and `is_verified=True`
- Passwords are stored using Django's password hashing
- Users can be recreated/updated by running the management command again
- These are **test credentials only** - do not use in production!

## Testing

To test login functionality:

1. Start the backend server:
   ```bash
   cd backend
   python manage.py runserver
   ```

2. Start the Flutter app:
   ```bash
   cd frontend/main_login
   flutter run
   ```

3. Navigate to the appropriate login page and use the credentials above.

## Role Mapping

The frontend uses simplified role names that map to backend role names:

| Frontend Role | Backend Role Name |
|--------------|-------------------|
| `admin` | `super_admin` |
| `management` | `management_admin` |
| `teacher` | `teacher` |
| `parent` | `student_parent` |

