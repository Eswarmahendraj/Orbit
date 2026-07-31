@echo off
cd /d D:\AURA_App
echo === Android Build — %DATE% %TIME% ===
echo.

set JAVA_HOME=D:\jdk17\jdk-17.0.11+9
set ANDROID_HOME=D:\android-sdk
set PUB_CACHE=D:\pub_cache
set PATH=D:\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin;%PATH%

echo [OK] JAVA_HOME  = %JAVA_HOME%
echo [OK] ANDROID_HOME = %ANDROID_HOME%
echo.

:: ── Build APK ─────────────────────────────────────────────────────────────────
echo [1/2] flutter build apk --release ...
call flutter build apk --release 2>&1
if %ERRORLEVEL% EQU 0 (
  echo  OK  →  build\app\outputs\flutter-apk\app-release.apk
) else (
  echo  FAILED
)

echo.

:: ── Build App Bundle ──────────────────────────────────────────────────────────
echo [2/2] flutter build appbundle --release ...
call flutter build appbundle --release 2>&1
if %ERRORLEVEL% EQU 0 (
  echo  OK  →  build\app\outputs\bundle\release\app-release.aab
) else (
  echo  FAILED
)

echo.
echo === DONE ===
pause
