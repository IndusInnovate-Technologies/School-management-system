# Runs the Django backend and Flutter app on Android (device or emulator).
# Same as run_all.ps1 but targets Android: launches an emulator if none is running, then runs the app.
# Usage: .\run_android.ps1 [-Release] [-App <app_name>] [-Device <device_id>]
#
# Examples:
#   .\run_android.ps1
#   .\run_android.ps1 -App parent_main_folder
#   .\run_android.ps1 -Release -App management_org

param(
    [switch]$Release,
    [string]$Device = '',
    [ValidateSet('main_login', 'super_admin', 'management_org', 'teacher_main_folder', 'parent_main_folder')]
    [string]$App = 'main_login'
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'

if ($App -eq 'main_login') {
    $flutterPath = Join-Path $projectRoot 'frontend\main_login'
} else {
    $flutterPath = Join-Path $projectRoot "frontend\apps\$App"
}

# Ensure Android SDK platform-tools (adb) is on PATH
$adbInPath = $null -ne (Get-Command adb -ErrorAction SilentlyContinue)
if (-not $adbInPath) {
    $sdkPaths = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk'),
        (Join-Path $env:USERPROFILE 'AppData\Local\Android\Sdk')
    )
    foreach ($sdk in $sdkPaths) {
        if ($sdk -and (Test-Path $sdk)) {
            $platformTools = Join-Path $sdk 'platform-tools'
            if (Test-Path $platformTools) {
                $env:PATH = "$platformTools;$env:PATH"
                Write-Host "Added Android SDK platform-tools to PATH: $platformTools" -ForegroundColor Gray
                break
            }
        }
    }
}

# Python / backend
$pythonExe = Join-Path $projectRoot 'venv\Scripts\python.exe'
if (!(Test-Path $pythonExe)) {
    $pythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
    if (!(Test-Path $pythonExe)) {
        $pythonExe = 'python'
        Write-Host "No virtualenv found. Using system Python: $pythonExe" -ForegroundColor Yellow
    }
}

if (!(Test-Path (Join-Path $backendPath 'manage.py'))) {
    Write-Error "Django manage.py not found at $backendPath"
}
if (!(Test-Path (Join-Path $flutterPath 'pubspec.yaml'))) {
    Write-Error "Flutter project (pubspec.yaml) not found at $flutterPath"
}

