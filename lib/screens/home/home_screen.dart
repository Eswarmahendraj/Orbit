import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../campfire/campfire_screen.dart';
import '../find/find_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/other_profile_screen.dart';
import '../social/vibe_check_screen.dart';
import '../campfire/song_battle_screen.dart';

// ── Models ───────────────────────────────────────────────────

class StoryBubble {
  final String name;
  final Color color;
  final String initial;
  final bool isCurrentlyListening;
  final String? nowSong;
  const StoryBubble({
    required this.name,
    required this.color,
    required this.initial,
    this.isCurrentlyListening = false,
    this.nowSong,
  });
}

class FeedPost {
  final String handle;
  final Color userColor;
  final String initial;
  final String mood;
  final String moodEmoji;
  final String songTitle;
  final String artistName;
  final int fires;
  final String timeAgo;
  final String? moodTag;
  final DateTime? expiresAt;
  bool fireReacted;

  FeedPost({
    required this.handle,
    required this.userColor,
    required this.initial,
    required this.mood,
    required this.moodEmoji,
    required this.songTitle,
    required this.artistName,
    required this.fires,
    required this.timeAgo,
    this.moodTag,
    this.expiresAt,
    this.fireReacted = false,
  });
}

// ── HomeScreen ────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeVibeCheck());
  }

  void _maybeVibeCheck() {
    if (!OrbitState().vibeCheckDoneToday) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _VibeCheckBanner(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: IndexedStack(index: _navIndex, children: const [
        _FeedTab(),
        CampfireScreen(),
        FindScreen(),
        ProfileScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.graphic_eq), label: 'home'),
          NavigationDestination(
              icon: Icon(Icons.local_fire_department_rounded),
              label: 'campfire'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome), label: 'find'),
          NavigationDestination(
              icon: Icon(Icons.account_circle), label: 'self'),
        ],
      ),
    );
  }
}

// ── Vibe Check Banner ─────────────────────────────────────────

class _VibeCheckBanner extends StatelessWidget {
  const _VibeCheckBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 18),
        const Text('🌡️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 10),
        const Text('morning vibe check',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('see who\'s feeling the same as you today',
            textAlign: TextAlign.center,
            style: TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AuraTheme.textMuted.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('later',
                  style: TextStyle(color: AuraTheme.textMuted)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VibeCheckScreen()));
              },
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('check now'),
            ),
          ),
        ]),
        const SizedBox(height: 6),
      ]),
    );
  }
}

