# Login to Dashboard Redirect Implementation

This document explains how the login flow redirects users to their role-specific dashboards after successful authentication.

## Flow Overview

1. User selects role on `main_login.dart`
2. User is navigated to role-specific login page
3. User enters credentials
4. Frontend calls backend API `/api/auth/role-login/`
5. Backend validates credentials and role
6. Backend returns JWT tokens and routing information
7. Frontend stores tokens and navigates to appropriate dashboard

## Backend Endpoint

### POST /api/auth/role-login/

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "admin"
}
```

**Success Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "username": "admin_user",
    "email": "admin@example.com",
    "role_name": "super_admin"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
  },
  "role": "admin",
  "routes": {
    "login_page": "/admin_login",
    "dashboard_route": "/super-admin/dashboard"
  },
  "message": "Login successful as admin"
}
```

## Frontend Implementation

### AuthService (frontend/core/lib/api/auth_service.dart)

The `AuthService` class handles all authentication requests:

```dart
final authService = AuthService();
final result = await authService.login(
  email: email,
  password: password,
  role: role,
);
```

**Returns:**
```dart
{
  'success': bool,
  'message': String,
  'user': Map<String, dynamic>?,
  'tokens': Map<String, dynamic>?,
  'routes': Map<String, dynamic>?,
}
```

### Role-to-Dashboard Mapping

| Role | Login Page | Dashboard App | Import Path |
|------|-----------|---------------|-------------|
| `admin` | `admin_login.dart` | `AdminDashboardApp` | `apps/super_admin/lib/main.dart` |
| `management` | `management_login.dart` | `SchoolManagementSystemApp` | `apps/management_org/lib/main.dart` |
| `teacher` | `teacher_login.dart` | `TeacherDashboardApp` | `apps/teacher_main_folder/lib/main.dart` |
| `parent` | `parent_login.dart` | `SchoolManagementSystemApp` | `apps/parent_main_folder/lib/main.dart` |

## Login Page Updates

All login pages have been updated to:

1. **Import AuthService:**
   ```dart
   import 'package:core/api/auth_service.dart';
   ```

2. **Import Dashboard App:**
   ```dart
   import '../../apps/[app_name]/lib/main.dart' as [alias];
   ```

3. **Call AuthService:**
   ```dart
   final authService = AuthService();
   final result = await authService.login(
     email: _emailController.text.trim(),
     password: _passwordController.text,
     role: 'admin', // or 'management', 'teacher', 'parent'
   );
   ```

4. **Navigate on Success:**
   ```dart
   if (result['success']) {
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(
         builder: (context) => const [DashboardApp](),
       ),
     );
   }
   ```

## Updated Files

### Backend:
- `backend/main_login/views.py` - Added `role_login()` function
- `backend/main_login/urls.py` - Added `/role-login/` endpoint

### Frontend Core:
- `frontend/core/lib/api/endpoints.dart` - Updated base URL and added `roleLogin` endpoint
- `frontend/core/lib/api/auth_service.dart` - Updated `login()` method to match backend response

### Frontend Login Pages:
- `frontend/main_login/lib/admin_login.dart` - Updated to use AuthService and navigate to AdminDashboardApp
- `frontend/main_login/lib/management_login.dart` - Updated to use AuthService and navigate to SchoolManagementSystemApp (management)
- `frontend/main_login/lib/teacher_login.dart` - Updated to use AuthService and navigate to TeacherDashboardApp
- `frontend/main_login/lib/parent_login.dart` - Updated to use AuthService and navigate to SchoolManagementSystemApp (parent)

## Token Storage

The JWT access token is automatically stored in `ApiService` when login is successful. This token is then used for all subsequent API requests via the `Authorization: Bearer <token>` header.

## Error Handling

If login fails, the user sees an error message via SnackBar:
- Red background for errors
- Green/purple background for success
- Error message from backend response

## Testing

1. Start Django backend: `python manage.py runserver`
2. Run Flutter app: `flutter run`
3. Select a role on main login screen
4. Enter credentials (create test users via Django admin first)
5. Verify redirect to correct dashboard after successful login

## Creating Test Users

To test the login flow, create users via Django admin:

1. Go to `http://localhost:8000/admin/`
2. Navigate to "Users" under "MAIN_LOGIN"
3. Create a new user with:
   - Email
   - Username
   - Password
   - Role (Super Admin, Management Admin, Teacher, or Student/Parent)

## Security Notes

- All authentication endpoints require valid credentials
- Role validation ensures users can only login with their assigned role
- JWT tokens expire after 1 hour (configurable in settings)
- Refresh tokens can be used to get new access tokens
- Tokens are stored in memory (consider using secure storage for production)

