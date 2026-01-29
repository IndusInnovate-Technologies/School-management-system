# PostgreSQL Database Setup and Connection Guide

## ✅ Database Connection Status

Your PostgreSQL database is **successfully connected** and working!

- **Database Name**: `school_management_system_db`
- **Host**: `localhost`
- **Port**: `5432`
- **User**: `postgres`
- **Status**: ✅ Connected

## 📊 Current Database State

- **Users**: 6 users created
- **Roles**: 4 roles created
  - `super_admin`: 1 user
  - `management_admin`: 1 user
  - `teacher`: 2 users
  - `student_parent`: 2 users

## 🔐 Test Credentials

The following test users have been created:

### Super Admin
- **Email**: `admin@school.com`
- **Password**: `admin123`

### Management Admin
- **Email**: `management@school.com`
- **Password**: `management123`

### Teacher
- **Email**: `teacher@school.com`
- **Password**: `teacher123`

### Parent
- **Email**: `parent@school.com`
- **Password**: `parent123`

## 🧪 Testing Database Connection

### Method 1: Using the Test Script
```bash
cd backend
python test_db_connection.py
```

This will:
- Test PostgreSQL connection
- List all tables
- Show all users and roles
- Display database version

### Method 2: Using the API Endpoint
Once your Django server is running, you can test the connection via API:

```bash
# Start Django server
python manage.py runserver

# Test database connection (in another terminal)
curl http://localhost:8000/api/main-login/test-db/
```

Or visit in browser: `http://localhost:8000/api/main-login/test-db/`

### Method 3: Using Django Shell
```bash
cd backend
python manage.py shell
```

Then in the shell:
```python
from main_login.models import User, Role
from django.db import connection

# Test connection
with connection.cursor() as cursor:
    cursor.execute("SELECT version();")
    print(cursor.fetchone()[0])

# List users
for user in User.objects.all():
    print(f"{user.email} - {user.role.name if user.role else 'No Role'}")
```

## 🔧 Database Configuration

The database configuration is in `backend/school_backend/settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'school_management_system_db',
        'USER': 'postgres',
        'PASSWORD': '123456',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

## 📝 Creating New Users

### Option 1: Using Management Command (Recommended)
```bash
cd backend
python manage.py create_dummy_users
```

This creates test users for all roles.

### Option 2: Using Django Admin
1. Create a superuser:
   ```bash
   python manage.py createsuperuser
   ```
2. Start the server:
   ```bash
   python manage.py runserver
   ```
3. Visit: `http://localhost:8000/admin/`
4. Login and create users through the admin interface

### Option 3: Using API Registration Endpoint
```bash
POST http://localhost:8000/api/main-login/register/
Content-Type: application/json

{
    "email": "newuser@school.com",
    "username": "newuser",
    "password": "password123",
    "password2": "password123",
    "role": "teacher",
    "first_name": "New",
    "last_name": "User"
}
```

### Option 4: Using Python Script
If you created users directly in PostgreSQL, use the helper script:

```bash
cd backend
python create_user_from_postgres.py
```

Then in Python shell:
```python
from create_user_from_postgres import import_user_from_postgres

import_user_from_postgres(
    email='user@school.com',
    username='user',
    password='password123',
    role_name='teacher'
)
```

## ⚠️ Important Notes

1. **Password Hashing**: Django uses hashed passwords. If you created users directly in PostgreSQL with plain text passwords, Django won't be able to authenticate them. Use the Django methods above to create users properly.

2. **Role Names**: The role names must match exactly:
   - `super_admin`
   - `management_admin`
   - `teacher`
   - `student_parent`

3. **Email as Username**: The `User` model uses `email` as the `USERNAME_FIELD`, so authentication uses email, not username.

## 🔍 Troubleshooting

### Issue: "No users found in database"
**Solution**: Run migrations and create users:
```bash
python manage.py migrate
python manage.py create_dummy_users
```

### Issue: "Database connection failed"
**Solution**: 
1. Check if PostgreSQL is running
2. Verify database credentials in `settings.py`
3. Ensure database `school_management_system_db` exists
4. Check if `psycopg2-binary` is installed: `pip install psycopg2-binary`

### Issue: "Invalid credentials" when logging in
**Solution**:
1. Verify user exists: `python test_db_connection.py`
2. Check if password is correct
3. Ensure user is active (`is_active=True`)
4. Verify user has the correct role assigned

### Issue: "User does not have [role] role"
**Solution**: Assign the role to the user:
```python
from main_login.models import User, Role

user = User.objects.get(email='user@school.com')
role = Role.objects.get(name='teacher')
user.role = role
user.save()
```

## 📚 API Endpoints

### Test Database Connection
```
GET /api/main-login/test-db/
```
Returns database status and user list.

### Login
```
POST /api/main-login/login/
Content-Type: application/json

{
    "email": "admin@school.com",
    "password": "admin123"
}
```

### Role-Specific Login
```
POST /api/main-login/role-login/
Content-Type: application/json

{
    "email": "admin@school.com",
    "password": "admin123",
    "role": "admin"
}
```

## ✅ Verification Checklist

- [x] PostgreSQL installed and running
- [x] Database `school_management_system_db` created
- [x] Django connected to PostgreSQL
- [x] Migrations applied
- [x] Test users created
- [x] Database connection test script working
- [x] API test endpoint available

## 🚀 Next Steps

1. Test login with the credentials above
2. Verify API endpoints are working
3. Create additional users as needed
4. Configure your Flutter app to use the API endpoints

---

**Last Updated**: Database connection verified and users created successfully!

