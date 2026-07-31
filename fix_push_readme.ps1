Set-Location D:\AURA_App
# Kill any lingering git processes
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
# Force remove lock
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
# Commit and push
git add README.md
git status
$msg = "docs: rewrite README with all current features"
git commit -m $msg
git push origin main
Write-Host "README PUSHED!" -ForegroundColor Green
Read-Host "Press Enter to close"
