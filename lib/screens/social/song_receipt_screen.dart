import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Song Receipt — monthly AI-flavored receipt of your music consumption
// Funny, shareable, uniquely Orbit
// ─────────────────────────────────────────────────────────────────────────────

class SongReceiptScreen extends StatefulWidget {
  const SongReceiptScreen({super.key});
  @override
  State<SongReceiptScreen> createState() => _SongReceiptScreenState();
}

class _SongReceiptScreenState extends State<SongReceiptScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool _loading = true;
  late AnimationController _rollCtrl;
  late Animation<double> _rollAnim;

  // Stats
  int _songsVibed = 0;
  int _momentsPosted = 0;
  int _battlesEntered = 0;
  int _puzzlesSolved = 0;
  int _hoursInFeelings = 0;
  int _lateNightSessions = 0;  // proxy from moments posted after midnight
  int _skipCount = 0;

  // Funny lines generated from data
  String _topLine = '';
  String _verdict = '';
  String _footer = '';

  @override
  void initState() {
    super.initState();
    _rollCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _rollAnim = CurvedAnimation(parent: _rollCtrl, curve: Curves.easeOut);
    _loadStats();
  }

  @override
  void dispose() {
    _rollCtrl.dispose();
    super.dispose();
  }

  String get _monthLabel {
    final now = DateTime.now();
    return ['January','February','March','April','May','June',
        'July','August','September','October','November','December'][now.month - 1];
  }

  Future<void> _loadStats() async {
    final uid = _uid;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthStartTs = Timestamp.fromDate(monthStart);

    if (uid != null) {
      // Pulse posts this month
      try {
        final posts = await _db.collection('pulse_posts')
            .where('uid', isEqualTo: uid)
            .where('createdAt', isGreaterThan: monthStartTs)
            .get();
        _songsVibed = posts.docs.length;
      } catch (_) {}

      // Orbit moments this month
      try {
        final moments = await _db.collection('orbit_moments')
            .where('uid', isEqualTo: uid)
            .where('createdAt', isGreaterThan: monthStartTs)
            .get();
        _momentsPosted = moments.docs.length;
        // Count late-night (hour 22-4)
        for (final d in moments.docs) {
          final ts = (d.data() as Map)['createdAt'];
          if (ts is Timestamp) {
            final h = ts.toDate().hour;
            if (h >= 22 || h <= 4) _lateNightSessions++;
          }
        }
      } catch (_) {}

      // Battles
      try {
        final battles = await _db.collection('song_battles')
            .where('challengerId', isEqualTo: uid)
            .where('createdAt', isGreaterThan: monthStartTs)
            .get();
        final battles2 = await _db.collection('song_battles')
            .where('opponentId', isEqualTo: uid)
            .where('createdAt', isGreaterThan: monthStartTs)
            .get();
        _battlesEntered = battles.docs.length + battles2.docs.length;
      } catch (_) {}

      // Puzzles
      try {
        final puzzles = await _db.collection('puzzle_scores')
            .where('uid', isEqualTo: uid)
            .where('solved', isEqualTo: true)
            .where('createdAt', isGreaterThan: monthStartTs)
            .get();
        _puzzlesSolved = puzzles.docs.length;
      } catch (_) {}
    }

    // Local stats
    _skipCount = _state.myMoments.length * 3; // proxy
    _hoursInFeelings = _lateNightSessions * 2 + (_momentsPosted ~/ 2);

    // Generate funny copy
    _generateCopy();

    setState(() => _loading = false);
    _rollCtrl.forward();
  }

  void _generateCopy() {
    final era = _state.currentEra;
    final mood = _state.mood;
    final streak = _state.streakCount;

    // Top descriptor line
    if (era == 'villain era') {
      _topLine = 'your villain arc is well-funded';
    } else if (era == 'healing era') {
      _topLine = 'you\'re healing. slowly. with playlists.';
    } else if (era == 'chaos era') {
      _topLine = 'forensic analysts are baffled by your queue';
    } else if (era == 'delulu era') {
      _topLine = 'manifesting via music. no notes.';
    } else if (mood == 'sad' || mood == 'heartbroken') {
      _topLine = 'this is a safe space. we don\'t judge.';
    } else if (_lateNightSessions > 5) {
      _topLine = 'you\'re a 2am person. we see you.';
    } else if (streak > 14) {
      _topLine = 'you\'re committed. therapy might also help.';
    } else {
      _topLine = 'a complete record of your music crimes';
    }

    // Verdict
    if (_hoursInFeelings > 20) {
      _verdict = '"emotionally expensive listener"';
    } else if (_battlesEntered > 5) {
      _verdict = '"chronically competitive orbiter"';
    } else if (_puzzlesSolved > 15) {
      _verdict = '"suspiciously good at music trivia"';
    } else if (_momentsPosted > 20) {
      _verdict = '"always in the moment, literally"';
    } else {
      _verdict = '"mysterious orbit energy"';
    }

    // Footer
    final footers = [
      'no refunds on emotional damage caused by this receipt',
      'please consult a therapist before your next playlist',
      'this store is not responsible for your music choices',
      'have you considered touching grass? asking for a friend',
      'we accept fire reactions, not returns',
    ];
    final idx = DateTime.now().day % footers.length;
    _footer = footers[idx];
  }

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    final text = '''
🧾 MY ORBIT RECEIPT — $_monthLabel

songs vibed to ............. $_songsVibed
hours in my feelings ........ $_hoursInFeelings
moments captured ............ $_momentsPosted
late-night sessions ......... $_lateNightSessions
battles entered ............. $_battlesEntered
puzzles solved .............. $_puzzlesSolved
songs rage-skipped .......... $_skipCount

VERDICT: $_verdict

$_footer

find me on Orbit ✨
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
          const Text('song receipt',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(_monthLabel,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
        actions: [
          if (!_loading)
            IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: _share),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AuraTheme.accent))
          : FadeTransition(
              opacity: _rollAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(children: [
                  // Receipt card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF1a1a1a),
                          fontSize: 13,
                          height: 1.5),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Header
                        Center(
                          child: Column(children: [
                            const Text('* * * ORBIT * * *',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 2)),
                            const SizedBox(height: 2),
                            Text(_monthLabel.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12, letterSpacing: 1)),
                            const SizedBox(height: 2),
                            Text(_topLine,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11)),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        _divider(),
                        const SizedBox(height: 8),

                        // Line items
                        _receiptRow('🎵 songs vibed to', '$_songsVibed'),
                        _receiptRow('😭 hrs in my feelings', '$_hoursInFeelings'),
                        _receiptRow('📸 moments captured', '$_momentsPosted'),
                        _receiptRow('🌙 late-night sessions', '$_lateNightSessions'),
                        _receiptRow('⚔️ battles entered', '$_battlesEntered'),
                        _receiptRow('🧩 puzzles solved', '$_puzzlesSolved'),
                        _receiptRow('⏭️ songs rage-skipped', '$_skipCount'),

                        const SizedBox(height: 8),
                        _divider(),
                        const SizedBox(height: 10),

                        // Verdict
                        Center(
                          child: Column(children: [
                            const Text('VERDICT',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(_verdict,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                                textAlign: TextAlign.center),
                          ]),
                        ),

                        const SizedBox(height: 12),
                        _divider(),
                        const SizedBox(height: 8),

                        // Footer
                        Center(
                          child: Text(_footer,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF1a1a1a).withOpacity(0.5),
                                  fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center),
                        ),

                        const SizedBox(height: 8),
                        // Barcode-ish
                        Center(
                          child: Column(children: [
                            _divider(),
                            const SizedBox(height: 6),
                            const Text('orbit.app', style: TextStyle(
                                letterSpacing: 3, fontSize: 10)),
                            const SizedBox(height: 4),
                            // Fake barcode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(30, (i) {
                                final widths = [1.0, 2.0, 1.5, 3.0, 1.0, 2.5, 1.0, 2.0];
                                return Container(
                                  width: widths[i % widths.length],
                                  height: 24,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                  color: const Color(0xFF1a1a1a),
                                );
                              }),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share_rounded,
                          color: Colors.white),
                      label: const Text('post your receipt',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraTheme.accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('refreshes on the 1st of each month',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 11),
                      textAlign: TextAlign.center),
                ]),
              ),
            ),
    );
  }

  Widget _receiptRow(String label, String value) {
    final dots = '.' * (38 - label.length - value.length).clamp(2, 38);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text('$label$dots$value'),
    );
  }

  Widget _divider() {
    return const Text(
        '- - - - - - - - - - - - - - - - - - - - - -',
        style: TextStyle(color: Color(0xFF888888), fontSize: 11));
  }
}
