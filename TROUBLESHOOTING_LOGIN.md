# Troubleshooting Login Network Errors

If you're seeing a "Network error: Failed to fetch" when trying to log in, follow these steps:

## Step 1: Start the Backend Server

The backend Django server must be running for the login to work.

### Option A: Using the Run Script
```powershell
# From the project root
.\run.ps1
```

### Option B: Manual Start
```powershell
# Navigate to backend directory
cd backend

# Activate virtual environment (if using one)
.\venv\Scripts\Activate.ps1

# Start Django server
python manage.py runserver
```

The backend should be running on `http://localhost:8000` or `http://127.0.0.1:8000`

## Step 2: Verify Backend is Running

Open your browser and navigate to:
- http://localhost:8000/api/auth/routes/

You should see a JSON response with route information. If you get an error or "This site can't be reached", the backend is not running.

## Step 3: Check CORS Settings

The CORS settings have been updated to allow all origins in development mode. If you're still having issues:

1. Make sure `DEBUG = True` in `backend/school_backend/settings.py`
2. The CORS middleware should allow all origins when DEBUG is True

## Step 4: Verify Flutter Web Configuration

Make sure your Flutter web app is configured correctly:

1. The API base URL is set to `http://localhost:8000/api` in `frontend/core/lib/api/endpoints.dart`
2. If your backend is running on a different port, update the `baseUrl` in `endpoints.dart`

## Step 5: Check Browser Console

Open the browser's developer console (F12) and check for:
- CORS errors
- Network errors
- Any JavaScript errors

## Common Issues

### Issue: "Failed to fetch" or "Network error"
**Solution:** Backend server is not running. Start it using Step 1.

### Issue: CORS error in browser console
**Solution:** 
- Make sure `CORS_ALLOW_ALL_ORIGINS = True` is set in settings.py when DEBUG=True
- Restart the Django server after changing settings

### Issue: Backend running but still getting errors
**Solution:**
- Check that the endpoint `/api/auth/role-login/` exists (it should)
- Verify the backend is accessible at http://localhost:8000
- Check Django server logs for any errors

### Issue: Port already in use
**Solution:**
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

## Testing the Backend Directly

You can test the login endpoint directly using curl or Postman:

```bash
curl -X POST http://localhost:8000/api/auth/role-login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "management@school.com",
    "password": "management123",
    "role": "management"
  }'
```

Expected response:
```json
{
  "success": true,
  "user": {...},
  "tokens": {...},
  "message": "Login successful as management"
}
```

## Quick Checklist

- [ ] Backend server is running on port 8000
- [ ] Backend is accessible at http://localhost:8000
- [ ] CORS settings allow all origins (DEBUG mode)
- [ ] Flutter web app base URL is correct
- [ ] Dummy users have been created (run `python manage.py create_dummy_users`)
- [ ] No firewall blocking localhost connections

