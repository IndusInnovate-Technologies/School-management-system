# Patches image_gallery_saver plugin's android/build.gradle to add namespace (required by AGP 8+)
# Run once if Android build fails with "Namespace not specified" for image_gallery_saver.

$ErrorActionPreference = 'Stop'
$pubCache = $env:PUB_CACHE
if (-not $pubCache) {
    $pubCache = Join-Path $env:LOCALAPPDATA 'Pub\Cache'
}
$pluginPath = Join-Path $pubCache 'hosted\pub.dev\image_gallery_saver-2.0.3\android\build.gradle'
if (-not (Test-Path $pluginPath)) {
    Write-Warning "image_gallery_saver plugin not found at $pluginPath (run 'flutter pub get' first)."
    exit 0
}
$content = Get-Content $pluginPath -Raw
if ($content -match "namespace\s+['\`"]") {
    Write-Host "image_gallery_saver already has namespace." -ForegroundColor Gray
    exit 0
}
# Add namespace inside android { } block (after first "android {" line)
$namespaceLine = "    namespace 'com.example.imagegallerysaver'"
if ($content -notmatch "namespace\s+") {
    $content = $content -replace "(\s*android\s*\{)(\r?\n)", "`$1`$2$namespaceLine`$2"
    Set-Content $pluginPath -Value $content -NoNewline
}
Write-Host "Patched image_gallery_saver android/build.gradle with namespace." -ForegroundColor Green
