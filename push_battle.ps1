Set-Location D:\AURA_App
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
git add lib/models/song_battle_model.dart
git add lib/services/song_battle_service.dart
git add lib/screens/pulse/
git add lib/screens/reels/pulse_screen.dart
git status --short
git commit -m 'feat: Song Battle - challenge friends, pick songs, vote, edit requests'
git push origin main
Write-Host 'DONE' -ForegroundColor Green
