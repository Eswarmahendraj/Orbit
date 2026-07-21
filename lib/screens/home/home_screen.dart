import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../campfire/song_battle_screen.dart';
import '../profile/other_profile_screen.dart';
import '../social/vybe_map_screen.dart';
import 'create_vybe_screen.dart';
import 'dm_screen.dart';
import 'activity_feed_screen.dart';
import '../social/confessions_screen.dart';
import '../social/daily_puzzle_screen.dart';
import '../social/orbit_wrapped_screen.dart';
import '../social/song_receipt_screen.dart';
import '../social/music_roast_screen.dart';
import '../social/red_flag_screen.dart';
import '../social/daily_drop_screen.dart';
import '../social/blindspot_screen.dart';
import '../social/song_secret_screen.dart';
import '../social/hot_take_screen.dart';
import '../social/npc_song_screen.dart';
import '../social/time_capsule_screen.dart';
import '../social/song_dare_screen.dart';
import '../social/sound_room_screen.dart';
import '../social/vibe_match_screen.dart';
import '../social/orbit_receipts_screen.dart';
import '../social/streak_chain_screen.dart';

// ── Data models ────────────────────────────────────────────────

class _Story {
  final String name, handle, initial;
  final Color color;
  final bool live;
  final String? nowSong;
  const _Story(this.name, this.handle, this.color, this.initial,
      {this.live = false, this.nowSong});
}

class _Post {
  final String handle, displayName, initial;
  final Color userColor;
  final String mood, moodEmoji, songTitle, artistName;
  final String? artUrl, previewUrl, caption, moodTag, photoPath;
  int fires;
  final String timeAgo;
  final DateTime? expiresAt;
  bool fireReacted;
  final bool isOwn;

  _Post({
    required this.handle,
    required this.displayName,
    required this.userColor,
    required this.initial,
    required this.mood,
    required this.moodEmoji,
    required this.songTitle,
    required this.artistName,
    this.artUrl,
    this.previewUrl,
    this.caption,
    this.photoPath,
    required this.fires,
    required this.timeAgo,
    this.moodTag,
    this.expiresAt,
    this.fireReacted = false,
    this.isOwn = false,
  });
}

// ── HomeScreen ─────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) => const _FeedTab();
}

