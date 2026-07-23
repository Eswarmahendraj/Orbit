import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../../theme/aura_theme.dart';
import '../../services/social_service.dart';
import '../profile/other_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/orb_skeleton.dart';
import '../../widgets/orb_empty_state.dart';
import 'dart:math' as math;

// ─── Models ───────────────────────────────────────────────────────────────────

class _PersonResult {
  final String name;
  final String handle;
  final String initial;
  final Color color;
  final String mood;
  final String moodEmoji;
  final int mutuals;

  const _PersonResult({
    required this.name,
    required this.handle,
    required this.initial,
    required this.color,
    required this.mood,
    required this.moodEmoji,
    this.mutuals = 0,
  });
}

class _SongResult {
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? previewUrl;

  const _SongResult({
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.previewUrl,
  });
}

class _CampfireResult {
  final String name;
  final String emoji;
  final int members;
  final bool isLive;
  final Color color;

  const _CampfireResult({
    required this.name,
    required this.emoji,
    required this.members,
    this.isLive = false,
    required this.color,
  });
}

// ─── FindScreen ───────────────────────────────────────────────────────────────

class FindScreen extends StatefulWidget {
  const FindScreen({super.key});

  @override
  State<FindScreen> createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  late TabController _tabController;
  late AnimationController _radarCtrl;
  List<Map<String, dynamic>> _songResults = [];
  bool _loadingSongs = false;
  final _player = AudioPlayer();
  String? _playingUrl;

  // Default suggested content
  // Firestore-backed people (replaces static list)
  List<Map<String, dynamic>> _firestoreUsers = [];
  List<Map<String, dynamic>> _searchedUsers = [];
  bool _loadingUsers = false;

  // Fallback static people (shown when Firestore returns nothing)
  static const List<_PersonResult> _fallbackPeople = [
    _PersonResult(
        name: 'Maya Patel',
        handle: '@mayasounds',
        initial: 'M',
        color: Color(0xFFFF4500),
        mood: 'nostalgic',
        moodEmoji: '🌙',
        mutuals: 3),
    _PersonResult(
        name: 'Alex Chen',
        handle: '@alexbeats',
        initial: 'A',
        color: Color(0xFF6C63FF),
        mood: 'hyped',
        moodEmoji: '⚡',
        mutuals: 1),
    _PersonResult(
        name: 'Zoe Williams',
        handle: '@zoevibe',
        initial: 'Z',
        color: Color(0xFFFF7A50),
        mood: 'chill',
        moodEmoji: '☀️',
        mutuals: 5),
    _PersonResult(
        name: 'Sam Rivera',
        handle: '@samr',
        initial: 'S',
        color: Color(0xFF4CAF50),
        mood: 'focused',
        moodEmoji: '🎧',
        mutuals: 2),
  ];

  final List<_CampfireResult> _openCampfires = const [
    _CampfireResult(
        name: 'late night sessions',
        emoji: '🌙',
        members: 8,
        isLive: true,
        color: Color(0xFF6C63FF)),
    _CampfireResult(
        name: 'hype house', emoji: '⚡', members: 23, color: Color(0xFFFF4500)),
    _CampfireResult(
        name: 'deep focus 🎧',
        emoji: '🎧',
        members: 12,
        color: Color(0xFF00BCD4)),
  ];

