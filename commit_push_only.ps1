Set-Location D:\AURA_App

# Remove stale locks
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
Remove-Item '.git\HEAD.lock'  -Force -ErrorAction SilentlyContinue

Write-Host "Staging files..." -ForegroundColor Cyan
git add lib/theme/aura_theme.dart
git add lib/widgets/web_scaffold.dart
git add lib/main.dart
git add lib/screens/home/home_screen.dart
git add build/web/
git status --short

Write-Host "Committing..." -ForegroundColor Cyan
git commit -m "feat: Deep Orbit UI dark theme, premium sidebar, glowing cards, orbital logo"
Write-Host "Commit exit: $LASTEXITCODE" -ForegroundColor Yellow

Write-Host "Pushing..." -ForegroundColor Cyan
git push origin main
Write-Host "Push exit: $LASTEXITCODE" -ForegroundColor Yellow

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS — Deep Orbit UI live on GitHub. Vercel deploying now." -ForegroundColor Green
} else {
    Write-Host "Push FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
}
Read-Host "Press Enter to close"
