@echo off
cd /d D:\AURA_App
del /f /q .git\index.lock 2>nul
del /f /q .git\HEAD.lock 2>nul
git add lib\screens\profile\profile_screen.dart
git add lib\widgets\web_scaffold.dart
git commit -m "fix: remove duplicate map+settings, add Messages to mobile nav"
powershell -ExecutionPolicy Bypass -Command "cd 'D:\AURA_App'; git push origin main; exit $LASTEXITCODE"
if %ERRORLEVEL% EQU 0 (echo PUSH SUCCESS) else (echo PUSH FAILED)
pause
