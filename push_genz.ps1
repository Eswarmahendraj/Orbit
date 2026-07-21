Set-Location D:\AURA_App
Remove-Item '.git\index.lock' -Force -ErrorAction SilentlyContinue
git add lib/screens/social/orbit_moment_screen.dart
git add lib/screens/social/daily_puzzle_screen.dart
git add lib/screens/social/orbit_wrapped_screen.dart
git add lib/screens/reels/pulse_screen.dart
git add lib/screens/home/home_screen.dart
git add lib/screens/profile/era_picker_sheet.dart
git add lib/models/orbit_state.dart
git add lib/screens/profile/profile_screen.dart
git status --short
git commit -m 'feat: Gen Z features - Era Mode, Orbit Moment, Daily Music Puzzle, Orbit Wrapped'
git push origin main
Write-Host 'DONE' -ForegroundColor Green
