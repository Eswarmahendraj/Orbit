Set-Location D:\AURA_App

# Kill any lingering git locks
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
Remove-Item '.git\HEAD.lock'  -Force -ErrorAction SilentlyContinue

Write-Host "Building Flutter web — Deep Orbit dark theme..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build FAILED" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host "Build OK. Committing..." -ForegroundColor Green

git add lib/theme/aura_theme.dart
git add lib/widgets/web_scaffold.dart
git add lib/main.dart
git add lib/screens/home/home_screen.dart
git add build/web/
git status --short

git commit -m "feat: Deep Orbit UI — dark-first theme, premium sidebar, glowing cards, orbital logo"
Write-Host "Commit exit code: $LASTEXITCODE" -ForegroundColor Yellow

git push origin main
Write-Host "Push exit code: $LASTEXITCODE" -ForegroundColor Yellow

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS — Deep Orbit UI pushed. Vercel deploying now." -ForegroundColor Green
} else {
    Write-Host "Push FAILED" -ForegroundColor Red
}
Read-Host "Press Enter to close"
