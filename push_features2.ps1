Set-Location D:\AURA_App
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue

git add lib/screens/social/song_receipt_screen.dart
git add lib/screens/social/red_flag_screen.dart
git add lib/screens/social/music_roast_screen.dart
git add lib/screens/social/daily_drop_screen.dart
git add lib/screens/social/blindspot_screen.dart
git add lib/screens/social/song_secret_screen.dart
git add lib/screens/campfire/steal_aux_widget.dart
git add lib/models/orbit_state.dart
git add lib/screens/home/home_screen.dart
git add lib/screens/profile/profile_screen.dart

git status --short
git commit -m 'feat: Gen Z batch 2 - Song Receipt, Red Flag/Green Flag, Music Roast, Daily Drop, Blindspot, Song Secret, NPC Mode, Steal the Aux'
git push origin main
Write-Host 'DONE' -ForegroundColor Green
