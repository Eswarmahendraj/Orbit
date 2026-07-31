Set-Location D:\AURA_App

Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
Remove-Item '.git\HEAD.lock'  -Force -ErrorAction SilentlyContinue

Write-Host "Building Flutter web — Deep Orbit UI (2-4 min)..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build FAILED" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Build done! Staging files..." -ForegroundColor Cyan
git add lib/theme/aura_theme.dart
git add lib/widgets/web_scaffold.dart
git add lib/main.dart
git add lib/screens/home/home_screen.dart
git add build/web/
git status

$msg = "feat: Deep Orbit UI — dark-first theme, premium web shell, glowing post cards, orbital logo"
git commit -m $msg
git push origin main

Write-Host ""
Write-Host "Orbit UI pushed! Vercel will serve the new look." -ForegroundColor Green
Read-Host "Press Enter to close"
