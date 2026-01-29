# Project Synchronization Script
# This script ensures that both Backend and Frontend are in sync after a merge or update.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Project Synchronization..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot "backend"
$frontendPath = Join-Path $projectRoot "frontend"

# 1. Backend Synchronization
Write-Host "[1/2] Syncing Backend..." -ForegroundColor Green

# Check for .env file
if (!(Test-Path (Join-Path $backendPath ".env"))) {
    Write-Host "Warning: .env file not found in $backendPath" -ForegroundColor Yellow
    Write-Host "Please copy .env.example to .env and fill in your database credentials." -ForegroundColor Yellow
}

# Run Migrations
Write-Host "Running migrations..." -ForegroundColor Gray
Push-Location $backendPath
try {
    # Try to find python in venv
    $pythonExe = Join-Path "venv" "Scripts" "python.exe"
    if (!(Test-Path $pythonExe)) {
        $pythonExe = "python"
    }
    
    & $pythonExe manage.py migrate
    Write-Host "Backend migrations completed." -ForegroundColor Green
} catch {
    Write-Error "Failed to run backend migrations: $_"
} finally {
    Pop-Location
}

# 2. Frontend Synchronization
Write-Host ""
Write-Host "[2/2] Syncing Frontend..." -ForegroundColor Green

# List of app directories
$apps = @(
    "main_login",
    "apps\management_org",
    "apps\teacher_main_folder",
    "apps\parent_main_folder",
    "apps\super_admin"
)

foreach ($app in $apps) {
    $appDir = Join-Path $frontendPath $app
    if (Test-Path $appDir) {
        Write-Host "Updating dependencies for $app..." -ForegroundColor Gray
        Push-Location $appDir
        try {
            flutter pub get
            Write-Host "Dependencies updated for $app." -ForegroundColor Green
        } catch {
            Write-Warning "Failed to update dependencies for $app. Skipping..."
        } finally {
            Pop-Location
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Synchronization Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
