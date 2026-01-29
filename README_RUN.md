# Running Backend and Frontend Together

This project includes a PowerShell script to run both the Django backend and Flutter frontend simultaneously.

## Prerequisites

1. **Python 3.14+** installed
2. **Flutter SDK** installed and in PATH
3. **PowerShell** (comes with Windows)

## Setup

The virtual environment has been created at `backend\venv` and dependencies are installed.

If you need to recreate the virtual environment:

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Usage
> [!IMPORTANT]
> If you encounter a "File cannot be loaded because running scripts is disabled on this system" error, run the script with the execution policy bypass flag:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\run_all.ps1
> ```

### Basic Usage (Run main_login app)

```powershell
.\run_all.ps1
```

This will:
- Start Django backend on `http://0.0.0.0:8000`
- Launch the `main_login` Flutter app in debug mode on Windows

### Run Different Flutter Apps

```powershell
# Run super_admin app
.\run_all.ps1 -App super_admin

# Run management_org app
.\run_all.ps1 -App management_org

# Run teacher_main_folder app
.\run_all.ps1 -App teacher_main_folder

# Run parent_main_folder app
.\run_all.ps1 -App parent_main_folder
```

### Run in Release Mode

```powershell
.\run_all.ps1 -Release
```

### Run on Different Devices

```powershell
# Run on Chrome browser
.\run_all.ps1 -Device chrome

# Run on Edge browser
.\run_all.ps1 -Device edge

# Run as web server
.\run_all.ps1 -Device web-server
```

### Combined Options

```powershell
# Run super_admin app in release mode on Chrome
.\run_all.ps1 -App super_admin -Release -Device chrome
```

## Available Apps

- `main_login` - Main login application (default)
- `super_admin` - Super Admin app
- `management_org` - Management Organization app
- `teacher_main_folder` - Teacher app
- `parent_main_folder` - Parent/Student app

## API Endpoints

Once the backend is running, you can access:

- **Django Admin**: http://127.0.0.1:8000/admin/
- **API Auth**: http://127.0.0.1:8000/api/auth/
- **Super Admin API**: http://127.0.0.1:8000/api/super-admin/
- **Management Admin API**: http://127.0.0.1:8000/api/management-admin/
- **Teacher API**: http://127.0.0.1:8000/api/teacher/
- **Student/Parent API**: http://127.0.0.1:8000/api/student-parent/

## Stopping

Press `Ctrl+C` in the terminal to stop both the Flutter app and Django backend.

The script will automatically:
1. Stop the Flutter app
2. Gracefully shutdown the Django backend
3. Clean up any processes

## Troubleshooting

### Virtualenv Not Found

If you get an error about virtualenv not found, the script will fall back to using system Python. Make sure Django and dependencies are installed globally, or create the virtualenv:

```powershell
cd backend
python -m venv venv
```

### Port Already in Use

If port 8000 is already in use, you can modify the script to use a different port, or stop the existing process:

```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Flutter Not Found

Make sure Flutter is installed and in your PATH:

```powershell
flutter --version
```

If not, add Flutter to your PATH or use the full path to `flutter.exe` in the script.

