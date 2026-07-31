@echo off
cd /d D:\AURA_App
del /f /q .git\index.lock 2>nul
git add README.md
git commit -m "docs: rewrite README with all current features"
git push origin main
echo.
echo README pushed!
pause
