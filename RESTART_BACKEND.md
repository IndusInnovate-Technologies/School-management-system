# How to Restart the Backend Server

The backend server needs to be restarted after code changes to pick up the updates.

## Quick Steps

1. **Stop the current server:**
   - If running via `run_all.ps1`, press `Ctrl+C` in the terminal
   - This will stop both frontend and backend

2. **Restart everything:**
   ```powershell
   .\run_all.ps1
   ```

## If Backend is Running Separately

If you started the backend manually:

1. **Find the process:**
   ```powershell
   netstat -ano | findstr :8000
   ```

2. **Kill the process:**
   ```powershell
   taskkill /PID <PID> /F
   ```
   (Replace `<PID>` with the actual process ID from step 1)

3. **Restart the backend:**
   ```powershell
   cd backend
   .\venv\Scripts\Activate.ps1
   python manage.py runserver
   ```

## Verify Backend is Running

Open in browser: http://localhost:8000/api/auth/routes/

You should see JSON response with route information.

## After Restart

The login should now work with:
- Email: `management@school.com`
- Password: `management123`
- Role: Management

