Set-Location D:\AURA_App
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue

git add lib/models/orbit_state.dart
git add lib/screens/home/home_screen.dart
git add lib/screens/profile/profile_screen.dart
git add lib/screens/reels/pulse_screen.dart
git add lib/screens/social/orbit_moment_screen.dart
git add lib/screens/social/daily_puzzle_screen.dart
git add lib/screens/social/orbit_wrapped_screen.dart
git add lib/screens/social/song_receipt_screen.dart
git add lib/screens/social/red_flag_screen.dart
git add lib/screens/social/music_roast_screen.dart
git add lib/screens/social/daily_drop_screen.dart
git add lib/screens/social/blindspot_screen.dart
git add lib/screens/social/song_secret_screen.dart
git add lib/screens/campfire/steal_aux_widget.dart
git add lib/screens/profile/era_picker_sheet.dart
git add lib/screens/social/hot_take_screen.dart
git add lib/screens/social/npc_song_screen.dart
git add lib/screens/social/time_capsule_screen.dart
git add lib/screens/social/song_dare_screen.dart
git add lib/screens/social/sound_room_screen.dart
git add lib/screens/social/vibe_match_screen.dart
git add lib/screens/social/orbit_receipts_screen.dart
git add lib/screens/social/streak_chain_screen.dart
git add push_genz.ps1
git add push_features2.ps1
git add push_features3.ps1

git status

$msg = "feat: complete Gen Z feature drop - 20 new screens across 3 batches"
git commit -m $msg

git push origin main

Write-Host "Done!" -ForegroundColor Green
