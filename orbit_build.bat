@echo off
cd /d D:\AURA_App
echo Starting flutter build... > D:\AURA_App\build_log.txt
flutter build web --release --no-tree-shake-icons >> D:\AURA_App\build_log.txt 2>&1
echo BUILD_EXIT:%ERRORLEVEL% >> D:\AURA_App\build_log.txt
if %ERRORLEVEL% neq 0 goto :fail
git add lib\theme\aura_theme.dart lib\widgets\web_scaffold.dart lib\main.dart lib\screens\home\home_screen.dart build\web\
git status --short >> D:\AURA_App\build_log.txt
git commit -m "feat: Deep Orbit UI dark theme" >> D:\AURA_App\build_log.txt 2>&1
git push origin main >> D:\AURA_App\build_log.txt 2>&1
echo PUSH_EXIT:%ERRORLEVEL% >> D:\AURA_App\build_log.txt
echo SUCCESS >> D:\AURA_App\build_log.txt
goto :end
:fail
echo FLUTTER_FAILED >> D:\AURA_App\build_log.txt
:end
echo Done >> D:\AURA_App\build_log.txt