// ── Feed Tab ──────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _stories = [
    StoryBubble(name: 'maya', color: Color(0xFFFF4500), initial: 'M',
        isCurrentlyListening: true, nowSong: 'Espresso'),
    StoryBubble(name: 'zara', color: Color(0xFF6C63FF), initial: 'Z'),
    StoryBubble(name: 'dev', color: Color(0xFFFF7A50), initial: 'D',
        isCurrentlyListening: true, nowSong: 'APT.'),
    StoryBubble(name: 'rina', color: Color(0xFF00B894), initial: 'R'),
    StoryBubble(name: 'jay', color: Color(0xFFE17055), initial: 'J',
        isCurrentlyListening: true, nowSong: 'luther'),
    StoryBubble(name: 'leo', color: Color(0xFF74B9FF), initial: 'L'),
  ];

  late final List<FeedPost> _posts = [
    FeedPost(
      handle: '@maya.k', userColor: const Color(0xFFFF4500), initial: 'M',
      mood: 'chill', moodEmoji: '☀️',
      songTitle: 'Espresso', artistName: 'Sabrina Carpenter',
      fires: 47, timeAgo: '2m ago', moodTag: 'hype',
      expiresAt: DateTime.now().add(const Duration(hours: 18, minutes: 42)),
    ),
    FeedPost(
      handle: '@zara.w', userColor: const Color(0xFF6C63FF), initial: 'Z',
      mood: 'nostalgic', moodEmoji: '🌙',
      songTitle: 'Die With A Smile', artistName: 'Lady Gaga & Bruno Mars',
      fires: 83, timeAgo: '14m ago', moodTag: 'nostalgic',
    ),
    FeedPost(
      handle: '@dev.s', userColor: const Color(0xFFFF7A50), initial: 'D',
      mood: 'hyped', moodEmoji: '⚡',
      songTitle: 'APT.', artistName: 'ROSE & Bruno Mars',
      fires: 122, timeAgo: '31m ago', moodTag: '2am',
    ),
    FeedPost(
      handle: '@jay.r', userColor: const Color(0xFFE17055), initial: 'J',
      mood: 'sad', moodEmoji: '🌧️',
      songTitle: 'luther', artistName: 'Kendrick Lamar & SZA',
      fires: 56, timeAgo: '1h ago', moodTag: 'heartbreak',
    ),
    FeedPost(
      handle: '@rina.p', userColor: const Color(0xFF00B894), initial: 'R',
      mood: 'romantic', moodEmoji: '💫',
      songTitle: 'Golden Hour', artistName: 'JVKE',
      fires: 39, timeAgo: '2h ago', moodTag: 'drive',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          floating: true,
          backgroundColor: AuraTheme.background,
          title: const Text('orbit',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          actions: [
            IconButton(
              icon: const Icon(Icons.bolt_rounded,
                  color: AuraTheme.accent, size: 26),
              tooltip: 'Song Battle',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SongBattleScreen())),
            ),
            IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {}),
          ],
        ),
        SliverToBoxAdapter(child: _storiesRow()),
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
          _feedList(_posts),
          _feedList(_posts.reversed.toList()),
          _feedList([..._posts]..shuffle(math.Random(42))),
        ],
      ),
    );
  }

  Widget _storiesRow() => SizedBox(
        height: 96,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _stories.length,
          itemBuilder: (_, i) {
            final s = _stories[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherProfileScreen(
                    name: s.name,
                    handle: '@${s.name}.k',
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
                              colors: [s.color, s.color.withOpacity(0.4)]),
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
                      if (s.isCurrentlyListening)
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
                                  color: AuraTheme.background, width: 2),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(s.name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AuraTheme.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _feedList(List<FeedPost> posts) {
    final blocked = OrbitState().blockedSongs;
    final visible =
        posts.where((p) => !blocked.contains(p.songTitle)).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: visible.length,
      itemBuilder: (_, i) => _FeedPostCard(
        post: visible[i],
        onUpdated: () => setState(() {}),
      ),
    );
  }
}

// ── Feed Post Card ────────────────────────────────────────────

class _FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onUpdated;
  const _FeedPostCard({required this.post, required this.onUpdated});
  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  final _player = AudioPlayer();
  bool _playing = false;

  static const _tagColors = <String, Color>{
    'heartbreak': Color(0xFFE84393),
    'hype': Color(0xFFFF4500),
    'nostalgic': Color(0xFF6C63FF),
    '2am': Color(0xFF636E72),
    'drive': Color(0xFF00B894),
    'chill': Color(0xFF0984E3),
  };

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      try {
        final uri = Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent('${widget.post.songTitle} ${widget.post.artistName}')}&media=music&limit=1');
        final res = await http.get(uri);
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final url = results[0]['previewUrl'] as String?;
          if (url != null) {
            await _player.setUrl(url);
            await _player.play();
          }
        }
      } catch (_) {
        if (mounted) setState(() => _playing = false);
      }
    }
  }

  String _timeLeft(DateTime? exp) {
    if (exp == null) return '';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inHours > 0) return 'expires in ${diff.inHours}h';
    return 'expires in ${diff.inMinutes}m';
  }

  void _showReactionThread() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReactionThread(post: widget.post),
    );
  }

  void _showBlockMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
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
    final tagColor = _tagColors[p.moodTag] ?? AuraTheme.accent;
    final timeLeft = _timeLeft(p.expiresAt);

    return GestureDetector(
      onLongPress: _showBlockMenu,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => OtherProfileScreen(
                    name: p.handle.replaceAll('@', '').replaceAll('.', ' '),
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
                child: Text(p.initial,
                    style: TextStyle(
                        color: p.userColor, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.handle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${p.moodEmoji} ${p.mood} · ${p.timeAgo}',
                  style: const TextStyle(
                      color: AuraTheme.textMuted, fontSize: 12)),
            ])),
            if (p.expiresAt != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
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
          ]),
          const SizedBox(height: 12),

          // Song card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: p.userColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.music_note_rounded,
                    color: p.userColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.songTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(p.artistName,
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ])),
              if (p.moodTag != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#${p.moodTag}',
                      style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
              ],
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: _playing ? p.userColor : AuraTheme.accent,
                      shape: BoxShape.circle),
                  child: Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Actions row
          Row(children: [
            GestureDetector(
              onTap: () {
                setState(() => p.fireReacted = !p.fireReacted);
                if (p.fireReacted) _showReactionThread();
              },
              child: Row(children: [
                Icon(Icons.local_fire_department_rounded,
                    color: p.fireReacted
                        ? AuraTheme.accent
                        : AuraTheme.textMuted,
                    size: 22),
                const SizedBox(width: 4),
                Text('${p.fires + (p.fireReacted ? 1 : 0)}',
                    style: TextStyle(
                        color: p.fireReacted
                            ? AuraTheme.accent
                            : AuraTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: _showReactionThread,
              child: const Row(children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: AuraTheme.textMuted, size: 20),
                SizedBox(width: 4),
                Text('react',
                    style: TextStyle(
                        color: AuraTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showBlockMenu,
              child: const Icon(Icons.more_horiz,
                  color: AuraTheme.textMuted, size: 20),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Reaction Thread Sheet ─────────────────────────────────────

class _ReactionThread extends StatefulWidget {
  final FeedPost post;
  const _ReactionThread({required this.post});
  @override
  State<_ReactionThread> createState() => _ReactionThreadState();
}

class _ReactionThreadState extends State<_ReactionThread> {
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _msgs = [
    {'h': '@zara.w', 't': 'this song has been on repeat 😭', 'i': 'Z'},
    {'h': '@dev.s', 't': 'actually obsessed rn', 'i': 'D'},
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.local_fire_department_rounded,
                color: AuraTheme.accent, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(
                'reactions · ${widget.post.songTitle}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
                overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _msgs.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AuraTheme.accent.withOpacity(0.15),
                  child: Text(_msgs[i]['i']!,
                      style: const TextStyle(
                          color: AuraTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_msgs[i]['h']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AuraTheme.textMuted)),
                  Text(_msgs[i]['t']!,
                      style: const TextStyle(fontSize: 13)),
                ])),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                    hintText: 'send a reaction...', isDense: true),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                if (_ctrl.text.trim().isNotEmpty) {
                  setState(() {
                    _msgs.add({'h': '@you', 't': _ctrl.text.trim(), 'i': 'Y'});
                    _ctrl.clear();
                  });
                }
              },
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(
                    color: AuraTheme.accent, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [color.withOpacity(0), color, color.withOpacity(0)],
          transform: GradientRotation(progress * 2 * math.pi),
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}