# JAVA_HOME for Gradle (Android build)
if (-not $env:JAVA_HOME) {
    $possibleJava = "C:\Program Files\Android\Android Studio\jbr"
    if (Test-Path $possibleJava) {
        $env:JAVA_HOME = $possibleJava
        $env:PATH = "$possibleJava\bin;$env:PATH"
        Write-Host "Auto-configured JAVA_HOME: $possibleJava" -ForegroundColor Gray
    } else {
        Write-Warning "JAVA_HOME is not set. Gradle build might fail."
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Django Backend + Flutter on Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend: $backendPath" -ForegroundColor Green
Write-Host "Flutter App: $App ($flutterPath)" -ForegroundColor Green
Write-Host "Release: $Release" -ForegroundColor Green
Write-Host ""

# ADB and device / emulator (launch emulator if none running)
Write-Host "Checking for Android devices/emulators..." -ForegroundColor Cyan
try {
    $prevErr = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $adbVersion = & adb version 2>&1
    $adbOk = $LASTEXITCODE -eq 0 -or $?
    $ErrorActionPreference = $prevErr

    if (-not $adbOk) {
        Write-Warning "ADB not found. Install Android SDK Platform-Tools and set ANDROID_HOME (or PATH)."
    } else {
        Write-Host "ADB detected." -ForegroundColor Gray
        $ErrorActionPreference = 'Continue'
        $devicesOutput = & adb devices 2>&1
        $devices = $devicesOutput | Select-String -Pattern "\tdevice$"
        $ErrorActionPreference = $prevErr

        if (-not $devices) {
            Write-Host "No Android device. Attempting to launch emulator..." -ForegroundColor Yellow
            $emulatorsOutput = flutter emulators 2>&1
            $emulators = $emulatorsOutput | Select-String "Pixel"
            if (-not $emulators) { $emulators = $emulatorsOutput | Select-String "android" }

            if ($emulators) {
                $firstMatch = $emulators | Select-Object -First 1
                $firstLine = if ($firstMatch.Line) { $firstMatch.Line } else { $firstMatch.ToString() }
                $emulatorId = (-split $firstLine)[0].Trim()
                Write-Host "Launching emulator: $emulatorId" -ForegroundColor Cyan
                $ErrorActionPreference = 'Continue'
                flutter emulators --launch $emulatorId 2>&1 | Out-Null
                $ErrorActionPreference = $prevErr
                Write-Host "Waiting for emulator to boot..." -ForegroundColor Yellow
                $retries = 60
                while ($retries -gt 0) {
                    Start-Sleep -Seconds 2
                    $ErrorActionPreference = 'Continue'
                    $devList = & adb devices 2>&1
                    $ErrorActionPreference = $prevErr
                    $d = $devList | Select-String "\tdevice$"
                    if ($d) {
                        Write-Host "Emulator connected." -ForegroundColor Green
                        $deviceLine = ($devList | Select-String "\tdevice$" | Select-Object -First 1).Line
                        if ($deviceLine) { $Device = ($deviceLine -split "\s+")[0].Trim() }
                        break
                    }
                    $retries--
                    Write-Host "." -NoNewline
                }
                if ($retries -gt 0) { Write-Host "" }
                if ($retries -le 0) {
                    Write-Warning "Emulator did not become ready in time. Continuing anyway."
                }
            } else {
                Write-Warning "No emulators found. Launch one from Android Studio (AVD Manager) and run this script again."
            }
        } else {
            Write-Host "Android device detected." -ForegroundColor Green
            if (-not $Device) {
                $ErrorActionPreference = 'Continue'
                $devList = & adb devices 2>&1
                $ErrorActionPreference = $prevErr
                $deviceLine = ($devList | Select-String "\tdevice$" | Select-Object -First 1).Line
                if ($deviceLine) { $Device = ($deviceLine -split "\s+")[0].Trim() }
            }
        }
    }
} catch {
    Write-Warning "ADB/emulator check failed: $_"
}
if ($Device) { Write-Host "Device: $Device" -ForegroundColor Green }
Write-Host ""

# Free port 8000
Write-Host "Checking for processes using port 8000..." -ForegroundColor Cyan
try {
    $portOutput = netstat -ano | Select-String ":8000.*LISTENING"
    if ($portOutput) {
        $pidString = ($portOutput -split '\s+')[-1]
        if ($pidString -match '^\d+$') {
            $portPid = [int]$pidString
            Write-Host "Stopping process on port 8000 (PID $portPid)..." -ForegroundColor Yellow
            try { Stop-Process -Id $portPid -Force -ErrorAction Stop } catch { $null = taskkill /PID $portPid /F 2>&1 }
            Start-Sleep -Seconds 1
        }
    }
} catch { Write-Host "Could not check port 8000. Continuing..." -ForegroundColor Yellow }

# Start Django backend (daphne)
Write-Host "Starting Django backend with daphne (ASGI) on http://127.0.0.1:8000..." -ForegroundColor Cyan
$backendProcess = Start-Process -FilePath $pythonExe -ArgumentList '-m', 'daphne', '-b', '127.0.0.1', '-p', '8000', 'school_backend.asgi:application' -WorkingDirectory $backendPath -NoNewWindow -PassThru
Start-Sleep -Seconds 3
if ($backendProcess.HasExited) {
    Write-Error "Django backend failed to start. Check for errors above."
}
Write-Host "Django backend started (PID: $($backendProcess.Id))" -ForegroundColor Green

# ADB reverse so device/emulator can reach host:8000
Write-Host "Setting up ADB reverse (tcp:8000)..." -ForegroundColor Cyan
try {
    adb reverse tcp:8000 tcp:8000
    if ($?) { Write-Host "ADB reverse OK." -ForegroundColor Green } else { Write-Warning "ADB reverse failed." }
} catch { Write-Warning "ADB reverse failed. App may not reach backend." }

# Run Flutter on Android
Write-Host ""
Write-Host "Launching Flutter app on Android: $App..." -ForegroundColor Cyan
Push-Location $flutterPath
try {
    $flutterArgs = @('run')
    if ($Device) { $flutterArgs += '-d', $Device } else { $flutterArgs += '-d', 'android' }
    if ($Release) { $flutterArgs += '--release' }
    Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor Gray
    flutter @flutterArgs
} catch {
    Write-Error "Flutter app failed to start: $_"
} finally {
    Pop-Location
    Write-Host ""
    Write-Host "Stopping Django backend..." -ForegroundColor Yellow
    if ($backendProcess -and -not $backendProcess.HasExited) {
        try {
            $backendProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
            if (-not $backendProcess.HasExited) { $backendProcess.Kill() }
        } catch {
            if (-not $backendProcess.HasExited) { $backendProcess.Kill() }
        }
        $backendProcess.WaitForExit()
        Write-Host "Django backend stopped." -ForegroundColor Green
    }
    Write-Host "All processes stopped." -ForegroundColor Green
}
