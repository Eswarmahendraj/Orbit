Set-Location D:\AURA_App
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue

Write-Host "Building Flutter web (this takes 2-4 minutes)..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build FAILED" -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Build done! Committing to git..." -ForegroundColor Cyan
git add lib/screens/social/orbit_receipts_screen.dart
git add lib/screens/social/streak_chain_screen.dart
git add lib/screens/settings/settings_screen.dart
git add build/web/
git status

$msg = "fix: web compile errors (apostrophe, _Dot getter, Clipboard import) + rebuild Flutter web for Vercel"
git commit -m $msg
git push origin main

Write-Host ""
Write-Host "Web build pushed! Vercel will serve the updated app." -ForegroundColor Green
Read-Host "Press Enter to close"
