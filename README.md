# 🌌 Orbit

**Orbit** is a Gen Z social music app built with Flutter + Firebase — where your vibe, your music taste, and your circle all connect in real time. Share what you're listening to, discover your sync partners, battle over songs, and explore 20+ social music features built for the way people actually listen.

> *"Your vibe is your orbit."*

---

## 📱 What is Orbit?

Orbit is a private social space built entirely around music. It's not a streaming app — it's the social layer on top of your listening. Share moments, battle songs, dare friends, co-listen live, match vibes, and track your music personality across every week.

---

## ✨ Features

### 🎵 Core Feed (Pulse)
- **Pulse Feed** — Share what you're listening to with your circle. Posts include song, mood, caption, and album art.
- **Vibe Check** — Daily mood with 20+ options. Filters your feed by emotional state.
- **Fire Reactions** — React to friends' posts with 🔥. Tap to open a DM thread.
- **Spotify Preview** — Songs play a 30-second preview inline in the feed.
- **Disappearing Vybes** — Posts auto-delete after 24 hours.
- **Song of the Moment** — Pin your current obsession to your profile.

### 🎙️ Social Music Features

#### 📸 Orbit Moment
BeReal-style daily music check-in. Post your song + mood once a day — see what your friends are listening to right now. Streams live from Firestore.

#### 🧩 Daily Music Puzzle
Guess the song from 5 emoji clues. 5 guesses max, 3 hint tiers, shake animation on wrong answers. Date-seeded so every user gets the same puzzle. Global leaderboard sorted by guesses then time.

#### 🌌 Orbit Wrapped (Weekly)
Your weekly music DNA card — top song, dominant vibe, sync partner, moments posted, battles won, puzzles solved. Shareable as text via share_plus.

#### 🎯 Song Dares
Dare a friend to listen to a song without skipping. They accept → listen → mark complete or admit they skipped. Dare streak tracked per friendship pair.

#### 💬 Hot Take Feed (Anonymous)
Drop anonymous music hot takes. Others agree or disagree. Featured "Take of the Day" for the highest-net-vote post. Starter prompt chips to get you going.

#### 🤖 NPC Song of the Day
Every day you're assigned a song persona — "today you're 'Espresso' by Sabrina Carpenter: chaotic, caffeinated, unapologetically extra." 20 personas, date-seeded so everyone gets the same one. Share your NPC on profile.

#### ⏳ Music Time Capsule
Lock a song + message to be revealed on a future date (1 week / 1 month / 3 months / 6 months). Send to yourself or a friend. Locked capsules show a countdown; opened ones reveal with a green gradient card.

#### 🎙️ Sound Rooms
Live co-listening rooms — like Clubhouse but for music. Host controls the queue and picks songs. Everyone in the room chats in real time. Live listener count. Steal the aux within a room via vote.

#### 💫 Vibe Match Swipe
Tinder-style swipe cards showing other users' top song + vibe + era. Swipe right → orbit sync. Mutual right swipes create an "Orbit Sync" match. View all your matches in the matches sheet.

#### 🧾 Orbit Receipts (Weekly)
Your weekly embarrassing music stats — guilty pleasure era, most skipped song, 2am habits, puzzle performance, battle record, moment energy. Presented as 6 swipeable cards with roast commentary.

#### 🔗 Listening Streak Chains
When you and a friend both post Orbit Moments for 7 consecutive days, a "Sync Chain" badge appears on both profiles. 7-dot visual calendar shows mutual days. Longest streak shown in a header card.

#### 🚩 Red Flag / Green Flag
Post a song — is it a red flag or a green flag personality indicator? Others vote. See live % bars after voting. Feed of all posts with caption and flag breakdown.

#### 🔥 Music Roast
Template-based AI-style roast of your listening history pulled from OrbitState — era, mood, streak, vibe status. Staggered reveal animation per line with a closing "verdict."

#### 🧾 Song Receipt
Monthly stats formatted as a paper receipt — era alignment, vibe score, posts, moments, battles, puzzles. Funny generated copy, fake barcode, monospace font, yellow paper aesthetic. Shareable.

