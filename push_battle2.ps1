Set-Location D:\AURA_App
Get-Process -Name "git" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
git add lib/screens/campfire/song_battle_screen.dart
git add lib/services/song_battle_service.dart
git status
$msg = "feat: song battle v2 - invite friend, 1 vote/account, 24h timer, update/remove song, edit request approval"
git commit -m $msg
git push origin main
Write-Host "Battle v2 pushed!" -ForegroundColor Green
Read-Host "Press Enter to close"
