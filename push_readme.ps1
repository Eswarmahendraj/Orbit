Set-Location D:\AURA_App
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
git add README.md
git commit -m "docs: rewrite README with all current features"
git push origin main
Write-Host "README pushed!" -ForegroundColor Green
