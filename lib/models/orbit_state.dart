import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart' show ThemeMode;
import '../theme/aura_theme.dart';

class OrbitState {
  static final OrbitState _i = OrbitState._();
  factory OrbitState() => _i;
  OrbitState._();

  // Onboarding
  bool hasOnboarded = false;

  // Profile
  String displayName = 'You';
  String username = '@you';
  String bio = '';
  File? pfpFile;
  String? pfpUrl;   // Firebase Storage download URL (visible to other users)
  String pfpFilter = 'none';

  // Mood
  String mood = 'chill';
  String moodEmoji = '☀️';
  bool moodMaskEnabled = false;
  String moodMaskPublic = 'focused';
  String moodMaskPublicEmoji = '🎧';

  // Appearance
  bool darkMode = false;

  // Privacy
  bool ghostMode = false;
  bool stealthView = false;
  bool antiCreepShield = true;
  String lastSeenMode = 'friends';
  bool screenshotBlock = false;
  bool appDisguiseEnabled = false;
  String? dmPasscode;

  // Streak
  int streakCount = 0;
  String lastActiveDate = '';

  // Song of the Day
  bool sotdReactedToday = false;
  String sotdLastDate = '';
  int sotdReactionCount = 12; // seed count

  // Vibe Song (24h status shown on profile)
  String vibeSong = '';
  String vibeArtist = '';
  String? vibeArtUrl;
  String vibeSetAt = '';

  bool get vibeActive {
    if (vibeSong.isEmpty || vibeSetAt.isEmpty) return false;
    final set = DateTime.tryParse(vibeSetAt);
    if (set == null) return false;
    return DateTime.now().difference(set).inHours < 24;
  }

  // Hours remaining on the current vibe song (0 if expired)
  int get vibeHoursLeft {
    if (!vibeActive) return 0;
    final set = DateTime.tryParse(vibeSetAt)!;
    final exp = set.add(const Duration(hours: 24));
    return exp.difference(DateTime.now()).inHours;
  }

  void setVibeSong(String song, String artist, {String? artUrl}) {
    vibeSong = song;
    vibeArtist = artist;
    vibeArtUrl = artUrl;
    vibeSetAt = DateTime.now().toIso8601String();
    save();
  }

  void clearVibeSong() {
    vibeSong = '';
    vibeArtist = '';
    vibeArtUrl = null;
    vibeSetAt = '';
    save();
  }

  // Always vibes — permanent, up to 3, never expire
  // Each entry: {'emoji': '🎧', 'label': 'in the zone'}
  List<Map<String, String>> alwaysVibes = [];

  // LGBTQ+ identity tags — private by default
  List<String> identityTags = [];
  bool identityTagsPublic = false;

  // Social
  Set<String> closeOrbit = {'@maya.k', '@zara.w'};
  bool streakShieldAvailable = true;
  bool vibeCheckDoneToday = false;
  Set<String> blockedSongs = {};
  Map<String, String> syncLevels = {
    '@maya.k': 'platinum',
    '@zara.w': 'gold',
    '@dev.s': 'silver',
    '@rina.p': 'bronze',
    '@jay.r': 'gold',
  };

  // User content (persisted)
  List<Map<String, dynamic>> myPosts = [];
  List<Map<String, dynamic>> myCampfires = [];
  Map<String, List<Map<String, dynamic>>> dmThreads = {};

  // Clip streaks — per friendship (keyed by handle)
  Map<String, Map<String, dynamic>> clipStreaks = {};

  // Moments — daily streak posts
  int momentStreak = 0;
  String lastMomentDate = '';
  List<Map<String, dynamic>> myMoments = [];

  // Pinned song of the moment
  String pinnedSong = '';
  String pinnedArtist = '';
  String pinnedPreviewUrl = '';

  // Real-time vibe status
  String vibeStatus = '';
  String vibeStatusEmoji = '';

  // Notification mode: 'push' (banner+sound), 'sound' (chime only), 'off'
  String notifMode = 'push';

  // Era Mode — Gen Z identity tag
  String currentEra = '';      // e.g. 'villain era'
  String currentEraEmoji = ''; // e.g. '🖤'

  // NPC Mode — 24h invisibility (named after Gen Z NPC meme)
  bool npcModeActive = false;
  String npcModeExpiresAt = ''; // ISO8601