// ── Feed Tab ───────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _moodFilter; // null = show all

  static const _stories = [
    _Story('maya', '@maya.k', Color(0xFFFF8C42), 'M',
        live: true, nowSong: 'Espresso'),
    _Story('zara', '@zara.w', Color(0xFF6C63FF), 'Z'),
    _Story('dev', '@dev.s', Color(0xFFFF7A50), 'D',
        live: true, nowSong: 'APT.'),
    _Story('rina', '@rina.p', Color(0xFF00B894), 'R'),
    _Story('jay', '@jay.r', Color(0xFFE17055), 'J',
        live: true, nowSong: 'luther'),
    _Story('leo', '@leo.m', Color(0xFF74B9FF), 'L'),
  ];

  late List<_Post> _friendPosts;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _buildFriendPosts();
  }

  void _buildFriendPosts() {
    _friendPosts = [
      _Post(
          handle: '@maya.k',
          displayName: 'maya',
          userColor: const Color(0xFFFF8C42),
          initial: 'M',
          mood: 'chill',
          moodEmoji: '☀️',
          songTitle: 'Espresso',
          artistName: 'Sabrina Carpenter',
          fires: 47,
          timeAgo: '2m ago',
          moodTag: 'hype',
          caption: 'this has been on repeat all morning ☀️',
          expiresAt: DateTime.now().add(const Duration(hours: 18, minutes: 42))),
      _Post(
          handle: '@zara.w',
          displayName: 'zara',
          userColor: const Color(0xFF6C63FF),
          initial: 'Z',
          mood: 'nostalgic',
          moodEmoji: '🌙',
          songTitle: 'Die With A Smile',
          artistName: 'Lady Gaga & Bruno Mars',
          fires: 83,
          timeAgo: '14m ago',
          moodTag: 'nostalgic',
          caption: 'every single lyric hits different at 2am'),
      _Post(
          handle: '@dev.s',
          displayName: 'dev',
          userColor: const Color(0xFFFF7A50),
          initial: 'D',
          mood: 'hyped',
          moodEmoji: '⚡',
          songTitle: 'APT.',
          artistName: 'ROSE & Bruno Mars',
          fires: 122,
          timeAgo: '31m ago',
          moodTag: '2am'),
      _Post(
          handle: '@jay.r',
          displayName: 'jay',
          userColor: const Color(0xFFE17055),
          initial: 'J',
          mood: 'sad',
          moodEmoji: '🌧️',
          songTitle: 'luther',
          artistName: 'Kendrick Lamar & SZA',
          fires: 56,
          timeAgo: '1h ago',
          moodTag: 'heartbreak'),
      _Post(
          handle: '@rina.p',
          displayName: 'rina',
          userColor: const Color(0xFF00B894),
          initial: 'R',
          mood: 'chill',
          moodEmoji: '☀️',
          songTitle: 'Espresso',
          artistName: 'Sabrina Carpenter',
          fires: 39,
          timeAgo: '2h ago',
          moodTag: 'cozy',
          caption: 'golden mornings deserve golden songs'),
    ];
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  List<_Post> _userPosts() {
    final s = OrbitState();
    return s.myPosts.map((p) {
      final exp = p['disappearing'] == true
          ? DateTime.parse(p['time']).add(const Duration(hours: 24))
          : null;
      if (exp != null && exp.isBefore(DateTime.now())) return null;
      return _Post(
        handle: p['username'] ?? s.username,
        displayName: p['user'] ?? s.displayName,
        userColor: AuraTheme.accent,
        initial: (p['user'] ?? s.displayName).isNotEmpty
            ? (p['user'] ?? s.displayName)[0].toUpperCase()
            : 'Y',
        mood: s.mood,
        moodEmoji: s.moodEmoji,
        songTitle: p['song'] ?? '',
        artistName: p['artist'] ?? '',
        artUrl: p['art'],
        previewUrl: p['preview'],
        caption: p['caption'],
        photoPath: p['photo'] as String?,
        fires: (p['fires'] ?? 0) as int,
        timeAgo: _ago(DateTime.parse(p['time'])),
        moodTag: p['tag'],
        expiresAt: exp,
        isOwn: true,
      );
    }).whereType<_Post>().toList();
  }

  List<_Post> _allPosts() {
    final blocked = OrbitState().blockedSongs;
    final visible =
        _friendPosts.where((p) => !blocked.contains(p.songTitle)).toList();
    return [..._userPosts(), ...visible];
  }

  List<_Post> _moodFiltered(List<_Post> posts) {
    if (_moodFilter == null) return posts;
    return posts.where((p) => p.mood == _moodFilter).toList();
  }

  // Top 3 songs by friend post count
  List<Map<String, dynamic>> _hotSongs() {
    final map = <String, Map<String, dynamic>>{};
    for (final p in _friendPosts) {
      map.putIfAbsent(p.songTitle,
          () => {'song': p.songTitle, 'artist': p.artistName, 'count': 0});
      map[p.songTitle]!['count'] =
          (map[p.songTitle]!['count'] as int) + 1;
    }
    return (map.values.toList()
          ..sort((a, b) =>
              (b['count'] as int).compareTo(a['count'] as int)))
        .take(3)
        .toList();
  }

  // First song shared by 2+ friends
  _Post? _matchSong() {
    final map = <String, List<_Post>>{};
    for (final p in _friendPosts) {
      map.putIfAbsent(p.songTitle, () => []).add(p);
    }
    for (final entry in map.entries) {
      if (entry.value.length >= 2) return entry.value.first;
    }
    return null;
  }

  List<_Post> _matchFriends(String song) =>
      _friendPosts.where((p) => p.songTitle == song).take(2).toList();

  bool _postedToday() {
    final posts = OrbitState().myPosts;
    if (posts.isEmpty) return false;
    return DateTime.parse(posts.first['time'])
        .isAfter(DateTime.now().subtract(const Duration(hours: 24)));
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _buildFriendPosts();
    if (mounted) setState(() {});
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const CreateVybeScreen()));
    if (created == true && mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final userInitial = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'Y';

    return Scaffold(
      backgroundColor: AuraTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AuraTheme.accent,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            backgroundColor: AuraTheme.background,
            title: const Text('orbit',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            actions: [
              // Daily puzzle
              IconButton(
                tooltip: 'Daily Puzzle',
                icon: const Text('🧩', style: TextStyle(fontSize: 20)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DailyPuzzleScreen())),
              ),
              // Orbit Wrapped
              IconButton(
                tooltip: 'Orbit Wrapped',
                icon: const Text('🌌', style: TextStyle(fontSize: 20)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OrbitWrappedScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: AuraTheme.accent),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VybeMapScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.bolt_rounded,
                    color: AuraTheme.accent, size: 26),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SongBattleScreen())),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ActivityFeedScreen())),
                  ),
                  // New-activity badge
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AuraTheme.accent, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(child: _storiesRow(userInitial, state)),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabs,
              indicatorColor: AuraTheme.accent,
              labelColor: AuraTheme.accent,
              unselectedLabelColor: AuraTheme.textMuted,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'friends'),
                Tab(text: 'trending'),
                Tab(text: 'for you'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _friendsTab(),
            _trendingTab(),
            _forYouTab(),
          ],
        ),
      ),
    );
  }

  // ── Stories Row ────────────────────────────────────────────

  Widget _storiesRow(String userInitial, OrbitState state) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // Your bubble
          GestureDetector(
            onTap: _openCreate,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AuraTheme.accent, width: 2),
                        color: AuraTheme.surface,
                        image: state.pfpFile != null
                            ? DecorationImage(
                                image: FileImage(state.pfpFile!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: state.pfpFile == null
                          ? Center(
                              child: Text(userInitial,
                                  style: const TextStyle(
                                      color: AuraTheme.accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                            color: AuraTheme.accent,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text('you',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AuraTheme.accent)),
                ],
              ),
            ),
          ),
          // Friend bubbles
          ..._stories.map((s) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtherProfileScreen(
                      name: s.name,
                      handle: s.handle,
                      userColor: s.color,
                      initial: s.initial,
                      mood: 'chill',
                      moodEmoji: '☀️',
                      songTitle: s.nowSong ?? 'Golden Hour',
                      artistName: 'JVKE',
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [
                                  s.color,
                                  s.color.withOpacity(0.4)
                                ]),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.5),
                            child: CircleAvatar(
                              backgroundColor: s.color.withOpacity(0.18),
                              child: Text(s.initial,
                                  style: TextStyle(
                                      color: s.color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18)),
                            ),
                          ),
                        ),
                        if (s.live)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D26A),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AuraTheme.background,
                                    width: 2),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 3),
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AuraTheme.textSecondary)),
                      // Now playing badge under live stories
                      if (s.live && s.nowSong != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                              color: AuraTheme.accent,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            s.nowSong!,
                            style: const TextStyle(
                                fontSize: 7,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Tab: Friends ───────────────────────────────────────────

  Widget _friendsTab() {
    final posts = _moodFiltered(_allPosts());
    final hot = _hotSongs();
    final match = _matchSong();
    final state = OrbitState();

    return RefreshIndicator(
      color: AuraTheme.accent,
      backgroundColor: AuraTheme.card,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
        children: [
          _moodChips(),
          _sotdCard(state),
          _dailyDropBanner(context),
          _confessionsTeaser(),
          _discoverRow(context),
          if (hot.isNotEmpty) _hotRightNow(hot),
          if (match != null) _matchCard(match),
          if (state.streakCount > 0 && !_postedToday()) _streakCard(state),
          ...posts.map((p) => _PostCard(
              post: p,
              userMood: state.mood,
              onUpdated: () => setState(() {}),
              onHashtagTap: (tag) => setState(() => _moodFilter = tag))),
          if (posts.isEmpty) _emptyFeed(),
        ],
      ),
    );
  }

  // ── Tab: Trending (sorted by fires desc) ──────────────────

  Widget _trendingTab() {
    final posts = List<_Post>.from(_allPosts())
      ..sort((a, b) => b.fires.compareTo(a.fires));
    return RefreshIndicator(
      color: AuraTheme.accent,
      backgroundColor: AuraTheme.card,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        children: [
          ...posts.map((p) => _PostCard(
              post: p,
              userMood: OrbitState().mood,
              onUpdated: () => setState(() {}),
              onHashtagTap: (tag) => setState(() => _moodFilter = tag))),
          if (posts.isEmpty) _emptyFeed(),
        ],
      ),
    );
  }

  // ── Tab: For You (mood match only) ────────────────────────

  Widget _forYouTab() {
    final state = OrbitState();
    final posts =
        _allPosts().where((p) => p.mood == state.mood).toList();
    return RefreshIndicator(
      color: AuraTheme.accent,
      backgroundColor: AuraTheme.card,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        children: [
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(children: [
                  Text(state.moodEmoji,
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('no ${state.mood} vibes yet',
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('be the first to drop one',
                      style: TextStyle(
                          color: AuraTheme.textMuted, fontSize: 13)),
                ]),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(children: [
                Text('${state.moodEmoji} ${state.mood} vibes',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text('${posts.length} posts',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ]),
            ),
            ...posts.map((p) => _PostCard(
                post: p,
                userMood: state.mood,
                onUpdated: () => setState(() {}))),
          ],
        ],
      ),
    );
  }

  // ── Mood Filter Chips ──────────────────────────────────────

  static const _moodOptions = [
    (null, 'all ✨'),
    ('chill', '☀️ chill'),
    ('hyped', '⚡ hyped'),
    ('nostalgic', '🌙 nostalgic'),
    ('sad', '🌧️ sad'),
    ('romantic', '💫 romantic'),
    ('cozy', '🫶 cozy'),
    ('euphoric', '✨ euphoric'),
  ];

  Widget _moodChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _moodOptions.map((m) {
          final sel = _moodFilter == m.$1;
          return GestureDetector(
            onTap: () => setState(() => _moodFilter = m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin:
                  const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? AuraTheme.accent : AuraTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(m.$2,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? Colors.white
                          : AuraTheme.textSecondary)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SOTD Card ──────────────────────────────────────────────

  Widget _sotdCard(OrbitState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AuraTheme.accentLight.withOpacity(0.6), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🎵', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: AuraTheme.accentLight.withOpacity(0.35),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('SONG OF THE DAY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.accent)),
          ),
          const Spacer(),
          Text('${state.sotdReactionCount} reactions',
              style: const TextStyle(
                  fontSize: 11, color: AuraTheme.textMuted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                  colors: AuraTheme.brandGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: const Icon(Icons.music_note_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Espresso',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('Sabrina Carpenter',
                      style: TextStyle(
                          color: AuraTheme.textMuted, fontSize: 12)),
                ]),
          ),
          GestureDetector(
            onTap: () {
              state.reactSotd();
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: state.sotdReactedToday
                    ? AuraTheme.surface
                    : AuraTheme.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(state.sotdReactedToday ? '✅' : '🔥',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  state.sotdReactedToday ? 'reacted' : 'react',
                  style: TextStyle(
                      color: state.sotdReactedToday
                          ? AuraTheme.textMuted
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Confessions Teaser ────────────────────────────────────────

  Widget _confessionsTeaser() {
    // Pick 2 seed previews
    const previews = [
      ('someone in your orbit is feeling 😭 can\'t stop crying'),
      ('someone in your orbit is feeling 💘 falling for someone they shouldn\'t'),
    ];
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ConfessionsScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF7C5CBF).withOpacity(0.35), width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🫧', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CBF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('ORBIT CONFESSIONS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9B7ED4))),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AuraTheme.textMuted, size: 18),
          ]),
          const SizedBox(height: 10),
          for (final p in previews) ...[
            Text(p,
                style: const TextStyle(
                    color: AuraTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
          ],
          const Text('tap to read + confess anonymously',
              style: TextStyle(
                  color: AuraTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Daily Drop Banner ─────────────────────────────────────
  Widget _dailyDropBanner(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const DailyDropScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('the daily drop',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 14)),
            Text('everyone is listening right now — join in',
                style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right, color: AuraTheme.accent, size: 20),
        ]),
      ),
    );
  }

  // ── Discover Row ───────────────────────────────────────────
  Widget _discoverRow(BuildContext ctx) {
    final items = [
      ('🚩', 'red flag?', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const RedFlagScreen()))),
      ('🔥', 'roast me', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const MusicRoastScreen()))),
      ('🧾', 'receipt', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const SongReceiptScreen()))),
      ('👁️', 'blindspot', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const BlindspotScreen()))),
      ('🤫', 'song secret', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const SongSecretScreen()))),
      ('🎙️', 'sound room', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const SoundRoomListScreen()))),
      ('💫', 'vibe match', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const VibeMatchScreen()))),
      ('🎯', 'song dare', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const SongDareScreen()))),
      ('💬', 'hot takes', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const HotTakeScreen()))),
      ('🤖', 'npc song', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const NpcSongScreen()))),
      ('⏳', 'time capsule', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const TimeCapsuleScreen()))),
      ('🧾', 'orbit recap', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const OrbitReceiptsScreen()))),
      ('🔗', 'streaks', () => Navigator.push(ctx,
          MaterialPageRoute(builder: (_) => const StreakChainScreen()))),
    ];
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (emoji, label, onTap) = items[i];
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 76,
              decoration: BoxDecoration(
                color: AuraTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(color: Colors.white.withOpacity(0.6),
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Hot Right Now ──────────────────────────────────────────

  Widget _hotRightNow(List<Map<String, dynamic>> hot) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AuraTheme.card, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.trending_up_rounded,
              color: AuraTheme.accent, size: 16),
          const SizedBox(width: 6),
          const Text('hot right now',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13)),
          const Spacer(),
          const Text('in your orbit',
              style:
                  TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
        ]),
        const SizedBox(height: 10),
        ...hot.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(
                  width: 20,
                  child: Text('${e.key + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AuraTheme.accent)),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AuraTheme.surface,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.music_note_rounded,
                      color: AuraTheme.accent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(e.value['song'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(e.value['artist'] as String,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AuraTheme.textMuted)),
                    ])),
                Text(
                  '${e.value['count']} friend${(e.value['count'] as int) > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            )),
      ]),
    );
  }

  // ── Song Match Card ────────────────────────────────────────

  Widget _matchCard(_Post match) {
    final friends = _matchFriends(match.songTitle);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AuraTheme.accent.withOpacity(0.06),
        border: Border.all(
            color: AuraTheme.accentLight.withOpacity(0.6), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        SizedBox(
          width: 46,
          height: 28,
          child: Stack(clipBehavior: Clip.none, children: [
            ...friends.asMap().entries.map((e) => Positioned(
                  left: e.key * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        e.value.userColor.withOpacity(0.2),
                    child: Text(e.value.initial,
                        style: TextStyle(
                            color: e.value.userColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                  ),
                )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${friends.map((f) => f.displayName).join(' & ')} are both vibing',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AuraTheme.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.songTitle} · ${match.artistName}',
                  style: const TextStyle(
                      fontSize: 11, color: AuraTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
        ),
        const Icon(Icons.bolt_rounded,
            color: AuraTheme.accent, size: 22),
      ]),
    );
  }

  // ── Streak Reminder ────────────────────────────────────────

  Widget _streakCard(OrbitState state) {
    return GestureDetector(
      onTap: _openCreate,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('keep your streak alive!',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Text('tap to drop a vybe and extend it',
                  style: TextStyle(
                      fontSize: 12, color: AuraTheme.textMuted)),
            ]),
          ),
          Text('${state.streakCount}',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AuraTheme.accent)),
        ]),
      ),
    );
  }

  // ── Empty Feed ─────────────────────────────────────────────

  Widget _emptyFeed() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Column(children: [
          Text('🎵', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No vybes yet — drop one!',
              style: TextStyle(
                  color: AuraTheme.textMuted, fontSize: 15)),
        ]),
      ),
    );
  }
}

