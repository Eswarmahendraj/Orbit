@echo off
cd /d D:\AURA_App

set JAVA_HOME=D:\jdk17\jdk-17.0.11+9
set ANDROID_HOME=D:\android-sdk
set PUB_CACHE=D:\pub_cache
set PATH=D:\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin;%PATH%

echo.
echo ========================================
echo  ORBIT — APK + Web Build ^& Push
echo ========================================
echo.

:: ── 1. Build APK ──────────────────────────────────────────────────────────────
echo [1/3] flutter build apk --release ...
call flutter build apk --release
if %ERRORLEVEL% EQU 0 (
  echo  [OK] APK  →  build\app\outputs\flutter-apk\app-release.apk
) else (
  echo  [FAIL] APK build failed
  pause
  exit /b 1
)

echo.

:: ── 2. Build Flutter Web ──────────────────────────────────────────────────────
echo [2/3] flutter build web --release ...
call flutter build web --release --no-tree-shake-icons
if %ERRORLEVEL% EQU 0 (
  echo  [OK] Web  →  build\web\
) else (
  echo  [FAIL] Web build failed
  pause
  exit /b 1
)

echo.

:: ── 3. Push web build to GitHub ───────────────────────────────────────────────
echo [3/3] Pushing web build to GitHub ...
del /f /q .git\index.lock 2>nul
git add build\web\
git commit -m "build: Flutter web release — voice playlist, find theming, story waveforms"
git push origin main
if %ERRORLEVEL% EQU 0 (
  echo  [OK] PUSH SUCCESS
) else (
  echo  [FAIL] Push failed
)

echo.
echo ========================================
echo  DONE
echo ========================================
pause
