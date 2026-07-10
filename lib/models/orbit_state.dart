import 'dart:io';

/// Global singleton — all feature flags, privacy settings, profile state.
class OrbitState {
  static final OrbitState _i = OrbitState._();
  factory OrbitState() => _i;
  OrbitState._();

  // ── Privacy ───────────────────────────────────────────────
  bool ghostMode = false;
  bool stealthView = false;
  bool antiCreepShield = true;
  String lastSeenMode = 'friends'; // everyone | friends | hidden
  bool screenshotBlock = false;
  bool appDisguiseEnabled = false;
  String? dmPasscode; // 4-digit PIN

  // ── Profile / PFP ─────────────────────────────────────────
  File? pfpFile;
  String pfpFilter = 'none'; // none|warm|cool|noir|rose|golden|fade|vivid

  // ── Mood ──────────────────────────────────────────────────
  String mood = 'chill';
  String moodEmoji = '☀️';
  bool moodMaskEnabled = false;
  String moodMaskPublic = 'focused';
  String moodMaskPublicEmoji = '🎧';

  // ── Social ────────────────────────────────────────────────
  Set<String> closeOrbit = {'@maya.k', '@zara.w'};
  bool streakShieldAvailable = true;
  bool vibeCheckDoneToday = false;
  Set<String> blockedSongs = {};

  // ── Sync levels (mock) ────────────────────────────────────
  // 'bronze' | 'silver' | 'gold' | 'platinum'
  Map<String, String> syncLevels = {
    '@maya.k': 'platinum',
    '@zara.w': 'gold',
    '@dev.s': 'silver',
    '@rina.p': 'bronze',
    '@jay.r': 'gold',
  };
}