  final List<String> _trendingChips = const [
    'blinding lights', 'golden hour', 'as it was',
    'stay', 'levitating', 'bad guy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.trim().isNotEmpty;
      });
    });
    // Publish current user to Firestore + load suggested users
    SocialService().upsertProfile();
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() => _loadingUsers = true);
    final users = await SocialService().getSuggested(limit: 10);
    if (mounted) setState(() { _firestoreUsers = users; _loadingUsers = false; });
  }

  Future<void> _searchPeople(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchedUsers = []);
      return;
    }
    setState(() => _loadingUsers = true);
    final users = await SocialService().searchUsers(query);
    if (mounted) setState(() { _searchedUsers = users; _loadingUsers = false; });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _radarCtrl.dispose();
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loadingSongs = true);
    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=10');
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        _songResults = List<Map<String, dynamic>>.from(data['results']);
        _loadingSongs = false;
      });
    } catch (_) {
      setState(() => _loadingSongs = false);
    }
  }

  Future<void> _togglePlay(String? url) async {
    if (url == null) return;
    if (_playingUrl == url) {
      await _player.pause();
      setState(() => _playingUrl = null);
    } else {
      setState(() => _playingUrl = url);
      try {
        await _player.setUrl(url);
        await _player.play();
      } catch (_) {
        setState(() => _playingUrl = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [AuraTheme.accent, Color(0xFFFF8C42), AuraTheme.accent],
          ).createShader(r),
          child: const Text(
            'ORBIT_SCAN',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 2.5,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [AuraTheme.accent, Color(0xFFFF8C42)],
              ).createShader(r),
              child: const Icon(Icons.wifi_tethering, color: Colors.white, size: 22),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AuraTheme.accent, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'SCAN::  people · songs · campfires',
                hintStyle: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: AuraTheme.textMuted,
                  letterSpacing: 0.5,
                ),
                prefixIcon: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [AuraTheme.accent, Color(0xFFFF8C42)],
                  ).createShader(r),
                  child: const Icon(Icons.radar, color: Colors.white, size: 20),
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                        },
                      )
                    : null,
                filled: true,
                fillColor: AuraTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AuraTheme.accent, width: 1.5),
                ),
              ),
              onSubmitted: (q) {
                _searchSongs(q);
                _searchPeople(q);
              },
              onChanged: (q) => _searchPeople(q),
            ),
          ),

          if (_isSearching) ...[
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'people'),
                Tab(text: 'songs'),
                Tab(text: 'campfires'),
              ],
              labelColor: AuraTheme.accent,
              unselectedLabelColor: AuraTheme.textMuted,
              indicatorColor: AuraTheme.accent,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // People tab — real Firestore users, fallback to static
                  _loadingUsers
                      ? const SkeletonList(skeleton: PersonTileSkeleton())
                      : (_firestoreUsers.isEmpty && _searchedUsers.isEmpty && _fallbackPeople.isEmpty)
                          ? EmptyPeopleState(onExplore: () => _tabController.animateTo(1))
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...(_searchedUsers.isNotEmpty ? _searchedUsers : _firestoreUsers)
                                    .map((u) => _FirestorePersonTile(data: u)),
                                if (_firestoreUsers.isEmpty && _searchedUsers.isEmpty)
                                  ..._fallbackPeople.map((p) => _PersonTile(person: p)),
                              ],
                            ),
                  // Songs tab
                  _loadingSongs
                      ? const SkeletonList(skeleton: SongTileSkeleton())
                      : _songResults.isEmpty
                          ? const OrbEmptyState(
                              emoji: '🎵',
                              title: 'Search for a song',
                              subtitle: 'Type a song, artist, or mood above to discover music.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _songResults.length,
                              itemBuilder: (context, i) {
                                final track = _songResults[i];
                                final url = track['previewUrl'] as String?;
                                return _SongTile(
                                  title: track['trackName'] ?? '',
                                  artist: track['artistName'] ?? '',
                                  artworkUrl: track['artworkUrl60'],
                                  isPlaying: _playingUrl == url,
                                  onTogglePlay: () => _togglePlay(url),
                                );
                              },
                            ),
                  // Campfires tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: _openCampfires
                        .map((c) => _CampfireTile(campfire: c))
                        .toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  // ── Orbit Radar ─────────────────────────────────────
                  _OrbitRadar(
                    people: _fallbackPeople,
                    animation: _radarCtrl,
                  ),
                  const SizedBox(height: 24),
                  // ── Trending ─────────────────────────────────────────
                  const Text(
                    'TRENDING_NOW',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: AuraTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _trendingChips
                        .map((chip) => GestureDetector(
                              onTap: () {
                                _searchController.text = chip;
                                _searchSongs(chip);
                                _tabController.index = 1;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AuraTheme.card,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AuraTheme.accent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (r) => const LinearGradient(
                                        colors: [AuraTheme.accent, Color(0xFFFF8C42)],
                                      ).createShader(r),
                                      child: const Icon(Icons.trending_up,
                                          color: Colors.white, size: 14),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(chip,
                                        style: const TextStyle(
                                            fontFamily: 'SpaceMono',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // ── Orbit Signals ────────────────────────────────────
                  const Text(
                    'ORBIT_SIGNALS',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: AuraTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingUsers)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AuraTheme.accent, strokeWidth: 2),
                    ))
                  else if (_firestoreUsers.isNotEmpty)
                    ..._firestoreUsers.map((u) => _FirestorePersonTile(data: u))
                  else
                    ..._fallbackPeople.map((p) => _PersonTile(person: p)),
                  const SizedBox(height: 24),
                  // ── Active Campfires ─────────────────────────────────
                  const Text(
                    'ACTIVE_CAMPFIRES',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: AuraTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._openCampfires.map((c) => _CampfireTile(campfire: c)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Firestore Person Tile (real users) ──────────────────────────────────────

class _FirestorePersonTile extends StatefulWidget {
  final Map<String, dynamic> data;
  const _FirestorePersonTile({required this.data});

  @override
  State<_FirestorePersonTile> createState() => _FirestorePersonTileState();
}

class _FirestorePersonTileState extends State<_FirestorePersonTile> {
  bool _following = false;
  bool _loading = true;

  static const _avatarColors = [
    Color(0xFFFF6B6B), Color(0xFF6C63FF), Color(0xFFFF7A50),
    Color(0xFF4CAF50), Color(0xFF00BCD4), Color(0xFFFF4500),
  ];

  @override
  void initState() {
    super.initState();
    _checkFollow();
  }

  Future<void> _checkFollow() async {
    final uid = widget.data['uid'] as String? ?? '';
    if (uid.isEmpty) { setState(() => _loading = false); return; }
    final following = await SocialService().isFollowing(uid);
    if (mounted) setState(() { _following = following; _loading = false; });
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    final uid = widget.data['uid'] as String? ?? '';
    if (uid.isEmpty) return;
    setState(() => _following = !_following);
    if (_following) {
      await SocialService().follow(uid);
    } else {
      await SocialService().unfollow(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['displayName'] as String? ?? 'User';
    final handle = widget.data['username'] as String? ?? '@user';
    final mood = widget.data['mood'] as String? ?? 'chill';
    final moodEmoji = widget.data['moodEmoji'] as String? ?? '☀️';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final colorIdx = name.hashCode.abs() % _avatarColors.length;
    final color = _avatarColors[colorIdx];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => OtherProfileScreen(
              name: name, handle: handle,
              userColor: color, initial: initial,
              mood: mood, moodEmoji: moodEmoji,
              songTitle: widget.data['pinnedSong'] as String? ?? '',
              artistName: widget.data['pinnedArtist'] as String? ?? '',
              pfpUrl: widget.data['pfpUrl'] as String?,
            ),
          )),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            backgroundImage: (widget.data['pfpUrl'] as String?) != null
                ? CachedNetworkImageProvider(widget.data['pfpUrl'] as String)
                : null,
            child: (widget.data['pfpUrl'] as String?) == null
                ? Text(initial,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('$moodEmoji $mood',
                style: const TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
          ]),
        ),
        _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AuraTheme.accent))
            : GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _following ? AuraTheme.surface : AuraTheme.accent,
                    borderRadius: BorderRadius.circular(20),
                    border: _following
                        ? Border.all(color: AuraTheme.textMuted.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    _following ? 'following' : 'follow',
                    style: TextStyle(
                        color: _following ? AuraTheme.textMuted : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
      ]),
    );
  }
}

// ─── Person Tile ──────────────────────────────────────────────────────────────

class _PersonTile extends StatefulWidget {
  final _PersonResult person;
  const _PersonTile({required this.person});

  @override
  State<_PersonTile> createState() => _PersonTileState();
}

class _PersonTileState extends State<_PersonTile> {
  bool _synced = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtherProfileScreen(
                  name: widget.person.name,
                  handle: widget.person.handle,
                  userColor: widget.person.color,
                  initial: widget.person.initial,
                  mood: widget.person.mood,
                  moodEmoji: widget.person.moodEmoji,
                  songTitle: 'Blinding Lights',
                  artistName: 'The Weeknd',
                ),
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: widget.person.color.withOpacity(0.15),
              child: Text(widget.person.initial,
                  style: TextStyle(
                      color: widget.person.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.person.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${widget.person.moodEmoji} ${widget.person.mood}  ·  ${widget.person.mutuals} mutual',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _synced = !_synced),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _synced ? AuraTheme.surface : AuraTheme.accent,
                borderRadius: BorderRadius.circular(20),
                border: _synced
                    ? Border.all(color: AuraTheme.textMuted.withOpacity(0.3))
                    : null,
              ),
              child: Text(
                _synced ? 'synced' : 'sync',
                style: TextStyle(
                  color: _synced ? AuraTheme.textMuted : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Song Tile ────────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? artworkUrl;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const _SongTile({
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: artworkUrl != null
                ? Image.network(artworkUrl!,
                    width: 44, height: 44, fit: BoxFit.cover)
                : Container(
                    width: 44,
                    height: 44,
                    color: AuraTheme.surface,
                    child: const Icon(Icons.music_note,
                        color: AuraTheme.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(artist,
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: AuraTheme.accent, shape: BoxShape.circle),
              child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Campfire Tile ────────────────────────────────────────────────────────────

class _CampfireTile extends StatelessWidget {
  final _CampfireResult campfire;
  const _CampfireTile({required this.campfire});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: campfire.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(campfire.emoji,
                style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(campfire.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    if (campfire.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AuraTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('● live',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                Text('${campfire.members} in orbit',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AuraTheme.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('join',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Orbit Radar ──────────────────────────────────────────────────────────────

class _OrbitRadar extends StatelessWidget {
  final List<_PersonResult> people;
  final Animation<double> animation;

  const _OrbitRadar({required this.people, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 262,
          decoration: BoxDecoration(
            color: const Color(0xFF05050F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AuraTheme.accent.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: AuraTheme.accent.withOpacity(0.07),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => CustomPaint(
                painter: _RadarPainter(
                  sweep: animation.value,
                  people: people,
                ),
              ),
            ),
          ),
        ),
        // HUD top-left label
        const Positioned(
          top: 12,
          left: 14,
          child: Text(
            'ORBIT_RADAR',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AuraTheme.accent,
              letterSpacing: 2,
            ),
          ),
        ),
        // HUD top-right scanning badge
        Positioned(
          top: 9,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AuraTheme.accent.withOpacity(0.38)),
            ),
            child: const Text(
              '● SCANNING',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: AuraTheme.accent,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Radar Painter ────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final double sweep;
  final List<_PersonResult> people;

  // Orbit radii as fraction of maxR
  static const List<double> _orbits = [0.30, 0.52, 0.70, 0.88];
  // Angular speeds relative to sweep revolution
  static const List<double> _speeds = [0.45, 0.28, 0.62, 0.35];
  // Initial phase offsets (radians)
  static const List<double> _phases = [0.0, 1.4, 2.8, 4.5];

  const _RadarPainter({required this.sweep, required this.people});

  void _drawText(Canvas canvas, Offset center, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) * 0.86;
    final center = Offset(cx, cy);

    // Background radial gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF0D0A1A), const Color(0xFF05050F)],
          radius: 0.85,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Concentric rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(
        center,
        maxR * i / 4,
        Paint()
          ..color = AuraTheme.accent.withOpacity(0.05 + i * 0.015)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Crosshairs
    final xPaint = Paint()
      ..color = AuraTheme.accent.withOpacity(0.07)
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(cx - maxR, cy), Offset(cx + maxR, cy), xPaint);
    canvas.drawLine(Offset(cx, cy - maxR), Offset(cx, cy + maxR), xPaint);
    final d = maxR * math.cos(math.pi / 4);
    final xPaint2 = Paint()
      ..color = AuraTheme.accent.withOpacity(0.04)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(cx - d, cy - d), Offset(cx + d, cy + d), xPaint2);
    canvas.drawLine(Offset(cx + d, cy - d), Offset(cx - d, cy + d), xPaint2);

    // Sweep trail — SweepGradient over full circle, clipped to circle
    final rect = Rect.fromCircle(center: center, radius: maxR);
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    final trailS0 = math.max(0.0, sweep - 0.16);
    final trailS1 = math.max(0.001, sweep).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: -math.pi / 2,
          endAngle: math.pi * 2 - math.pi / 2,
          colors: [
            Colors.transparent,
            Colors.transparent,
            AuraTheme.accent.withOpacity(0.45),
            Colors.transparent,
          ],
          stops: [0.0, trailS0, trailS1, 1.0],
        ).createShader(rect),
    );
    canvas.restore();

    // Sweep line — glow layer + solid layer
    final sweepAngle = sweep * 2 * math.pi - math.pi / 2;
    final lineEnd = Offset(
      cx + maxR * math.cos(sweepAngle),
      cy + maxR * math.sin(sweepAngle),
    );
    canvas.drawLine(center, lineEnd,
        Paint()
          ..color = AuraTheme.accent.withOpacity(0.65)
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawLine(center, lineEnd,
        Paint()
          ..color = AuraTheme.accent
          ..strokeWidth = 1.0);

    // Person nodes — each orbiting at their own speed
    final count = math.min(people.length, 4);
    for (int i = 0; i < count; i++) {
      final orbitR = maxR * _orbits[i];
      final nodeAngle =
          sweep * 2 * math.pi * _speeds[i] + _phases[i] - math.pi / 2;
      final nx = cx + orbitR * math.cos(nodeAngle);
      final ny = cy + orbitR * math.sin(nodeAngle);
      final node = Offset(nx, ny);

      // Hit: sweep just crossed the node's angle
      final diff =
          ((sweepAngle - nodeAngle) % (2 * math.pi) + 2 * math.pi) %
              (2 * math.pi);
      final isHit = diff < 0.28;

      // Hit glow burst
      if (isHit) {
        canvas.drawCircle(
          node,
          20,
          Paint()
            ..color = people[i].color.withOpacity(0.40)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }

      // Node fill + border
      canvas.drawCircle(node, 14,
          Paint()..color = people[i].color.withOpacity(isHit ? 0.22 : 0.08));
      canvas.drawCircle(
        node,
        14,
        Paint()
          ..color = people[i].color.withOpacity(isHit ? 1.0 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Initial letter
      _drawText(
        canvas,
        node,
        people[i].initial,
        TextStyle(
          color: people[i].color.withOpacity(isHit ? 1.0 : 0.8),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    // Center YOU node
    canvas.drawCircle(center, 28,
        Paint()
          ..color = AuraTheme.accent.withOpacity(0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(center, 22,
        Paint()..color = AuraTheme.accent.withOpacity(0.14));
    canvas.drawCircle(center, 22,
        Paint()
          ..color = AuraTheme.accent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(center, 14,
        Paint()
          ..color = AuraTheme.accent.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    _drawText(canvas, center, 'YOU',
        const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ));
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.sweep != sweep;
}
