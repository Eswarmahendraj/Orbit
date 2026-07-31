@echo off
cd /d D:\AURA_App
set LOG=D:\AURA_App\build_all_log.txt
echo === BUILD ALL — %DATE% %TIME% === > %LOG%

echo.
echo =============================================
echo  AURA — Full Platform Build
echo =============================================
echo.

:: ── 1. flutter pub get ───────────────────────────────────────────────────────
echo [1/4] flutter pub get...
echo [1/4] flutter pub get >> %LOG%
call flutter pub get >> %LOG% 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  FAILED — check build_all_log.txt
  echo PUB_GET_FAILED >> %LOG%
  pause
  exit /b 1
)
echo  OK

:: ── 2. Web ───────────────────────────────────────────────────────────────────
echo [2/4] flutter build web --release ...
echo [2/4] flutter build web --release >> %LOG%
call flutter build web --release >> %LOG% 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  FAILED — check build_all_log.txt
  echo WEB_BUILD_FAILED >> %LOG%
  pause
  exit /b 1
)
echo  OK  →  build\web\
echo WEB_BUILD_OK >> %LOG%

:: ── 3. Android APK ───────────────────────────────────────────────────────────
echo [3/4] flutter build apk --release ...
echo [3/4] flutter build apk --release >> %LOG%
call flutter build apk --release >> %LOG% 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  FAILED — check build_all_log.txt
  echo APK_BUILD_FAILED >> %LOG%
) else (
  echo  OK  →  build\app\outputs\flutter-apk\app-release.apk
  echo APK_BUILD_OK >> %LOG%
)

:: ── 4. Android App Bundle ────────────────────────────────────────────────────
echo [4/4] flutter build appbundle --release ...
echo [4/4] flutter build appbundle --release >> %LOG%
call flutter build appbundle --release >> %LOG% 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo  FAILED — check build_all_log.txt
  echo AAB_BUILD_FAILED >> %LOG%
) else (
  echo  OK  →  build\app\outputs\bundle\release\app-release.aab
  echo AAB_BUILD_OK >> %LOG%
)

:: ── Summary ──────────────────────────────────────────────────────────────────
echo.
echo =============================================
echo  BUILD COMPLETE — check build_all_log.txt
echo =============================================
echo.
echo  Web:     build\web\
echo  APK:     build\app\outputs\flutter-apk\app-release.apk
echo  Bundle:  build\app\outputs\bundle\release\app-release.aab
echo.
echo NOTE: iOS requires macOS + Xcode ^(run on a Mac^)
echo.
echo === DONE === >> %LOG%
pause