// ── Notifications ──────────────────────────────────────────────

extension _NotifHelper on _FeedTabState {
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Text('notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              children: [
                _notifTile('🔥', '@maya.k reacted to your vybe', '2m ago', const Color(0xFFFF8C42)),
                _notifTile('🎵', '@zara.w shared a song with you', '14m ago', const Color(0xFF6C63FF)),
                _notifTile('⚡', '@dev.s wants to sync', '1h ago', const Color(0xFFFF7A50)),
                _notifTile('💫', 'Your vybe got 12 fire reactions', '2h ago', AuraTheme.accent),
                _notifTile('🌙', '@rina.p joined late night sessions', '3h ago', const Color(0xFF00B894)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _notifTile(String emoji, String text, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AuraTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

// ── Animated Now-Playing Bars ──────────────────────────────────

class _NowPlayingBars extends StatefulWidget {
  const _NowPlayingBars();
  @override
  State<_NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends State<_NowPlayingBars>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  static const _speeds = [600, 380, 700, 450];

  @override
  void initState() {
    super.initState();
    _ctrls = _speeds
        .map((ms) => AnimationController(
            vsync: this, duration: Duration(milliseconds: ms))
          ..repeat(reverse: true))
        .toList();
    _anims = _ctrls
        .map((c) => Tween(begin: 3.0, end: 13.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        4,
        (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            width: 3,
            height: _anims[i].value,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ),
    );
  }
}

// ── Post Card ──────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final _Post post;
  final String userMood;
  final VoidCallback onUpdated;
  final ValueChanged<String>? onHashtagTap;
  const _PostCard(
      {required this.post,
      required this.userMood,
      required this.onUpdated,
      this.onHashtagTap});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _showBurst = false;

  late final AnimationController _burstCtrl;
  late final Animation<double> _burstAnim;

  static const _tagColors = <String, Color>{
    'heartbreak': Color(0xFFE84393),
    'hype': Color(0xFFFF8C42),
    'nostalgic': Color(0xFF6C63FF),
    '2am': Color(0xFF636E72),
    'cozy': Color(0xFF00B894),
    'chill': Color(0xFF0984E3),
    'focused': Color(0xFF6C63FF),
    'euphoric': Color(0xFFFFAD75),
  };

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _burstAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _player.dispose();
    _burstCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    try {
      String? url = widget.post.previewUrl;
      if (url == null || url.isEmpty) {
        final res = await http.get(Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent('${widget.post.songTitle} ${widget.post.artistName}')}&media=music&limit=1'));
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          url = results[0]['previewUrl'] as String?;
        }
      }
      if (url != null) {
        await _player.setUrl(url);
        await _player.play();
      }
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    }
  }

  void _onFireTap() {
    final p = widget.post;
    setState(() {
      p.fireReacted = !p.fireReacted;
      if (p.fireReacted) {
        p.fires++;
        _showBurst = true;
        _burstCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 750),
            () { if (mounted) setState(() => _showBurst = false); });
      } else if (p.fires > 0) {
        p.fires--;
      }
    });
    // fire reaction stays local — no auto-navigation
  }