#### 💀 The Daily Drop
One song, every day, for everyone. Date-seeded from a curated list. Join → hear the preview → react with 8 emojis. Live emoji counts stream from Firestore in real time.

#### 👁️ Blindspot
Anonymous nearby listener discovery. Register your anonymous ID. Send songs to anonymous IDs. Reveal each other for a mutual reveal. Animated pulsing dots show active anonymous listeners.

#### 🤫 Song Secret
Send a secret song to a friend anonymously. Both sides choose reveal emojis. When both reveal, you see who sent it. Reply with your own secret song. "Listening Without You" widget shows when you and a friend both heard the same song today.

### 🔥 Campfire (Group Spaces)
- **Secret Campfire** — Invite-only group spaces.
- **Campfire Chat** — Real-time group chat inside a campfire.
- **Song Battle** — Two songs head to head. Vote live, percentages update in real time. Resets every 24h. Win tracking in your orbit stats.
- **Collab Playlist** — Group-shared playlist where every member adds songs.
- **Steal the Aux** — Current DJ holds the aux for 30 minutes. 3 votes in 30 seconds = aux stolen. New DJ picks a song.

### 🌍 Discovery
- **Vybe Map** — CustomPainter world map with animated pulsing dots showing where your circle is listening from.
- **Activity Feed** — All reactions, syncs, and follows from your orbit in one stream.
- **Orbit Confessions** — Anonymous music confessions from your circle.

### 👤 Profile & Identity
- **Era Mode** — Pick your current musical era (15 options: brat summer, villain era, healing arc, main character, etc.). Shows as a gradient badge on your profile.
- **NPC Song Badge** — Today's NPC song persona shown on your profile card.
- **NPC Mode Toggle** — Go into NPC mode for 24 hours (robot emoji, minimal presence).
- **Orbit Stats Card** — Monthly stats: posts, syncs, battles won, puzzles solved.
- **Music Taste Compatibility** — % compatibility score when viewing other users' profiles.
- **Real-time Vibe Status** — Your current vibe updates live on your profile for friends to see.
- **Profile Photo Upload** — Upload to Firebase Storage, shown across the app.
- **QR Profile Share** — Share your profile as a scannable QR code.

### 💬 Messaging
- **Real-time DMs** — Firestore-backed 1:1 chat with instant delivery.
- **Push Notifications** — FCM push for new messages and reactions.
- **Reaction DM Thread** — React to a song → opens a DM thread automatically.

### ⚙️ Settings & Notifications
- **Notification Mode** — All / Mentions Only / None.
- **Skip Stats** — Tracks how many times you've skipped each song (stored in OrbitState).

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.44.4 (stable) |
| Language | Dart 3.x |
| Backend | Firebase (Auth + Firestore + Storage + Messaging) |
| State | Singleton (`OrbitState`) + SharedPreferences |
| Audio | `just_audio` |
| Music Search | Spotify Web API |
| Images | `cached_network_image`, `image_picker` |
| Sharing | `share_plus` |
| Navigation | `IndexedStack` (4 tabs) + `Navigator.push` |
| Maps | `CustomPainter` |
| Android Build | Gradle 8.13 + AGP 8.9.1 + Kotlin 2.1.0 |
| Min SDK | Android 5.0 (API 21) |

---

## 🗂️ Project Structure