  bool get npcModeExpired {
    if (!npcModeActive || npcModeExpiresAt.isEmpty) return true;
    final exp = DateTime.tryParse(npcModeExpiresAt);
    if (exp == null) return true;
    return DateTime.now().isAfter(exp);
  }

  void activateNpcMode() {
    npcModeActive = true;
    npcModeExpiresAt =
        DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    save();
  }

  void deactivateNpcMode() {
    npcModeActive = false;
    npcModeExpiresAt = '';
    save();
  }

  // Skip Stats — track how many times a song was skipped before giving in
  // key: 'song|artist', value: skip count
  Map<String, int> songSkips = {};

  void recordSkip(String song, String artist) {
    final key = '$song|$artist';
    songSkips[key] = (songSkips[key] ?? 0) + 1;
    save();
  }

  int getSkips(String song, String artist) =>
      songSkips['$song|$artist'] ?? 0;

  // Anonymous orbit confessions (user-posted)
  List<Map<String, dynamic>> orbitConfessions = [];

  bool get postedMomentToday =>
      lastMomentDate == _dateStr(DateTime.now());

  // ── Streak logic ──────────────────────────────────────────────
  void checkStreak() {
    final today = _dateStr(DateTime.now());
    if (lastActiveDate.isEmpty) {
      streakCount = 1;
      lastActiveDate = today;
      save();
      return;
    }
    if (lastActiveDate == today) return; // already counted today
    final last = DateTime.parse(lastActiveDate);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 1) {
      streakCount++;
    } else if (diff > 1) {
      streakCount = 1; // reset
    }
    lastActiveDate = today;
    save();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Moment streak logic ───────────────────────────────────────
  void checkMomentStreak() {
    final today = _dateStr(DateTime.now());
    if (lastMomentDate == today) return; // already posted today
    if (lastMomentDate.isEmpty) {
      momentStreak = 1;
    } else {
      final last = DateTime.tryParse(lastMomentDate);
      if (last != null) {
        final diff = DateTime.now().difference(last).inDays;
        momentStreak = diff == 1 ? momentStreak + 1 : 1;
      } else {
        momentStreak = 1;
      }
    }
    lastMomentDate = today;
    save();
  }

  void addMoment(Map<String, dynamic> moment) {
    myMoments.insert(0, moment);
    checkMomentStreak();
    save();
  }

  void reactSotd() {
    final today = _dateStr(DateTime.now());
    if (sotdLastDate != today) {
      sotdReactedToday = false;
      sotdLastDate = today;
    }
    if (!sotdReactedToday) {
      sotdReactedToday = true;
      sotdReactionCount++;
      save();
    }
  }

