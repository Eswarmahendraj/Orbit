Set-Location D:\AURA_App
$env:PATH = "D:\flutter\bin;" + $env:PATH
$env:PUB_CACHE = "D:\pub_cache"

Write-Host "=== Building Flutter Web ===" -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) {
    Write-Host "FLUTTER WEB BUILD FAILED" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "=== Committing web build ===" -ForegroundColor Cyan
del /f /q .git\index.lock 2>$null
git add build\web\
git commit -m "build: Flutter web release — voice playlist, find theming, story waveforms"
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== WEB PUSH SUCCESS ===" -ForegroundColor Green
} else {
    Write-Host "=== PUSH FAILED ===" -ForegroundColor Red
}
Read-Host "Press Enter to close"
