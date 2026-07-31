@echo off
cd /d D:\AURA_App
set LOG=D:\AURA_App\commit_log.txt
echo === START %DATE% %TIME% === > %LOG%

echo Removing stale locks... >> %LOG%
del /f /q .git\index.lock >> %LOG% 2>&1
del /f /q .git\HEAD.lock  >> %LOG% 2>&1

echo Building Flutter web... >> %LOG%
call flutter build web --release >> %LOG% 2>&1
echo BUILD_EXIT:%ERRORLEVEL% >> %LOG%
if %ERRORLEVEL% NEQ 0 (
  echo BUILD FAILED — check commit_log.txt >> %LOG%
  start notepad %LOG%
  exit /b 1
)

echo Staging files... >> %LOG%
git add lib\main.dart >> %LOG% 2>&1
git add lib\theme\aura_theme.dart >> %LOG% 2>&1
git add lib\widgets\web_scaffold.dart >> %LOG% 2>&1
git add lib\screens\home\dm_screen.dart >> %LOG% 2>&1
git add lib\screens\messages\messages_screen.dart >> %LOG% 2>&1
git add lib\screens\profile\profile_screen.dart >> %LOG% 2>&1
git add lib\screens\settings\settings_screen.dart >> %LOG% 2>&1
git add lib\screens\campfire\campfire_screen.dart >> %LOG% 2>&1
git add lib\screens\campfire\campfire_chat_screen.dart >> %LOG% 2>&1
git add lib\screens\find\find_screen.dart >> %LOG% 2>&1
git add lib\screens\social\vybe_map_screen.dart >> %LOG% 2>&1
git add build\web\ >> %LOG% 2>&1
echo STAGE_EXIT:%ERRORLEVEL% >> %LOG%

git status --short >> %LOG% 2>&1

echo Committing... >> %LOG%
git commit -m "feat: futuristic UI v6 — orbital chat, DM v2, Music DNA, orbit radar, vybe map HUD, campfire plasma, profile redesign" >> %LOG% 2>&1
echo COMMIT_EXIT:%ERRORLEVEL% >> %LOG%

echo Pushing via PowerShell... >> %LOG%
powershell -ExecutionPolicy Bypass -Command "cd 'D:\AURA_App'; git push origin main; exit $LASTEXITCODE" >> %LOG% 2>&1
echo PUSH_EXIT:%ERRORLEVEL% >> %LOG%

echo === DONE === >> %LOG%
start notepad %LOG%