  String _timeLeft(DateTime? exp) {
    if (exp == null) return '';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inHours > 0) return 'expires ${diff.inHours}h';
    return 'expires ${diff.inMinutes}m';
  }

  void _openDM() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DMScreen(
          username: widget.post.handle,
          displayName: widget.post.displayName,
          songContext: widget.post.songTitle,
        ),
      ),
    );
  }

  Widget _buildCaption(String caption) {
    final words = caption.split(' ');
    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('#')) {
        spans.add(WidgetSpan(
          child: GestureDetector(
            onTap: () => widget.onHashtagTap?.call(word),
            child: Text(
              word,
              style: const TextStyle(
                  color: AuraTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: word,
          style: const TextStyle(
              fontSize: 13,
              color: AuraTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4),
        ));
      }
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          if (widget.post.isOwn)
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('delete this vybe'),
              onTap: () {
                OrbitState().removePost(widget.post.songTitle);
                Navigator.pop(ctx);
                widget.onUpdated();
              },
            ),
          if (!widget.post.isOwn)
            ListTile(
              leading:
                  const Icon(Icons.block_rounded, color: Colors.redAccent),
              title: Text('block "${widget.post.songTitle}" from feed'),
              onTap: () {
                OrbitState().blockedSongs.add(widget.post.songTitle);
                Navigator.pop(ctx);
                widget.onUpdated();
              },
            ),
          ListTile(
            leading: const Icon(Icons.person_off_outlined,
                color: AuraTheme.textMuted),
            title: const Text('hide posts from this person'),
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final tagColor =
        _tagColors[p.moodTag?.replaceAll('#', '')] ?? AuraTheme.accent;
    final timeLeft = _timeLeft(p.expiresAt);
    final moodMatch = !p.isOwn && p.mood == widget.userMood;
    final syncLevel = OrbitState().syncLevels[p.handle];
    final state = OrbitState();

    return GestureDetector(
      onLongPress: _showMenu,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: p.isOwn
              ? Border.all(
                  color: AuraTheme.accent.withOpacity(0.2), width: 1.5)
              : null,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──
          Row(children: [
            GestureDetector(
              onTap: p.isOwn
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OtherProfileScreen(
                                name: p.displayName,
                                handle: p.handle,
                                userColor: p.userColor,
                                initial: p.initial,
                                mood: p.mood,
                                moodEmoji: p.moodEmoji,
                                songTitle: p.songTitle,
                                artistName: p.artistName,
                              ))),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: p.userColor.withOpacity(0.15),
                backgroundImage: p.isOwn && state.pfpFile != null
                    ? FileImage(state.pfpFile!)
                    : null,
                child: (p.isOwn && state.pfpFile != null)
                    ? null
                    : Text(p.initial,
                        style: TextStyle(
                            color: p.userColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                    child: Text(p.handle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (p.isOwn) ...[
                    const SizedBox(width: 5),
                    _badge('you', AuraTheme.accent),
                  ],
                  if (syncLevel != null && !p.isOwn) ...[
                    const SizedBox(width: 5),
                    _badge(syncLevel, AuraTheme.accent),
                  ],
                  if (moodMatch) ...[
                    const SizedBox(width: 5),
                    _badge(
                        '${p.moodEmoji} match',
                        const Color(0xFF00875A),
                        bg: const Color(0xFF00B894)),
                  ],
                ]),
                Text('${p.moodEmoji} ${p.mood} · ${p.timeAgo}',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ]),
            ),
            if (timeLeft.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined,
                      size: 11, color: Colors.orangeAccent),
                  const SizedBox(width: 3),
                  Text(timeLeft,
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
          const SizedBox(height: 10),

          // ── Photo (optional) ──
          if (p.photoPath != null && File(p.photoPath!).existsSync()) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(p.photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Song card ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AuraTheme.background,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: p.artUrl != null && p.artUrl!.isNotEmpty
                    ? Image.network(p.artUrl!, width: 44, height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _songIcon(p))
                    : _songIcon(p),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.songTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(p.artistName,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 12)),
                ]),
              ),
              if (p.moodTag != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onHashtagTap?.call(p.moodTag!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(p.moodTag!,
                        style: TextStyle(
                            color: tagColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _playing
                          ? p.userColor
                          : AuraTheme.accent,
                      shape: BoxShape.circle),
                  child: Center(
                    child: _playing
                        ? const _NowPlayingBars()
                        : const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          ),

          // ── Caption (with tappable hashtags) ──
          if (p.caption != null && p.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _buildCaption(p.caption!),
            ),
          ],
          const SizedBox(height: 10),

          // ── Actions ──
          Row(children: [
            // Fire button with burst
            Stack(clipBehavior: Clip.none, children: [
              GestureDetector(
                onTap: _onFireTap,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: p.fireReacted
                        ? AuraTheme.accent
                        : AuraTheme.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.fires}',
                    style: TextStyle(
                        color: p.fireReacted
                            ? AuraTheme.accent
                            : AuraTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ]),
              ),
              if (_showBurst)
                AnimatedBuilder(
                  animation: _burstAnim,
                  builder: (_, __) => Positioned(
                    top: -28 * _burstAnim.value,
                    left: -2,
                    child: Opacity(
                      opacity: 1.0 - _burstAnim.value,
                      child: const Text('🔥🔥',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 16),
            if (!p.isOwn)
              GestureDetector(
                onTap: _openDM,
                child: const Row(children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: AuraTheme.textMuted, size: 20),
                  SizedBox(width: 4),
                  Text('dm',
                      style: TextStyle(
                          color: AuraTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            const Spacer(),
            GestureDetector(
              onTap: _showMenu,
              child: const Icon(Icons.more_horiz,
                  color: AuraTheme.textMuted, size: 20),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color textColor, {Color? bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: (bg ?? textColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                color: textColor,
                fontSize: 9,
                fontWeight: FontWeight.w700)));

  Widget _songIcon(_Post p) => Container(
      width: 44,
      height: 44,
      color: p.userColor.withOpacity(0.15),
      child: Icon(Icons.music_note_rounded, color: p.userColor, size: 22));
}