```
lib/
├── main.dart
├── theme/
│   └── aura_theme.dart               # Dark palette — background, card, surface, accent
├── models/
│   └── orbit_state.dart              # Global singleton (era, mood, NPC mode, skip stats…)
├── services/
│   ├── spotify_service.dart          # Spotify search + preview
│   ├── notification_service.dart     # FCM push
│   └── storage_service.dart          # Firebase Storage uploads
└── screens/
    ├── home/
    │   ├── home_screen.dart          # Main feed + daily drop banner + discover row
    │   ├── create_vybe_screen.dart
    │   ├── dm_screen.dart
    │   └── activity_feed_screen.dart
    ├── reels/
    │   └── pulse_screen.dart         # Pulse feed + orbit moment FAB + battle entry
    ├── campfire/
    │   ├── campfire_screen.dart
    │   ├── campfire_chat_screen.dart
    │   ├── song_battle_screen.dart
    │   ├── collab_playlist_screen.dart
    │   └── steal_aux_widget.dart     # Embeddable DJ steal mechanic
    ├── profile/
    │   ├── profile_screen.dart       # Profile + era badge + NPC mode toggle
    │   ├── other_profile_screen.dart # Other users + compatibility score
    │   ├── era_picker_sheet.dart     # 15 era options with gradients
    │   └── settings_screen.dart
    └── social/
        ├── orbit_moment_screen.dart  # BeReal-style daily check-in
        ├── daily_puzzle_screen.dart  # Emoji-to-song puzzle + leaderboard
        ├── orbit_wrapped_screen.dart # Weekly stats card
        ├── song_receipt_screen.dart  # Monthly receipt format
        ├── red_flag_screen.dart      # Red/green flag voting
        ├── music_roast_screen.dart   # Template roast reveal
        ├── daily_drop_screen.dart    # Daily curated song + reactions
        ├── blindspot_screen.dart     # Anonymous listener discovery
        ├── song_secret_screen.dart   # Anonymous song sharing
        ├── hot_take_screen.dart      # Anonymous music hot takes
        ├── npc_song_screen.dart      # Daily NPC song persona
        ├── time_capsule_screen.dart  # Future-date song lock
        ├── song_dare_screen.dart     # Dare a friend to listen
        ├── sound_room_screen.dart    # Live co-listening rooms
        ├── vibe_match_screen.dart    # Tinder-style vibe swipe
        ├── orbit_receipts_screen.dart # Weekly embarrassing stats
        ├── streak_chain_screen.dart  # 7-day mutual moment streak
        ├── vybe_map_screen.dart
        └── confessions_screen.dart
```

---

## 🎨 Design System

| Token | Value |
|---|---|
| Background | `#0A0A0A` (near-black) |
| Card | `#141414` |
| Surface | `#1C1C1C` |
| Accent | `#7B2FF7` (purple) |
| Text Muted | `rgba(255,255,255,0.4)` |
| Font | System default |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.44.4 (`flutter --version`)
- Android Studio or VS Code
- Firebase project with Auth + Firestore + Storage + Messaging enabled
- Spotify Developer credentials (client ID + secret)

### Run on Android

```bash
git clone https://github.com/Eswarmahendraj/Orbit.git
cd Orbit
flutter pub get
flutter run
```

### Build Release AAB

```bash
flutter build appbundle --release --no-tree-shake-icons
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build Release APK

```bash
flutter build apk --release --no-tree-shake-icons
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔥 Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | User profiles, vibe, era, top song |
| `pulse_posts` | Feed posts |
| `follows` | Friend/follow graph |
| `battles` | Song battle votes |
| `orbit_moments` | Daily BeReal-style check-ins |
| `puzzle_scores` | Daily puzzle results + leaderboard |
| `song_dares` | Dare inbox/sent |
| `song_secrets` | Anonymous song secrets |
| `blindspot_messages` | Anonymous song drops |
| `blindspot_presence` | Anonymous listener registry |
| `hot_takes` | Anonymous music hot takes |
| `time_capsules` | Future-locked song messages |
| `sound_rooms` | Live co-listening rooms |
| `vibe_match_swipes` | Swipe history per user |
| `vibe_match_matches` | Mutual orbit sync matches |
| `streak_chains` | 7-day mutual moment streaks |
| `redflag_posts` | Red/green flag votes |
| `daily_drop_reactions` | Daily drop emoji reactions |
| `campfire_aux` | Current DJ + steal votes |
| `_notifications` | FCM push targets |

---

## 📦 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_storage: ^12.x
  firebase_messaging: ^15.x
  just_audio: ^0.9.x
  cached_network_image: ^3.3.1
  image_picker: ^1.1.x
  share_plus: ^10.x
  shared_preferences: ^2.x
  http: any
```

---

## 👤 Author

**Eswar Mahendra**  
GitHub: [@Eswarmahendraj](https://github.com/Eswarmahendraj)

---

> *"Your vibe is your orbit."*
