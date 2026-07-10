# AURA App — Setup Guide

## Prerequisites
Install these on your laptop before anything else:

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
2. **Android Studio** — https://developer.android.com/studio
3. **Java JDK 17** — comes with Android Studio
4. **Git** — https://git-scm.com

---

## Step 1 — Firebase Setup (5 minutes)

1. Go to https://console.firebase.google.com
2. Create a new project → name it **AURA**
3. Enable these services:
   - Authentication → Email/Password + Phone
   - Firestore Database → Start in test mode
   - Storage
4. Add an Android app:
   - Package name: `com.aura.app`
   - Download `google-services.json`
   - Place it at: `AURA_App/android/app/google-services.json`

---

## Step 2 — Android Setup

Open `AURA_App/android/app/build.gradle` and confirm:
```
applicationId "com.aura.app"
minSdk 21
targetSdk 34
```

Open `AURA_App/android/build.gradle` and add at the bottom of dependencies:
```
classpath 'com.google.gms:google-services:4.4.0'
```

---

## Step 3 — Run the App

```bash
cd AURA_App
flutter pub get
flutter run
```

Connect your Android phone via USB with Developer Mode + USB Debugging enabled,
or use Android Studio's emulator.

---

## Project Structure

```
lib/
  main.dart                    ← App entry point
  theme/aura_theme.dart        ← Colors, fonts, design system
  models/
    user_model.dart            ← User + TenureEmoji
    message_model.dart         ← Messages, Rooms, Posts
  services/
    auth_service.dart          ← Signup, OTP, login, logout
    chat_service.dart          ← 1-on-1, Campfire, Circle Thread messaging
  screens/
    auth/
      signup_screen.dart       ← Email or mobile signup
      otp_screen.dart          ← OTP verification
    home/
      home_screen.dart         ← Your Aura + friends' Auras
    campfire/
      campfire_screen.dart     ← Room discovery + mood filters
      room_screen.dart         ← Group chat inside a Campfire room
    messages/
      messages_screen.dart     ← DMs + Circle Threads list
      chat_screen.dart         ← 1-on-1 chat (no timestamps, no read receipts)
    profile/
      profile_screen.dart      ← Mood, interests, settings
```

---

## Key Design Decisions in Code

| Feature | Implementation |
|---------|---------------|
| No timestamps | `createdAt` stored in Firestore for ordering only, never shown in UI |
| No read receipts | No `readAt` field exists anywhere |
| Typing indicator | Firestore `typing: {userId: bool}` map, shown to receiver only |
| Sound-only notifications | FCM with `content_available: true`, silent push |
| Tenure emojis | `TenureEmoji.getEmoji(days)` in user_model.dart |
| Aura glow | Animated `BoxShadow` with pulsing opacity |
| Campfire messages clear on exit | Messages stored per-room, not archived to user |
