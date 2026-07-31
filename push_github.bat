@echo off
cd /d D:\AURA_App
echo === GitHub Push — %DATE% %TIME% ===
echo.

echo Removing stale locks...
del /f /q .git\index.lock 2>nul
del /f /q .git\HEAD.lock  2>nul

echo Running flutter pub get...
flutter pub get

echo.
echo Staging files...
git add lib\config\api_config.dart
git add lib\services\ai_service.dart
git add lib\screens\ai\voice_playlist_screen.dart
git add lib\screens\ai\ai_caption_screen.dart
git add lib\screens\social\vibe_check_ai_screen.dart
git add lib\screens\reels\pulse_screen.dart
git add lib\screens\reels\meme_studio_screen.dart
git add lib\screens\reels\remix_drop_screen.dart
git add lib\screens\reels\trending_sounds_screen.dart
git add lib\screens\find\find_screen.dart
git add lib\screens\profile\profile_screen.dart
git add pubspec.yaml
git add pubspec.lock

git status --short
echo.

git add lib\screens\onboarding\onboarding_screen.dart
git add lib\screens\home\home_screen.dart

echo Committing...
git commit -m "feat: cinematic onboarding, Drop comments, empty states, story viewer"

echo.
echo Pushing via PowerShell (proxy bypass)...
powershell -ExecutionPolicy Bypass -Command "cd 'D:\AURA_App'; git push origin main; exit $LASTEXITCODE"

echo.
if %ERRORLEVEL% EQU 0 (
  echo PUSH SUCCESS — Vercel will auto-deploy
) else (
  echo PUSH FAILED — check network/proxy
)
echo.
pause
