# Dummy Credentials for Testing

This document contains all dummy credentials created by the `create_role_credentials` management command.

## How to Create Credentials

Run the following command to create dummy credentials:

```bash
python manage.py create_role_credentials --count 10
```

## Login Credentials

All users have the password: **123456**

### Super Admin Users (Role: admin)

1. **Email:** superadmin1@school.com  
   **Password:** 123456  
   **Role:** super_admin

2. **Email:** superadmin2@school.com  
   **Password:** 123456  
   **Role:** super_admin

### Management Admin Users (Role: management)

1. **Email:** management1@school.com  
   **Password:** 123456  
   **Role:** management_admin

2. **Email:** management2@school.com  
   **Password:** 123456  
   **Role:** management_admin

### Teacher Users (Role: teacher)

1. **Email:** teacher1@school.com  
   **Password:** 123456  
   **Role:** teacher  
   **Employee No:** EMP001

2. **Email:** teacher2@school.com  
   **Password:** 123456  
   **Role:** teacher  
   **Employee No:** EMP002

3. **Email:** teacher3@school.com  
   **Password:** 123456  
   **Role:** teacher  
   **Employee No:** EMP003

### Student/Parent Users (Role: parent)

1. **Email:** student1@school.com  
   **Password:** 123456  
   **Role:** student_parent  
   **Admission No:** ADM-2024-001

2. **Email:** student2@school.com  
   **Password:** 123456  
   **Role:** student_parent  
   **Admission No:** ADM-2024-002

3. **Email:** student3@school.com  
   **Password:** 123456  
   **Role:** student_parent  
   **Admission No:** ADM-2024-003

## How to Login

Use the `/api/auth/role-login/` endpoint with the following request:

```json
{
  "email": "user@school.com",
  "password": "123456",
  "role": "admin"  // or "management", "teacher", "parent"
}
```

### Role Mapping

- **admin** → super_admin
- **management** → management_admin
- **teacher** → teacher
- **parent** → student_parent

## Database Links

- **Teachers** are linked to the `teachers` table with employee numbers
- **Students** are linked to the `students` table with admission numbers
- **Super Admin** and **Management Admin** users are only in the `users` table (no additional linked tables)

## Notes

- All users have `has_custom_password = True`, so they can login immediately
- All passwords are hashed using Django's password hashing system
- Users are linked to a default "Demo School"
- Teachers are linked to departments (Mathematics, Science, English, History, Computer Science)
- Students have admission numbers and are linked to classes

