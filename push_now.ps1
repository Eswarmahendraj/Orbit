Set-Location D:\AURA_App
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
Remove-Item '.git\HEAD.lock' -Force -ErrorAction SilentlyContinue
git push origin main
Write-Host "Done!" -ForegroundColor Green
Read-Host "Press Enter to close"
