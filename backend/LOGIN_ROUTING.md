# Login Routing and Backend Connections

This document explains how the backend handles role-based login routing and connections.

## Backend Endpoints

### 1. Get Role Routes
**Endpoint:** `GET /api/auth/routes/`

**Description:** Returns routing information for each role, including which login page to navigate to.

**Query Parameters:**
- `role` (optional): Specific role to get routes for. If omitted, returns all routes.

**Example Request:**
```
GET /api/auth/routes/?role=admin
```

**Example Response:**
```json
{
  "success": true,
  "role": "admin",
  "route": {
    "login_page": "/admin_login",
    "login_file": "admin_login.dart",
    "dashboard_route": "/super-admin/dashboard",
    "api_base": "/api/super-admin/"
  }
}
```

**All Routes Response:**
```json
{
  "success": true,
  "routes": {
    "admin": {
      "login_page": "/admin_login",
      "login_file": "admin_login.dart",
      "dashboard_route": "/super-admin/dashboard",
      "api_base": "/api/super-admin/"
    },
    "management": {
      "login_page": "/management_login",
      "login_file": "management_login.dart",
      "dashboard_route": "/management-admin/dashboard",
      "api_base": "/api/management-admin/"
    },
    "teacher": {
      "login_page": "/teacher_login",
      "login_file": "teacher_login.dart",
      "dashboard_route": "/teacher/dashboard",
      "api_base": "/api/teacher/"
    },
    "parent": {
      "login_page": "/parent_login",
      "login_file": "parent_login.dart",
      "dashboard_route": "/student-parent/dashboard",
      "api_base": "/api/student-parent/"
    }
  }
}
```

### 2. Role-Based Login
**Endpoint:** `POST /api/auth/role-login/`

**Description:** Authenticates a user and validates their role, returning routing information along with tokens.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "admin"
}
```

**Response (Success):**
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

**Response (Error - Wrong Role):**
```json
{
  "success": false,
  "message": "User does not have admin role. Current role: teacher"
}
```

**Response (Error - Invalid Credentials):**
```json
{
  "success": false,
  "errors": {
    "email": ["Invalid email or password."]
  },
  "message": "Invalid credentials"
}
```

### 3. Standard Login
**Endpoint:** `POST /api/auth/login/`

**Description:** Standard login endpoint (works with or without role validation).

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "role": "admin"  // optional
}
```

## Role Mapping

The backend maps frontend role names to backend role names:

| Frontend Role | Backend Role | Login Page | API Base |
|--------------|-------------|------------|----------|
| `admin` | `super_admin` | `admin_login.dart` | `/api/super-admin/` |
| `management` | `management_admin` | `management_login.dart` | `/api/management-admin/` |
| `teacher` | `teacher` | `teacher_login.dart` | `/api/teacher/` |
| `parent` | `student_parent` | `parent_login.dart` | `/api/student-parent/` |

## Frontend Navigation Flow

1. User selects a role on `main_login.dart`
2. User clicks "Login with your [Role] credentials" button
3. Frontend navigates to the appropriate login page:
   - Admin → `AdminLoginPage` (admin_login.dart)
   - Management → `ManagementLoginPage` (management_login.dart)
   - Teacher → `TeacherLoginPage` (teacher_login.dart)
   - Parent → `ParentLoginPage` (parent_login.dart)

4. User enters credentials on the role-specific login page
5. Frontend calls `POST /api/auth/role-login/` with:
   - `email`
   - `password`
   - `role` (admin, management, teacher, or parent)

6. Backend validates:
   - Credentials are correct
   - User has the requested role
   - User account is active

7. Backend returns:
   - JWT tokens (access & refresh)
   - User data
   - Routing information for dashboard navigation

8. Frontend stores tokens and navigates to the appropriate dashboard

## Implementation Details

### Backend Files Modified:
- `backend/main_login/views.py` - Added `get_role_routes()` and `role_login()` functions
- `backend/main_login/urls.py` - Added routes for `/routes/` and `/role-login/`

### Frontend Files Modified:
- `frontend/main_login/lib/main_login.dart` - Added navigation logic to route to appropriate login pages

## Testing

### Test Role Routes Endpoint:
```bash
curl http://localhost:8000/api/auth/routes/?role=admin
```

### Test Role Login:
```bash
curl -X POST http://localhost:8000/api/auth/role-login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password123",
    "role": "admin"
  }'
```

## Security Notes

1. All authentication endpoints require valid credentials
2. Role validation ensures users can only login with their assigned role
3. JWT tokens are used for subsequent API requests
4. Tokens include user role information for authorization checks

