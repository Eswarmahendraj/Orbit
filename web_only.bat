@echo off
cd /d D:\AURA_App
set PATH=D:\flutter\bin;%PATH%
set PUB_CACHE=D:\pub_cache

echo === Building Flutter Web ===
call flutter build web --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
  echo FLUTTER WEB BUILD FAILED
  pause
  exit /b 1
)

echo === Pushing to GitHub ===
del /f /q .git\index.lock 2>nul
git add build\web\
git commit -m "build: Flutter web release — voice playlist, find theming, story waveforms"
git push origin main

echo.
echo === WEB PUSH SUCCESS ===
pause
