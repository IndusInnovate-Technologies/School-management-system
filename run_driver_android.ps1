# Run Driver Portal app on Android (with optional Django backend).
# Usage: .\run_driver_android.ps1 [-Release] [-Device <device_id>] [-NoBackend]
#
# -NoBackend: Skip starting Django; use when backend is already running.

param(
    [switch]$Release,
    [string]$Device = '',
    [switch]$NoBackend
)

$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot 'backend'
$driverPath = Join-Path $projectRoot 'frontend\Driver_portal-main'

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

# Verify Driver portal exists
if (!(Test-Path (Join-Path $driverPath 'pubspec.yaml'))) {
    Write-Error "Driver portal not found at $driverPath (expected pubspec.yaml)"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Driver Portal - Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Driver app: $driverPath" -ForegroundColor Green
if ($Device) { Write-Host "Device: $Device" -ForegroundColor Green }
Write-Host "Release: $Release | NoBackend: $NoBackend" -ForegroundColor Green
Write-Host ""

# JAVA_HOME for Gradle
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

# ADB and devices / emulator
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
            } else {
                Write-Warning "No emulators found. Launch one from Android Studio."
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

$backendProcess = $null

if (-not $NoBackend) {
    if (!(Test-Path (Join-Path $backendPath 'manage.py'))) {
        Write-Warning "Django backend not found at $backendPath. Use -NoBackend if backend runs elsewhere."
    } else {
        # Free port 8000 if needed
        try {
            $portOutput = netstat -ano | Select-String ":8000.*LISTENING"
            if ($portOutput) {
                $pidString = ($portOutput -split '\s+')[-1]
                if ($pidString -match '^\d+$') {
                    $portPid = [int]$pidString
                    Write-Host "Stopping process on port 8000 (PID $portPid)..." -ForegroundColor Yellow
                    try { Stop-Process -Id $portPid -Force -ErrorAction Stop } catch { taskkill /PID $portPid /F 2>&1 | Out-Null }
                    Start-Sleep -Seconds 1
                }
            }
        } catch { }

        $pythonExe = Join-Path $projectRoot 'venv\Scripts\python.exe'
        if (!(Test-Path $pythonExe)) {
            $pythonExe = Join-Path $backendPath 'venv\Scripts\python.exe'
        }
        if (!(Test-Path $pythonExe)) { $pythonExe = 'python' }

        Write-Host "Starting Django backend on http://127.0.0.1:8000..." -ForegroundColor Cyan
        $backendProcess = Start-Process -FilePath $pythonExe -ArgumentList '-m', 'daphne', '-b', '127.0.0.1', '-p', '8000', 'school_backend.asgi:application' -WorkingDirectory $backendPath -NoNewWindow -PassThru
        Start-Sleep -Seconds 3
        if ($backendProcess.HasExited) {
            Write-Error "Django backend failed to start."
        }
        Write-Host "Backend started (PID: $($backendProcess.Id))" -ForegroundColor Green
    }
}

# ADB reverse so emulator/device can reach host:8000
Write-Host "Setting up ADB reverse (tcp:8000)..." -ForegroundColor Cyan
try {
    adb reverse tcp:8000 tcp:8000
    if ($?) { Write-Host "ADB reverse OK." -ForegroundColor Green } else { Write-Warning "ADB reverse failed." }
} catch {
    Write-Warning "ADB reverse failed. App may not reach backend."
}

# Run Driver portal on Android
Write-Host ""
Write-Host "Launching Driver Portal on Android..." -ForegroundColor Cyan
Push-Location $driverPath
try {
    $flutterArgs = @('run')
    if ($Device) { $flutterArgs += '-d', $Device }
    if ($Release) { $flutterArgs += '--release' }
    Write-Host "flutter $($flutterArgs -join ' ')" -ForegroundColor Gray
    flutter @flutterArgs
} catch {
    Write-Error "Flutter run failed: $_"
} finally {
    Pop-Location
    if ($backendProcess -and -not $backendProcess.HasExited) {
        Write-Host "Stopping Django backend..." -ForegroundColor Yellow
        try {
            $backendProcess.CloseMainWindow() | Out-Null
            Start-Sleep -Seconds 1
            if (-not $backendProcess.HasExited) { $backendProcess.Kill() }
        } catch {
            if (-not $backendProcess.HasExited) { $backendProcess.Kill() }
        }
        Write-Host "Backend stopped." -ForegroundColor Green
    }
    Write-Host "Done." -ForegroundColor Green
}
