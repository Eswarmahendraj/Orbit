Set-Location D:\AURA_App
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
git add web_portal/index.html
git status
$msg = "feat: update web portal dashboard with all 20+ Gen Z features"
git commit -m $msg
git push origin main
Write-Host "Web portal pushed!" -ForegroundColor Green
Read-Host "Press Enter to close"
