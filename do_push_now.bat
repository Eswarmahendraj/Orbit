@echo off
cd /d D:\AURA_App
echo === Force-Push New Features — %DATE% %TIME% ===
echo.

echo Clearing stale git locks...
del /f /q .git\index.lock 2>nul
del /f /q .git\HEAD.lock 2>nul
del /f /q .git\MERGE_HEAD 2>nul
echo Done.
echo.

echo Staging all changed lib files...
git add lib\screens\onboarding\onboarding_screen.dart
git add lib\screens\home\home_screen.dart
git add lib\screens\reels\pulse_screen.dart
git add lib\screens\reels\meme_studio_screen.dart
git add lib\screens\find\find_screen.dart
git add lib\services\ai_service.dart
git add lib\config\api_config.dart
git add lib\screens\ai\ai_caption_screen.dart
git add lib\screens\ai\voice_playlist_screen.dart
git add lib\screens\social\vibe_check_ai_screen.dart
git add pubspec.yaml
git add pubspec.lock
echo.

git status --short
echo.

echo Committing...
git commit -m "feat: cinematic onboarding, Drop comments, empty states, story viewer"
echo.

echo Pushing to GitHub...
powershell -ExecutionPolicy Bypass -Command "cd 'D:\AURA_App'; git push origin main; exit $LASTEXITCODE"
echo.

if %ERRORLEVEL% EQU 0 (
  echo === PUSH SUCCESS ===
) else (
  echo === PUSH FAILED — check above for errors ===
)
echo.
pause
