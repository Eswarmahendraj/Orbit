@echo off
cd /d D:\AURA_App
echo === GitHub Push — %DATE% %TIME% ===
echo.

echo Removing stale locks...
del /f /q .git\index.lock 2>nul
del /f /q .git\HEAD.lock  2>nul

echo Staging files...
git add lib\screens\reels\meme_studio_screen.dart
git add lib\screens\reels\trending_sounds_screen.dart
git add lib\screens\reels\remix_drop_screen.dart
git add lib\screens\reels\pulse_screen.dart
git add lib\screens\profile\profile_screen.dart

git status --short
echo.

echo Committing...
git commit -m "feat: Creator Hub — Meme Studio 🎭 + Trending Sounds 🔥 + Remix 🔁 + Creator badge ✦"

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
