# 🌌 Orbit

**Orbit** is a social music app built with Flutter — where your vibe, your music taste, and your circle all connect in real time. Think of it as a private social space built around what you're listening to, who you're listening with, and how you're feeling.

---

## 📱 What is Orbit?

Orbit lets you share songs, moods, and moments with your close circle — not the whole internet. It's built for Gen Z social dynamics: privacy controls that actually work, music as the core social currency, and intimate group spaces instead of public feeds.

---

## ✨ Features (V14)

### 🔒 Privacy & Security
- **Ghost Mode** — Go completely invisible. No presence, no activity, no trace.
- **Stealth View** — View others' profiles and stories without leaving a footprint.
- **Anti-Creep Shield** — Blocks unknown accounts from seeing your profile.
- **Screenshot Block** — Prevents screenshots within the app.
- **Last Seen Control** — Show last seen to Everyone / Friends only / Nobody.
- **Passcode DMs** — Lock your DMs behind a 4-digit PIN.
- **App Disguise** — The app appears as a Calculator on your home screen. Long-press `=` for 3 seconds to unlock the real app.

### 🖼️ Profile & Identity
- **PFP Editor** — Pick a photo from camera or gallery and apply one of 8 color filter presets (Normal, Warm, Cool, Neon, Vintage, Monochrome, Vivid, Dreamy).
- **Secret Vault** — A PIN-protected private space to save vybes (posts) only you can see.
- **Mood Tags** — Set your current mood with an emoji. Others see it on your profile.
- **Mood Mask** — Show a different public mood while your real mood stays private.
- **Sync Levels** — Your closeness with each friend is shown via ring colors: Bronze → Silver → Gold → Platinum.

### 🎵 Music & Feed
- **Song Feed** — Share what you're listening to with your circle.
- **Mood Tags on Songs** — Tag songs with vibes: `#hype`, `#heartbreak`, `#2am`, `#nostalgia`, etc.
- **Block Song from Feed** — Never see a specific song in your feed again.
- **Disappearing Vybes** — Posts that auto-delete after 24 hours.
- **Live Listening Dot** — A pulsing dot on story bubbles shows who's listening live right now.
- **Reaction DM Thread** — React to a song with 🔥 and it opens a DM thread with that person.
- **iTunes Preview** — Songs play a 30-second preview via the iTunes Search API.

### 🔥 Campfire (Group Spaces)
- **Secret Campfire** — Invite-only group spaces. Only members can see or join.
- **Campfire Chat** — Chat inside a campfire, gated with a PIN passcode.
- **Song Battle** — Two songs go head to head. Vote, watch live percentages update, resets every 24h.
- **Collab Playlist** — A group-shared playlist where every member can add songs. Powered by iTunes search.

### 🌍 Discovery & Social
- **Vibe Check** — A daily mood-match quiz. Tells you which friends you're most in sync with today.
- **Vybe Map** — A world map (CustomPainter) with animated pulsing dots showing where your circle is listening from.
- **Close Orbit** — Designate your closest friends for a prioritized inner circle feed.
- **Streak Shield** — Protect your listening streak from breaking (one free shield per period).

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.44.4 (stable) |
| Language | Dart |
| State Management | Singleton (`OrbitState`) |
| Audio | `just_audio 0.9.46` |
| Music Search | iTunes Search API |
| Image Picking | `image_picker 1.1.2` |
| Image Filters | `ColorFilter.matrix()` |
| Navigation | `IndexedStack` (4 tabs) |
| Maps | `CustomPainter` |
| Android Build | Gradle 8.13 + AGP 8.9.1 + Kotlin 2.1.0 |
| Min SDK | Android 5.0 (API 21) |

---

## 🗂️ Project Structure

```
lib/
├── main.dart                          # Entry point, app disguise check
├── theme/
│   └── aura_theme.dart               # Cream + orange palette
├── models/
│   └── orbit_state.dart              # Global singleton state
└── screens/
    ├── home/
    │   └── home_screen.dart          # Main feed
    ├── campfire/
    │   ├── campfire_screen.dart      # Group space list
    │   ├── campfire_chat_screen.dart # PIN-gated group chat
    │   ├── song_battle_screen.dart   # 24h song voting
    │   └── collab_playlist_screen.dart # Group shared playlist
    ├── find/
    │   └── find_screen.dart          # Discovery tab
    ├── profile/
    │   ├── profile_screen.dart       # Your profile
    │   ├── other_profile_screen.dart # Other user profiles
    │   ├── pfp_editor_screen.dart    # Photo + filter editor
    │   └── secret_vault_screen.dart  # PIN-gated private vybes
    ├── privacy/
    │   ├── privacy_screen.dart       # All privacy controls
    │   └── app_disguise_screen.dart  # Calculator disguise UI
    └── social/
        ├── vibe_check_screen.dart    # Daily mood match
        └── vybe_map_screen.dart      # World map with live dots
```

---

## 🎨 Design System

| Token | Value |
|---|---|
| Background | `#F4F0E8` (warm cream) |
| Accent | `#FF4500` (orange-red) |
| Accent Light | `#FF7A50` |
| Card | `#FFFFFF` |
| Font | System default (rounded) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Android Studio or VS Code
- Android SDK (API 21+)
- Java 17

### Run on Android

```bash
git clone https://github.com/Eswarmahendraj/Orbit.git
cd Orbit
flutter pub get
flutter run
```

### Build Release APK

```bash
flutter build apk --release --no-tree-shake-icons
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android Permissions Required

The following are declared in `AndroidManifest.xml`:
- `CAMERA` — PFP photo capture
- `READ_MEDIA_IMAGES` — Gallery access (Android 13+)
- `READ_EXTERNAL_STORAGE` — Gallery access (Android 12 and below)
- `INTERNET` — iTunes API + audio streaming

---

## 🍎 iOS Build (Mac Required)

1. Clone the repo on a Mac with Xcode installed
2. Run `flutter pub get`
3. Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to set your profile photo</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick a photo for your profile</string>
```
4. Open Xcode → set your Apple ID in Signing & Capabilities
5. Connect iPhone → `flutter run` or `flutter build ipa`

> Free Apple ID = 7-day re-sign limit. Apple Developer Program ($99/yr) removes this.

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  just_audio: ^0.9.46
  image_picker: ^1.1.2
  http: any
```

---

## 🔮 Roadmap

- [ ] Firebase backend (real users, real posts)
- [ ] Spotify / Apple Music integration
- [ ] Push notifications
- [ ] End-to-end encrypted DMs
- [ ] iOS App Store release

---

## 👤 Author

**Eswar Mahendra**
GitHub: [@Eswarmahendraj](https://github.com/Eswarmahendraj)

---

> *"Your vibe is your orbit."*
