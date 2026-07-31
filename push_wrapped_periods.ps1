Set-Location D:\AURA_App
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue

git add lib/screens/social/orbit_wrapped_screen.dart
git status

$msg = "feat: orbit wrapped — add monthly + yearly period toggle with top 3 songs and total posts"
git commit -m $msg
git push origin main

Write-Host "Pushed!" -ForegroundColor Green
Read-Host "Press Enter to close"
