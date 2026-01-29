# Runs the Django backend and Flutter frontend together.
# Usage: .\run_all.ps1 [-Release] [-App <app_name>] [-Device <device>]

param(
    [switch]$Release,
    [ValidateSet('windows', 'chrome', 'edge', 'web-server')]
    [string]$Device = 'windows',
    [ValidateSet('main_login', 'super_admin', 'management_org', 'teacher_main_folder', 'parent_main_folder')]
    [string]$App = 'main_login'
)

$ErrorActionPreference = 'Stop'

# Determine project root relative to this script
$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'

# Determine Flutter app path
if ($App -eq 'main_login') {
    $flutterPath = Join-Path $projectRoot 'frontend\main_login'
} else {
    $flutterPath = Join-Path $projectRoot "frontend\apps\$App"
}

# Check for Python virtualenv
$pythonExe = Join-Path $projectRoot 'venv\Scripts\python.exe'
if (!(Test-Path $pythonExe)) {
    $pythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
    if (!(Test-Path $pythonExe)) {
        # Use system Python if no virtualenv found
        $pythonExe = 'python'
        Write-Host "No virtualenv found. Using system Python: $pythonExe" -ForegroundColor Yellow
    }
}

# Verify paths exist
if (!(Test-Path (Join-Path $backendPath 'manage.py'))) {
    Write-Error "Django manage.py not found at $backendPath"
}

if (!(Test-Path (Join-Path $flutterPath 'pubspec.yaml'))) {
    Write-Error "Flutter project (pubspec.yaml) not found at $flutterPath"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Django Backend + Flutter App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend: $backendPath" -ForegroundColor Green
Write-Host "Flutter App: $App ($flutterPath)" -ForegroundColor Green
Write-Host "Device: $Device" -ForegroundColor Green
Write-Host "Release Mode: $Release" -ForegroundColor Green
Write-Host ""

# Check if port 8000 is already in use and kill the process
Write-Host "Checking for processes using port 8000..." -ForegroundColor Cyan
try {
    $portOutput = netstat -ano | Select-String ":8000.*LISTENING"
    if ($portOutput) {
        # Extract PID from the last column (format: TCP    127.0.0.1:8000    0.0.0.0:0    LISTENING    12345)
        $pidString = ($portOutput -split '\s+')[-1]
        if ($pidString -match '^\d+$') {
            $portPid = [int]$pidString
            Write-Host "Found process $portPid using port 8000, terminating..." -ForegroundColor Yellow
            try {
                Stop-Process -Id $portPid -Force -ErrorAction Stop
                Start-Sleep -Seconds 1
                Write-Host "Process terminated successfully." -ForegroundColor Green
            }
            catch {
                Write-Host "Trying taskkill for process $portPid..." -ForegroundColor Yellow
                $null = & taskkill /PID $portPid /F 2>&1
                Start-Sleep -Seconds 1
            }
        }
    }
}
catch {
    # If checking fails, continue anyway
    Write-Host "Could not check for existing processes on port 8000. Continuing..." -ForegroundColor Yellow
}

# Start Django backend with daphne (ASGI) for WebSocket support
Write-Host "Starting Django backend with daphne (ASGI) on http://127.0.0.1:8000..." -ForegroundColor Cyan
$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList '-m', 'daphne', '-b', '127.0.0.1', '-p', '8000', 'school_backend.asgi:application' -WorkingDirectory $backendPath -NoNewWindow -PassThru

# Wait for backend to start
Start-Sleep -Seconds 3

# Check if backend started successfully
if ($backendProcess.HasExited) {
    Write-Error "Django backend failed to start. Check for errors above."
}

Write-Host "Django backend started (PID: $($backendProcess.Id))" -ForegroundColor Green

# Clean up stale Flutter processes for Windows
if ($Device -eq 'windows') {
    Write-Host "Cleaning up stale Flutter desktop processes..." -ForegroundColor Cyan
    Get-Process -Name 'flutter_app', 'main_login', 'super_admin', 'management_org', 'teacher_main_folder', 'parent_main_folder' -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Write-Host "Terminating process: $($_.Name) (PID: $($_.Id))" -ForegroundColor Yellow
            $_.Kill()
            $_.WaitForExit()
        }
        catch {
            Write-Warning "Failed to terminate process $($_.Name): $_"
        }
    }

    # Try to remove locked generated plugin file
    $generatedPluginFile = Join-Path $flutterPath 'windows\flutter\generated_plugin_registrant.h'
    if (Test-Path $generatedPluginFile) {
        try {
            Remove-Item $generatedPluginFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Could not remove locked file $generatedPluginFile. Continuing..."
        }
    }
}

# Launch Flutter app
Write-Host ""
Write-Host "Launching Flutter app: $App..." -ForegroundColor Cyan
Push-Location $flutterPath

try {
    $flutterArgs = @('run', '-d', $Device)
    
    if ($Release) {
        $flutterArgs += '--release'
        Write-Host "Running in RELEASE mode" -ForegroundColor Yellow
    }
    else {
        Write-Host "Running in DEBUG mode" -ForegroundColor Yellow
    }
    
    Write-Host "Flutter command: flutter $($flutterArgs -join ' ')" -ForegroundColor Gray
    Write-Host ""
    
    # Run Flutter
    flutter @flutterArgs
}
catch {
    Write-Error "Flutter app failed to start: $_"
}
finally {
    Pop-Location
    
    Write-Host ""
    Write-Host "Stopping Django backend..." -ForegroundColor Yellow
    
    if ($backendProcess -and -not $backendProcess.HasExited) {
        try {
            # Try graceful shutdown first
            $backendProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
            
            if (-not $backendProcess.HasExited) {
                Write-Host "Force killing backend process..." -ForegroundColor Yellow
                $backendProcess.Kill()
            }
        }
        catch {
            if (-not $backendProcess.HasExited) {
                $backendProcess.Kill()
            }
        }
        
        $backendProcess.WaitForExit()
        Write-Host "Django backend stopped." -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "All processes stopped." -ForegroundColor Green
}