  // ── Persistence ───────────────────────────────────────────────
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    hasOnboarded = p.getBool('hasOnboarded') ?? false;
    displayName = p.getString('displayName') ?? 'You';
    username = p.getString('username') ?? '@you';
    bio = p.getString('bio') ?? '';
    pfpFilter = p.getString('pfpFilter') ?? 'none';
    pfpUrl = p.getString('pfpUrl');
    mood = p.getString('mood') ?? 'chill';
    moodEmoji = p.getString('moodEmoji') ?? '☀️';
    darkMode = p.getBool('darkMode') ?? false;
    AuraTheme.isDark = darkMode;
    ghostMode = p.getBool('ghostMode') ?? false;
    stealthView = p.getBool('stealthView') ?? false;
    antiCreepShield = p.getBool('antiCreepShield') ?? true;
    lastSeenMode = p.getString('lastSeenMode') ?? 'friends';
    screenshotBlock = p.getBool('screenshotBlock') ?? false;
    appDisguiseEnabled = p.getBool('appDisguiseEnabled') ?? false;
    dmPasscode = p.getString('dmPasscode');
    streakShieldAvailable = p.getBool('streakShieldAvailable') ?? true;
    streakCount = p.getInt('streakCount') ?? 0;
    lastActiveDate = p.getString('lastActiveDate') ?? '';
    sotdReactedToday = p.getBool('sotdReactedToday') ?? false;
    sotdLastDate = p.getString('sotdLastDate') ?? '';
    sotdReactionCount = p.getInt('sotdReactionCount') ?? 12;
    vibeSong = p.getString('vibeSong') ?? '';
    vibeArtist = p.getString('vibeArtist') ?? '';
    vibeArtUrl = p.getString('vibeArtUrl');
    vibeSetAt = p.getString('vibeSetAt') ?? '';
    final pfpPath = p.getString('pfpPath');
    if (pfpPath != null && File(pfpPath).existsSync()) pfpFile = File(pfpPath);
    final postsRaw = p.getString('myPosts');
    if (postsRaw != null) {
      myPosts = List<Map<String, dynamic>>.from(jsonDecode(postsRaw));
    }
    final campfiresRaw = p.getString('myCampfires');
    if (campfiresRaw != null) {
      myCampfires = List<Map<String, dynamic>>.from(jsonDecode(campfiresRaw));
    }
    final dmsRaw = p.getString('dmThreads');
    if (dmsRaw != null) {
      final raw = jsonDecode(dmsRaw) as Map<String, dynamic>;
      dmThreads = raw.map(
        (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
      );
    }
    final clipsRaw = p.getString('clipStreaks');
    if (clipsRaw != null) {
      final raw = jsonDecode(clipsRaw) as Map<String, dynamic>;
      clipStreaks = raw.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    }
    final alwaysRaw = p.getString('alwaysVibes');
    if (alwaysRaw != null) {
      final list = jsonDecode(alwaysRaw) as List;
      alwaysVibes = list.map((e) => Map<String, String>.from(e as Map)).toList();
    }
    final tagsRaw = p.getString('identityTags');
    if (tagsRaw != null) {
      identityTags = List<String>.from(jsonDecode(tagsRaw));
    }
    identityTagsPublic = p.getBool('identityTagsPublic') ?? false;
    notifMode = p.getString('notifMode') ?? 'push';
    currentEra = p.getString('currentEra') ?? '';
    currentEraEmoji = p.getString('currentEraEmoji') ?? '';
    npcModeActive = p.getBool('npcModeActive') ?? false;
    npcModeExpiresAt = p.getString('npcModeExpiresAt') ?? '';
    final skipsRaw = p.getString('songSkips');
    if (skipsRaw != null) {
      final raw = jsonDecode(skipsRaw) as Map<String, dynamic>;
      songSkips = raw.map((k, v) => MapEntry(k, v as int));
    }
    momentStreak = p.getInt('momentStreak') ?? 0;
    lastMomentDate = p.getString('lastMomentDate') ?? '';
    pinnedSong = p.getString('pinnedSong') ?? '';
    pinnedArtist = p.getString('pinnedArtist') ?? '';
    pinnedPreviewUrl = p.getString('pinnedPreviewUrl') ?? '';
    vibeStatus = p.getString('vibeStatus') ?? '';
    vibeStatusEmoji = p.getString('vibeStatusEmoji') ?? '';
    final confessionsRaw = p.getString('orbitConfessions');
    if (confessionsRaw != null) {
      orbitConfessions = List<Map<String, dynamic>>.from(jsonDecode(confessionsRaw));
    }
    final momentsRaw = p.getString('myMoments');
    if (momentsRaw != null) {
      myMoments = List<Map<String, dynamic>>.from(jsonDecode(momentsRaw));
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('hasOnboarded', hasOnboarded);
    await p.setString('displayName', displayName);
    await p.setString('username', username);
    await p.setString('bio', bio);
    await p.setString('pfpFilter', pfpFilter);
    await p.setString('mood', mood);
    await p.setString('moodEmoji', moodEmoji);
    await p.setBool('darkMode', darkMode);
    await p.setBool('ghostMode', ghostMode);
    await p.setBool('stealthView', stealthView);
    await p.setBool('antiCreepShield', antiCreepShield);
    await p.setString('lastSeenMode', lastSeenMode);
    await p.setBool('screenshotBlock', screenshotBlock);
    await p.setBool('appDisguiseEnabled', appDisguiseEnabled);
    if (dmPasscode != null) await p.setString('dmPasscode', dmPasscode!);
    await p.setBool('streakShieldAvailable', streakShieldAvailable);
    await p.setInt('streakCount', streakCount);
    await p.setString('lastActiveDate', lastActiveDate);
    await p.setBool('sotdReactedToday', sotdReactedToday);
    await p.setString('sotdLastDate', sotdLastDate);
    await p.setInt('sotdReactionCount', sotdReactionCount);
    if (pfpFile != null) await p.setString('pfpPath', pfpFile!.path);
    if (pfpUrl != null) await p.setString('pfpUrl', pfpUrl!); else await p.remove('pfpUrl');
    await p.setString('vibeSong', vibeSong);
    await p.setString('vibeArtist', vibeArtist);
    if (vibeArtUrl != null) await p.setString('vibeArtUrl', vibeArtUrl!);
    await p.setString('vibeSetAt', vibeSetAt);
    await p.setString('myPosts', jsonEncode(myPosts));
    await p.setString('myCampfires', jsonEncode(myCampfires));
    await p.setString('dmThreads', jsonEncode(dmThreads));
    await p.setString('clipStreaks', jsonEncode(clipStreaks));
    await p.setString('alwaysVibes', jsonEncode(alwaysVibes));
    await p.setString('identityTags', jsonEncode(identityTags));
    await p.setBool('identityTagsPublic', identityTagsPublic);
    await p.setInt('momentStreak', momentStreak);
    await p.setString('lastMomentDate', lastMomentDate);
    await p.setString('pinnedSong', pinnedSong);
    await p.setString('pinnedArtist', pinnedArtist);
    await p.setString('pinnedPreviewUrl', pinnedPreviewUrl);
    await p.setString('vibeStatus', vibeStatus);
    await p.setString('vibeStatusEmoji', vibeStatusEmoji);
    await p.setString('notifMode', notifMode);
    await p.setString('currentEra', currentEra);
    await p.setString('currentEraEmoji', currentEraEmoji);
    await p.setBool('npcModeActive', npcModeActive);
    await p.setString('npcModeExpiresAt', npcModeExpiresAt);
    await p.setString('songSkips', jsonEncode(songSkips));
    await p.setString('orbitConfessions', jsonEncode(orbitConfessions));
    await p.setString('myMoments', jsonEncode(myMoments));
  }

  void addPost(Map<String, dynamic> post) {
    myPosts.insert(0, post);
    save();
  }

  void removePost(String id) {
    myPosts.removeWhere((p) => p['id'] == id);
    save();
  }

  void addCampfire(Map<String, dynamic> campfire) {
    myCampfires.insert(0, campfire);
    save();
  }

  // ── Song Clip feature ─────────────────────────────────────────

  /// Send a clip message and record the streak contribution
  void sendClip(
    String handle, {
    required String song,
    required String artist,
    String? artUrl,
    String? previewUrl,
    required double clipStart,
    required double clipEnd,
  }) {
    dmThreads[handle] ??= [];
    dmThreads[handle]!.add({
      'type': 'clip',
      'song': song,
      'artist': artist,
      'artUrl': artUrl,
      'previewUrl': previewUrl,
      'clipStart': clipStart,
      'clipEnd': clipEnd,
      'isMe': true,
      'time': DateTime.now().toIso8601String(),
    });
    recordClipSent(handle);
    save();
  }

  void recordClipSent(String handle) {
    _initClipStreak(handle);
    clipStreaks[handle]!['lastSentDate'] = _dateStr(DateTime.now());
    _checkClipStreak(handle);
    save();
  }

  void recordClipReceived(String handle) {
    _initClipStreak(handle);
    clipStreaks[handle]!['lastReceivedDate'] = _dateStr(DateTime.now());
    _checkClipStreak(handle);
    save();
  }

  void _initClipStreak(String handle) {
    clipStreaks[handle] ??= {
      'streakCount': 0,
      'bestStreak': 0,
      'lastSentDate': '',
      'lastReceivedDate': '',
      'mutualDates': <String>[],
    };
  }

  void _checkClipStreak(String handle) {
    final data = clipStreaks[handle]!;
    final today = _dateStr(DateTime.now());
    if (data['lastSentDate'] != today) return;
    if (data['lastReceivedDate'] != today) return;

    final mutual = List<String>.from(data['mutualDates'] ?? []);
    if (mutual.contains(today)) return;

    mutual.add(today);
    mutual.sort();
    data['mutualDates'] = mutual;

    int streak = 1;
    for (int i = mutual.length - 1; i > 0; i--) {
      final a = DateTime.parse(mutual[i]);
      final b = DateTime.parse(mutual[i - 1]);
      if (a.difference(b).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    data['streakCount'] = streak;
    if (streak > (data['bestStreak'] as int? ?? 0)) {
      data['bestStreak'] = streak;
    }
  }

  void sendDM(String user, String text, {bool isMe = true}) {
    dmThreads[user] ??= [];
    dmThreads[user]!.add({
      'text': text,
      'isMe': isMe,
      'time': DateTime.now().toIso8601String(),
    });
    save();
  }
}
