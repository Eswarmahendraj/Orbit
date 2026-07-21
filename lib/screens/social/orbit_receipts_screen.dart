import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Orbit Receipts — weekly embarrassing stats
// "your guilty pleasure genre", "song you skipped the most", "2am habit"
// Distinct from monthly Song Receipt (which is a formatted paper receipt).
// This is a card-by-card swipeable reveal with funny commentary.
// ─────────────────────────────────────────────────────────────────────────────

class OrbitReceiptsScreen extends StatefulWidget {
  const OrbitReceiptsScreen({super.key});
  @override
  State<OrbitReceiptsScreen> createState() => _OrbitReceiptsScreenState();
}

class _OrbitReceiptsScreenState extends State<OrbitReceiptsScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool _loading = true;
  List<_ReceiptStat> _stats = [];
  int _page = 0;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _loadStats();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    final uid = _uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTs = Timestamp.fromDate(weekAgo);

    // Gather Firestore data
    final postSnap = await FirebaseFirestore.instance
        .collection('pulse_posts')
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: weekTs)
        .get();

    final momentSnap = await FirebaseFirestore.instance
        .collection('orbit_moments')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThan: weekAgo.toIso8601String().substring(0, 10))
        .get();

    final battleSnap = await FirebaseFirestore.instance
        .collection('battles')
        .where('winnerId', isEqualTo: uid)
        .where('createdAt', isGreaterThan: weekTs)
        .get();

    final puzzleSnap = await FirebaseFirestore.instance
        .collection('puzzle_scores')
        .where('uid', isEqualTo: uid)
        .where('date', isGreaterThan: weekAgo.toIso8601String().substring(0, 10))
        .get();

    // --- Compute stats ---
    final posts = postSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    final puzzles = puzzleSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

    // Top song skipped
    final skips = Map.from(_state.songSkips);
    String mostSkipped = '';
    int mostSkipCount = 0;
    skips.forEach((k, v) {
      if ((v as int) > mostSkipCount) {
        mostSkipCount = v;
        mostSkipped = (k as String).split('|').first;
      }
    });

    // Dominant genre (from mood history → estimate from posts)
    final moods = posts.map((p) => p['mood'] as String? ?? '').toList();
    final moodCounts = <String, int>{};
    for (final m in moods) { if (m.isNotEmpty) moodCounts[m] = (moodCounts[m] ?? 0) + 1; }
    String topMood = '';
    int topMoodCount = 0;
    moodCounts.forEach((m, c) { if (c > topMoodCount) { topMoodCount = c; topMood = m; } });

    // 2am habit — check if any posts were between midnight and 3am
    int lateNightPosts = 0;
    for (final p in posts) {
      final ts = p['createdAt'] as Timestamp?;
      if (ts != null) {
        final dt = ts.toDate().toLocal();
        if (dt.hour >= 0 && dt.hour < 3) lateNightPosts++;
      }
    }

    // Puzzle performance
    int solvedCount = puzzles.where((p) => p['solved'] == true).length;
    int totalPuzzles = puzzles.length;

    // Average guesses
    double avgGuesses = puzzles.isEmpty ? 0 :
        puzzles.map((p) => p['guesses'] as int? ?? 5).reduce((a, b) => a + b) /
        puzzles.length;

    // Battle wins
    int battleWins = battleSnap.docs.length;

    // Orbit moments
    int momentCount = momentSnap.docs.length;

    // Compile receipt stats
    final stats = <_ReceiptStat>[
      _ReceiptStat(
        emoji: '🤫',
        title: 'guilty pleasure era',
        value: topMood.isNotEmpty ? topMood : _state.currentEra.isNotEmpty
            ? _state.currentEra : 'chaotic neutral',
        roast: topMoodCount > 2
            ? 'you\'ve been in your $topMood era ${topMoodCount}x this week. therapy is a thing.'
            : 'you\'re emotionally diverse. or just confused. same thing.',
        gradient: const [Color(0xFF8B2FC9), Color(0xFFFF6B9D)],
      ),
      if (mostSkipped.isNotEmpty)
        _ReceiptStat(
          emoji: '⏭️',
          title: 'most skipped song',
          value: mostSkipped,
          roast: 'skipped "$mostSkipped" $mostSkipCount times. why do you even have it?',
          gradient: const [Color(0xFFfc4a1a), Color(0xFFf7b733)],
        ),
      _ReceiptStat(
        emoji: '🌙',
        title: '2am activity',
        value: lateNightPosts > 0 ? '$lateNightPosts late-night posts' : 'surprisingly normal',
        roast: lateNightPosts > 0
            ? 'posting vibes at 2am... you\'re a walking lo-fi playlist. we love it.'
            : 'you went to bed at a normal time? who ARE you.',
        gradient: const [Color(0xFF141e30), Color(0xFF243B55)],
      ),
      _ReceiptStat(
        emoji: '🧩',
        title: 'puzzle brain',
        value: totalPuzzles > 0 ? '$solvedCount/$totalPuzzles solved' : 'skipped puzzles',
        roast: totalPuzzles == 0
            ? 'you didn\'t do a single puzzle. your music IQ is protected by ignorance.'
            : avgGuesses <= 2.0
                ? 'avg ${avgGuesses.toStringAsFixed(1)} guesses. you\'re built different.'
                : 'avg ${avgGuesses.toStringAsFixed(1)} guesses. we don\'t judge (we do).',
        gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
      ),
      _ReceiptStat(
        emoji: '📸',
        title: 'moment energy',
        value: momentCount > 0 ? '$momentCount moments posted' : 'ghost mode',
        roast: momentCount == 0
            ? 'you posted zero orbit moments. living rent-free in no one\'s feed.'
            : momentCount >= 5
                ? '$momentCount moments! you\'re basically the neighborhood news channel.'
                : 'a solid $momentCount moments. present but mysterious.',
        gradient: const [Color(0xFFf953c6), Color(0xFFb91d73)],
      ),
      _ReceiptStat(
        emoji: '⚔️',
        title: 'battle record',
        value: battleWins > 0 ? '$battleWins wins this week' : '0 wins (big rip)',
        roast: battleWins == 0
            ? 'zero battle wins. the playlist gods are not with you.'
            : battleWins >= 3
                ? '$battleWins wins. your taste is undefeated. others fear you.'
                : '$battleWins battle ${battleWins == 1 ? 'win' : 'wins'}. survivable.',
        gradient: const [Color(0xFFf7971e), Color(0xFFffd200)],
      ),
      _ReceiptStat(
        emoji: '🔮',
        title: 'weekly verdict',
        value: _weeklyVerdict(posts.length, battleWins, momentCount, solvedCount),
        roast: 'that\'s your orbit DNA this week. change is possible. or don\'t.',
        gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
        isFinal: true,
      ),
    ];

    if (mounted) {
      setState(() { _stats = stats; _loading = false; });
      _slideCtrl.forward();
    }
  }

  String _weeklyVerdict(int posts, int wins, int moments, int solved) {
    final score = posts + wins * 2 + moments + solved;
    if (score >= 15) return 'orbit royalty 👑';
    if (score >= 8) return 'certified orbiter ⭐';
    if (score >= 3) return 'casual listener 🎵';
    return 'ghost mode activated 👻';
  }

  void _nextCard() {
    if (_page >= _stats.length - 1) return;
    HapticFeedback.lightImpact();
    _slideCtrl.reset();
    setState(() => _page++);
    _slideCtrl.forward();
  }

  void _prevCard() {
    if (_page <= 0) return;
    HapticFeedback.lightImpact();
    _slideCtrl.reset();
    setState(() => _page--);
    _slideCtrl.forward();
  }

  Future<void> _share() async {
    final stat = _stats[_page];
    HapticFeedback.mediumImpact();
    await Share.share(
        '${stat.emoji} my orbit receipt this week:\n\n'
        '${stat.title}: ${stat.value}\n\n'
        '"${stat.roast}"\n\n'
        'see yours on Orbit ✨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('orbit receipts 🧾',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _loading ? null : _share,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AuraTheme.accent, strokeWidth: 2))
          : Column(children: [
              // Page dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_stats.length, (i) => Container(
                    width: i == _page ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AuraTheme.accent
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity! < -200) _nextCard();
                    if (d.primaryVelocity! > 200) _prevCard();
                  },
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: _ReceiptCard(stat: _stats[_page]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevCard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('← back'),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _page < _stats.length - 1 ? _nextCard : _share,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraTheme.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                          _page < _stats.length - 1 ? 'next →' : 'share receipt 📤',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }
}

class _ReceiptStat {
  final String emoji;
  final String title;
  final String value;
  final String roast;
  final List<Color> gradient;
  final bool isFinal;

  const _ReceiptStat({
    required this.emoji,
    required this.title,
    required this.value,
    required this.roast,
    required this.gradient,
    this.isFinal = false,
  });
}

class _ReceiptCard extends StatelessWidget {
  final _ReceiptStat stat;
  const _ReceiptCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stat.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: stat.gradient.first.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(stat.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(stat.title.toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text(stat.value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  height: 1.2),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '"${stat.roast}"',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.6,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          if (stat.isFinal) ...[
            const SizedBox(height: 20),
            Text('week of ${_weekLabel()}',
                style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _weekLabel() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[start.month - 1]} ${start.day}';
  }
}
