@echo off
cd /d D:\AURA_App
del /f /q .git\index.lock 2>nul
del /f /q .git\HEAD.lock 2>nul

echo Running flutter pub get (palette_generator added)...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
  echo flutter pub get FAILED — check pubspec.yaml
  pause
  exit /b 1
)

echo Staging changed files...
git add pubspec.yaml
git add pubspec.lock
git add lib\config\api_config.dart
git add lib\main.dart
git add lib\services\album_theme_service.dart
git add lib\screens\home\home_screen.dart
git add lib\screens\settings\settings_screen.dart
git add lib\screens\profile\music_dna_share_screen.dart

echo Committing...
git commit -m "feat: Play Hub, album art theming, AI settings, Music DNA polish"

echo Pushing to GitHub...
powershell -ExecutionPolicy Bypass -Command "cd 'D:\AURA_App'; git push origin main; exit $LASTEXITCODE"
if %ERRORLEVEL% EQU 0 (echo PUSH SUCCESS) else (echo PUSH FAILED)
pause
