
# Runs the Django backend and Flutter frontend for Android.
# Usage: .\run_android.ps1 [-Release] [-App <app_name>] [-Device <device_id>]

param(
    [switch]$Release,
    [string]$Device = '', # Default to auto-detect
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
}
else {
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
Write-Host "Starting Django Backend + Flutter Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend: $backendPath" -ForegroundColor Green
Write-Host "Flutter App: $App ($flutterPath)" -ForegroundColor Green
if ($Device) { Write-Host "Device: $Device" -ForegroundColor Green }
Write-Host "Release Mode: $Release" -ForegroundColor Green
Write-Host ""

# Check configured ADB and Devices
# Also Check JAVA_HOME which is required for Gradle
if (-not $env:JAVA_HOME) {
    $possibleJava = "C:\Program Files\Android\Android Studio\jbr"
    if (Test-Path $possibleJava) {
        $env:JAVA_HOME = $possibleJava
        $env:PATH = "$possibleJava\bin;$env:PATH"
        Write-Host "Auto-configured JAVA_HOME: $possibleJava" -ForegroundColor Gray
    } else {
        Write-Warning "JAVA_HOME is not set and Android Studio JBR not found. Gradle build might fail."
    }
} else {
    Write-Host "JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
}

try {
    $adbVersion = adb version
    if (!$?) {
        Write-Warning "ADB not found in PATH. Ensure Android SDK Platform-Tools are installed and in PATH."
    } else {
        Write-Host "ADB detected." -ForegroundColor Gray
        
        # Check for connected devices
        $devices = adb devices | Select-String -Pattern "\tdevice$"
        if (-not $devices) {
             Write-Host "No connected Android devices found. Attempting to launch emulator..." -ForegroundColor Yellow
             
             Write-Host "No connected Android devices found. Attempting to launch emulator..." -ForegroundColor Yellow
             
             # Get available emulators
             # Note: We match "Pixel" or "android" to avoid issues with special bullet characters
             $emulatorsOutput = flutter emulators 2>&1 
             $emulators = $emulatorsOutput | Select-String "Pixel"
             
             if (-not $emulators) {
                 $emulators = $emulatorsOutput | Select-String "android"
             }
             
             if ($emulators) {
                 $emulatorId = $null
                 
                 # If user specified a device name that matches an emulator, use it
                 if ($Device) {
                     $match = $emulators | Select-String $Device | Select-Object -First 1
                     if ($match) {
                         # Parse ID: split by whitespace or bullet, take first non-empty token
                         $emulatorId = (-split $match)[0].Trim()
                         Write-Host "User selected emulator: $emulatorId" -ForegroundColor Cyan
                     }
                 }
                 
                 # Auto-detect if no specific emulator selected/found
                 if (-not $emulatorId) {
                     # Pick first available matching Pixel or just first one
                     $firstLine = $emulators | Select-Object -First 1
                     $emulatorId = (-split $firstLine)[0].Trim()
                     Write-Host "Auto-selected emulator: $emulatorId" -ForegroundColor Cyan
                 }
                 
                 Write-Host "Launching emulator: $emulatorId" -ForegroundColor Cyan
                 flutter emulators --launch $emulatorId | Out-Null
                 
                 Write-Host "Waiting for emulator to boot (this may take a minute)..." -ForegroundColor Yellow
                 
                 # Wait loop
                 $retries = 60
                 while ($retries -gt 0) {
                     Start-Sleep -Seconds 2
                     $d = adb devices | Select-String "\tdevice$"
                     if ($d) {
                         Write-Host "Emulator connected!" -ForegroundColor Green
                         break
                     }
                     $retries--
                     Write-Host "." -NoNewline
                 }
                 if ($retries -eq 0) {
                     Write-Warning "Emulator launch timed out. Continuing anyway..."
                 } else {
                     Write-Host ""
                 }
             } else {
                 Write-Warning "No emulators found via 'flutter emulators'. Found output:"
                 $emulatorsOutput | ForEach-Object { Write-Warning $_ }
                 Write-Warning "Please launch an emulator manually in Android Studio."
             }
        } else {
             Write-Host "Android device detected." -ForegroundColor Green
        }
    }
} catch {
    Write-Warning "ADB/Emulator check failed."
}

# Check if port 8000 is already in use (Backend)
Write-Host "Checking for processes using port 8000..." -ForegroundColor Cyan
try {
    $portOutput = netstat -ano | Select-String ":8000.*LISTENING"
    if ($portOutput) {
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
                $null = & taskkill /PID $portPid /F 2>&1
                Start-Sleep -Seconds 1
            }
        }
    }
}
catch {
    Write-Host "Could not check for existing processes on port 8000. Continuing..." -ForegroundColor Yellow
}

# Start Django backend with daphne
Write-Host "Starting Django backend with daphne (ASGI) on http://127.0.0.1:8000..." -ForegroundColor Cyan
$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList '-m', 'daphne', '-b', '127.0.0.1', '-p', '8000', 'school_backend.asgi:application' -WorkingDirectory $backendPath -NoNewWindow -PassThru

# Wait for backend to start
Start-Sleep -Seconds 3

if ($backendProcess.HasExited) {
    Write-Error "Django backend failed to start. Check for errors above."
}

Write-Host "Django backend started (PID: $($backendProcess.Id))" -ForegroundColor Green

# Setup ABD Reverse Port Forwarding
Write-Host ""
Write-Host "Setting up ADB reverse port forwarding (tcp:8000 -> tcp:8000)..." -ForegroundColor Cyan
try {
    # This allows the Android device to access the host's localhost:8000 via its own localhost:8000
    adb reverse tcp:8000 tcp:8000
    if ($?) {
        Write-Host "ADB reverse successful." -ForegroundColor Green
    } else {
        Write-Warning "ADB reverse command returned error code. Ensure a device is connected."
    }
} catch {
    Write-Warning "Failed strictly running adb reverse. Continuing, but app might not connect to backend."
}

# Launch Flutter app
Write-Host ""
Write-Host "Launching Flutter app: $App on Android..." -ForegroundColor Cyan
Push-Location $flutterPath

try {
    $flutterArgs = @('run')
    
    if ($Device) {
        $flutterArgs += '-d', $Device
    }
    
    if ($Release) {
        $flutterArgs += '--release'
        Write-Host "Running in RELEASE mode" -ForegroundColor Yellow
    }
    else {
        Write-Host "Running in DEBUG mode" -ForegroundColor Yellow
    }
    
    # Try to clean first if debug issues arise? No, keep it fast.
    
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
            $backendProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
            if (-not $backendProcess.HasExited) {
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
    
    # Optional: Remove adb reverse?
    # adb reverse --remove tcp:8000 
    
    Write-Host ""
    Write-Host "All processes stopped." -ForegroundColor Green
}
