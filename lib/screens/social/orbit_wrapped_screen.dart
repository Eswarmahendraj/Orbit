import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Orbit Wrapped — weekly stats shareable card
//
// Shows: top song, dominant vibe, sync partner, moments posted,
// battles won, puzzle streak.
// ─────────────────────────────────────────────────────────────────────────────

class OrbitWrappedScreen extends StatefulWidget {
  const OrbitWrappedScreen({super.key});

  @override
  State<OrbitWrappedScreen> createState() => _OrbitWrappedScreenState();
}

class _OrbitWrappedScreenState extends State<OrbitWrappedScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Computed stats
  bool _loading = true;
  String _topSong = '—';
  String _topArtist = '—';
  String _dominantVibe = '—';
  String _dominantVibeEmoji = '🎵';
  String _syncPartner = '—';
  int _momentsPosted = 0;
  int _battlesWon = 0;
  int _puzzlesSolved = 0;

  // Animation
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _loadStats();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final uid = _uid;
    if (uid == null) { setState(() => _loading = false); return; }

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoTs = Timestamp.fromDate(weekAgo);

    // ── Top song from pulse posts this week ──────────────────────────────────
    try {
      final postsSnap = await _db
          .collection('pulse_posts')
          .where('uid', isEqualTo: uid)
          .where('createdAt', isGreaterThan: weekAgoTs)
          .get();
      final songCounts = <String, int>{};
      final songArtists = <String, String>{};
      for (final doc in postsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final song = data['song'] as String? ?? '';
        if (song.isNotEmpty) {
          songCounts[song] = (songCounts[song] ?? 0) + 1;
          songArtists[song] = data['artist'] as String? ?? '';
        }
      }
      if (songCounts.isNotEmpty) {
        final top = songCounts.entries.reduce(
            (a, b) => a.value >= b.value ? a : b);
        _topSong = top.key;
        _topArtist = songArtists[top.key] ?? '';
      } else if (_state.vibeSong.isNotEmpty) {
        _topSong = _state.vibeSong;
        _topArtist = _state.vibeArtist;
      }
    } catch (_) {}

    // ── Dominant vibe from mood history ─────────────────────────────────────
    // We read the user's current mood as a proxy (no full history in this schema)
    _dominantVibe = _state.mood.isNotEmpty ? _state.mood : 'chill';
    _dominantVibeEmoji = _state.moodEmoji.isNotEmpty ? _state.moodEmoji : '🎵';

    // ── Sync partner — person who reacted most to my posts ──────────────────
    try {
      final reactSnap = await _db
          .collection('reactions')
          .where('targetUid', isEqualTo: uid)
          .where('createdAt', isGreaterThan: weekAgoTs)
          .get();
      final reactorCounts = <String, int>{};
      final reactorNames = <String, String>{};
      for (final doc in reactSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final fromUid = data['fromUid'] as String? ?? '';
        if (fromUid.isNotEmpty) {
          reactorCounts[fromUid] = (reactorCounts[fromUid] ?? 0) + 1;
          reactorNames[fromUid] = data['fromName'] as String? ?? fromUid;
        }
      }
      if (reactorCounts.isNotEmpty) {
        final top = reactorCounts.entries.reduce(
            (a, b) => a.value >= b.value ? a : b);
        _syncPartner = reactorNames[top.key] ?? 'your orbit';
      }
    } catch (_) {}
    if (_syncPartner == '—' && _state.closeOrbit.isNotEmpty) {
      _syncPartner = _state.closeOrbit.first;
    }

    // ── Orbit Moments this week ──────────────────────────────────────────────
    try {
      final momentSnap = await _db
          .collection('orbit_moments')
          .where('uid', isEqualTo: uid)
          .where('createdAt', isGreaterThan: weekAgoTs)
          .get();
      _momentsPosted = momentSnap.docs.length;
    } catch (_) {
      _momentsPosted = _state.myMoments.length.clamp(0, 7);
    }

    // ── Battles won ──────────────────────────────────────────────────────────
    try {
      final battleSnap = await _db
          .collection('song_battles')
          .where('winnerId', isEqualTo: uid)
          .where('updatedAt', isGreaterThan: weekAgoTs)
          .get();
      _battlesWon = battleSnap.docs.length;
    } catch (_) {}

    // ── Puzzles solved ───────────────────────────────────────────────────────
    try {
      final puzzleSnap = await _db
          .collection('puzzle_scores')
          .where('uid', isEqualTo: uid)
          .where('solved', isEqualTo: true)
          .where('createdAt', isGreaterThan: weekAgoTs)
          .get();
      _puzzlesSolved = puzzleSnap.docs.length;
    } catch (_) {}

    setState(() => _loading = false);
    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  String get _weekLabel {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return '${_monthShort(start.month)} ${start.day} – ${_monthShort(now.month)} ${now.day}';
  }

  String _monthShort(int m) => ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    final text = '''
my orbit wrapped 🌌 (${_weekLabel})

🎵 top song: $_topSong — $_topArtist
$_dominantVibeEmoji dominant vibe: $_dominantVibe
🤝 sync partner: $_syncPartner
📸 moments: $_momentsPosted/7
⚔️ battles won: $_battlesWon
🧩 puzzles solved: $_puzzlesSolved/7

join me on Orbit ✨
''';
    await Share.share(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('orbit wrapped',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(_weekLabel,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: _share,
              tooltip: 'Share',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AuraTheme.accent))
          : SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _WrappedCard(
                      icon: '🎵',
                      label: 'top song this week',
                      title: _topSong,
                      subtitle: _topArtist,
                      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _WrappedCard(
                          icon: _dominantVibeEmoji,
                          label: 'dominant vibe',
                          title: _dominantVibe,
                          gradient: const [Color(0xFFf7971e), Color(0xFFffd200)],
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WrappedCard(
                          icon: '🤝',
                          label: 'sync partner',
                          title: _syncPartner,
                          gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                          compact: true,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _StatCard(
                          emoji: '📸',
                          label: 'moments',
                          value: '$_momentsPosted',
                          sub: 'this week',
                          color: const Color(0xFFee0979),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          emoji: '⚔️',
                          label: 'battles won',
                          value: '$_battlesWon',
                          sub: 'this week',
                          color: const Color(0xFF4286f4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          emoji: '🧩',
                          label: 'puzzles',
                          value: '$_puzzlesSolved/7',
                          sub: 'solved',
                          color: AuraTheme.accent,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Share button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share_rounded,
                            color: Colors.white),
                        label: const Text('share your wrapped',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuraTheme.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('refreshes every monday',
                        style: TextStyle(color: Colors.white.withOpacity(0.3),
                            fontSize: 11),
                        textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapped Card (hero stat)
// ─────────────────────────────────────────────────────────────────────────────

class _WrappedCard extends StatelessWidget {
  final String icon;
  final String label;
  final String title;
  final String? subtitle;
  final List<Color> gradient;
  final bool compact;

  const _WrappedCard({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
    required this.gradient,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: TextStyle(fontSize: compact ? 24 : 32)),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 15 : 20),
            overflow: TextOverflow.ellipsis,
            maxLines: 2),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(subtitle!,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: compact ? 11 : 13),
              overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card (small number card)
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20)),
        Text(sub,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
