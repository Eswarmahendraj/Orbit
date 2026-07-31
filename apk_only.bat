@echo off
cd /d D:\AURA_App
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set ANDROID_HOME=D:\android-sdk
set PATH=D:\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%
set PUB_CACHE=D:\pub_cache

echo === Re-downloading speech_to_text (restoring original) ===
rd /s /q "D:\pub_cache\hosted\pub.dev\speech_to_text-6.6.2" 2>nul
call flutter pub get

echo === Patching speech_to_text companion object (V1 embedding removal) ===
powershell -ExecutionPolicy Bypass -File "D:\AURA_App\patch_stt.ps1"
if %ERRORLEVEL% NEQ 0 (
  echo Patch failed
  pause
  exit /b 1
)

echo === Building Flutter APK (release) ===
echo Log: D:\AURA_App\apk_build_log.txt

call flutter build apk --release > D:\AURA_App\apk_build_log.txt 2>&1

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo APK BUILD FAILED
  echo --- Last 40 lines of log ---
  powershell -Command "Get-Content D:\AURA_App\apk_build_log.txt | Select-Object -Last 40"
  pause
  exit /b 1
)

echo.
echo === APK BUILD SUCCESS ===
echo Output: build\app\outputs\flutter-apk\app-release.apk
pause
