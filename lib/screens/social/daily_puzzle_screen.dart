import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily Music Puzzle — guess the song from 5 emojis
//
// Seeded by date so everyone gets the same puzzle.
// Top 10 leaderboard (fewest guesses + fastest time).
// ─────────────────────────────────────────────────────────────────────────────

/// One puzzle entry. Add more songs here to expand the pool.
class _Puzzle {
  final String emojis;    // e.g. '🍸🌙💃🔥🎶'
  final String song;
  final String artist;
  final List<String> hints; // revealed one at a time

  const _Puzzle({
    required this.emojis,
    required this.song,
    required this.artist,
    required this.hints,
  });
}

const _puzzles = [
  _Puzzle(
    emojis: '☕🕐🛋️😴🎹',
    song: 'Coffee',
    artist: 'beabadoobee',
    hints: ['2-word title', "starts with 'C'", 'indie bedroom pop'],
  ),
  _Puzzle(
    emojis: '🌊🏄‍♀️💛🌞🎸',
    song: 'Golden Hour',
    artist: 'JVKE',
    hints: ['2 words', "time of day", 'viral TikTok hit'],
  ),
  _Puzzle(
    emojis: '👻📞🌙🖤💀',
    song: 'Ghost',
    artist: 'Justin Bieber',
    hints: ['one word', 'starts with G', 'pop ballad'],
  ),
  _Puzzle(
    emojis: '☀️💼👔😤🎧',
    song: 'Industry Baby',
    artist: 'Lil Nas X & Jack Harlow',
    hints: ['2 words', 'work theme', 'rap collab 2021'],
  ),
  _Puzzle(
    emojis: '🌹🔥💔🕯️🎻',
    song: 'Happier Than Ever',
    artist: 'Billie Eilish',
    hints: ['3 words', 'comparison in the title', 'Billie Eilish album title'],
  ),
  _Puzzle(
    emojis: '🪩🕺💜🌌🎶',
    song: 'As It Was',
    artist: 'Harry Styles',
    hints: ['3 words', 'time reference', 'starts with A'],
  ),
  _Puzzle(
    emojis: '🧃🍓💖🛹🌈',
    song: 'Good 4 U',
    artist: 'Olivia Rodrigo',
    hints: ['3 words', 'sarcastic tone', 'starts with G'],
  ),
  _Puzzle(
    emojis: '🕊️😇💿🌤️🎙️',
    song: 'Heaven',
    artist: 'Niall Horan',
    hints: ['one word', 'uplifting place', 'starts with H'],
  ),
  _Puzzle(
    emojis: '🌺🏝️🌊🎷🥂',
    song: 'Espresso',
    artist: 'Sabrina Carpenter',
    hints: ['Italian drink', 'one word', 'Summer 2024 anthem'],
  ),
  _Puzzle(
    emojis: '🦋🫀🎹💙🌊',
    song: 'luther',
    artist: 'Kendrick Lamar & SZA',
    hints: ['lowercase title', 'a name', 'collab 2024'],
  ),
  _Puzzle(
    emojis: '🌙✨🌑💫🎵',
    song: 'Midnight Rain',
    artist: 'Taylor Swift',
    hints: ['2 words', 'time + weather', 'Midnights album'],
  ),
  _Puzzle(
    emojis: '🏛️📖🖋️🌿🎼',
    song: 'Betty',
    artist: 'Taylor Swift',
    hints: ['a name', 'starts with B', 'folklore album'],
  ),
  _Puzzle(
    emojis: '🔮🌸🎀👑💞',
    song: 'Flowers',
    artist: 'Miley Cyrus',
    hints: ['one word', 'nature', 'starts with F'],
  ),
  _Puzzle(
    emojis: '🏎️💨🌆🌃🎹',
    song: 'Blinding Lights',
    artist: 'The Weeknd',
    hints: ['2 words', 'sight reference', 'retro synth pop'],
  ),
  _Puzzle(
    emojis: '🌪️👿😈🔥⚡',
    song: 'Anti-Hero',
    artist: 'Taylor Swift',
    hints: ['hyphenated', 'villain theme', 'starts with A'],
  ),
  _Puzzle(
    emojis: '🦁🌍🥁🎸🌅',
    song: 'Africa',
    artist: 'Toto',
    hints: ['one word', 'a continent', 'classic 80s'],
  ),
  _Puzzle(
    emojis: '🧠💭🌀😵🎵',
    song: 'Crazy in Love',
    artist: 'Beyoncé',
    hints: ['3 words', 'emotion + feeling', 'Bey classic'],
  ),
  _Puzzle(
    emojis: '🌧️🏠🪟💔🎹',
    song: 'drivers license',
    artist: 'Olivia Rodrigo',
    hints: ['2 words', 'DMV reference', 'all lowercase'],
  ),
  _Puzzle(
    emojis: '⚡🌩️🎸🤘🔊',
    song: 'Thunderstruck',
    artist: 'AC/DC',
    hints: ['one word', 'weather phenomenon', 'rock anthem'],
  ),
  _Puzzle(
    emojis: '🧸🛁🕯️🌑🎶',
    song: 'Heather',
    artist: 'Conan Gray',
    hints: ['a name', 'starts with H', 'indie pop heartbreak'],
  ),
];

class DailyPuzzleScreen extends StatefulWidget {
  const DailyPuzzleScreen({super.key});

  @override
  State<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends State<DailyPuzzleScreen>
    with SingleTickerProviderStateMixin {
  late _Puzzle _puzzle;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  int _hintsUsed = 0;
  int _guesses = 0;
  bool _solved = false;
  bool _failed = false;
  String _feedbackMsg = '';
  bool _feedbackCorrect = false;
  DateTime? _startTime;
  int _secondsTaken = 0;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _puzzle = _puzzleForToday();
    _startTime = DateTime.now();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
        CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _shakeCtrl.reverse();
    });

    _checkAlreadySolved();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  _Puzzle _puzzleForToday() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return _puzzles[seed % _puzzles.length];
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _checkAlreadySolved() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('puzzle_scores')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: _todayKey)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      final data = snap.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _solved = data['solved'] == true;
        _guesses = data['guesses'] as int? ?? 0;
        _hintsUsed = data['hintsUsed'] as int? ?? 0;
        _secondsTaken = data['secondsTaken'] as int? ?? 0;
      });
    }
  }

  void _guess() {
    final input = _ctrl.text.trim().toLowerCase();
    if (input.isEmpty) return;

    _guesses++;
    final correct = input == _puzzle.song.toLowerCase();

    if (correct) {
      _secondsTaken = DateTime.now().difference(_startTime!).inSeconds;
      HapticFeedback.mediumImpact();
      setState(() {
        _solved = true;
        _feedbackMsg = 'you got it! 🎉';
        _feedbackCorrect = true;
      });
      _saveScore(true);
    } else {
      HapticFeedback.lightImpact();
      _shakeCtrl.forward();
      if (_guesses >= 5) {
        setState(() {
          _failed = true;
          _feedbackMsg = 'the answer was "${_puzzle.song}"';
          _feedbackCorrect = false;
        });
        _saveScore(false);
      } else {
        setState(() {
          _feedbackMsg = 'not quite — try again';
          _feedbackCorrect = false;
        });
      }
    }
    _ctrl.clear();
  }

  void _useHint() {
    if (_hintsUsed >= _puzzle.hints.length || _solved || _failed) return;
    HapticFeedback.selectionClick();
    setState(() => _hintsUsed++);
  }

  Future<void> _saveScore(bool solved) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Orbiter';
    await FirebaseFirestore.instance.collection('puzzle_scores').add({
      'uid': uid,
      'name': displayName,
      'date': _todayKey,
      'solved': solved,
      'guesses': _guesses,
      'hintsUsed': _hintsUsed,
      'secondsTaken': _secondsTaken,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('daily music puzzle',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(_todayKey,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            tooltip: 'Orbit Leaderboard',
            onPressed: () => _showLeaderboard(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Emoji Card
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnim.value *
                  (_shakeCtrl.status == AnimationStatus.forward ? 1 : -1), 0),
              child: child,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AuraTheme.card, AuraTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Column(children: [
                const Text('🎵 what song is this?',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 13, fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 20),
                Text(_puzzle.emojis,
                    style: const TextStyle(fontSize: 46),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                // Progress pips
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _guesses
                        ? (_solved && i == _guesses - 1
                            ? Colors.greenAccent
                            : Colors.red.withOpacity(0.7))
                        : Colors.white.withOpacity(0.15),
                  ),
                ))),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // Hints
          if (_hintsUsed > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AuraTheme.accent.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('hints',
                      style: TextStyle(color: AuraTheme.accent,
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 6),
                  ...List.generate(_hintsUsed, (i) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• ${_puzzle.hints[i]}',
                        style: const TextStyle(color: Colors.white70,
                            fontSize: 13)),
                  )),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Solved / Failed state
          if (_solved || _failed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _solved
                    ? Colors.greenAccent.withOpacity(0.12)
                    : Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _solved
                        ? Colors.greenAccent.withOpacity(0.4)
                        : Colors.redAccent.withOpacity(0.4),
                    width: 1),
              ),
              child: Column(children: [
                Text(_solved ? '🎉' : '💀',
                    style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(_solved ? 'got it!' : 'better luck tomorrow',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 4),
                Text('"${_puzzle.song}" — ${_puzzle.artist}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 14),
                    textAlign: TextAlign.center),
                if (_solved) ...[
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    _StatChip(label: 'guesses', value: '$_guesses'),
                    const SizedBox(width: 10),
                    _StatChip(label: 'hints', value: '$_hintsUsed'),
                    const SizedBox(width: 10),
                    _StatChip(label: 'time', value: '${_secondsTaken}s'),
                  ]),
                ],
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => _showLeaderboard(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('view leaderboard'),
                ),
              ]),
            ),
          ] else ...[
            // Input field
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              onSubmitted: (_) => _guess(),
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'type the song name...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AuraTheme.accent),
                  onPressed: _guess,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Feedback message
            if (_feedbackMsg.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _feedbackCorrect
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_feedbackMsg,
                    style: TextStyle(
                        color: _feedbackCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            const SizedBox(height: 16),
            // Hint + Skip row
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hintsUsed < _puzzle.hints.length && !_solved
                      ? _useHint : null,
                  icon: const Icon(Icons.lightbulb_rounded, size: 16),
                  label: Text(_hintsUsed < _puzzle.hints.length
                      ? 'hint (${_puzzle.hints.length - _hintsUsed} left)'
                      : 'no hints left'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: BorderSide(color: Colors.amber.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _failed = true;
                    _feedbackMsg = 'answer: ${_puzzle.song}';
                    _feedbackCorrect = false;
                    _saveScore(false);
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('give up'),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeaderboardSheet(dateKey: _todayKey),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 10)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardSheet extends StatelessWidget {
  final String dateKey;
  const _LeaderboardSheet({required this.dateKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        const Row(children: [
          Text('orbit leaderboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Spacer(),
          Text('🏆', style: TextStyle(fontSize: 22)),
        ]),
        const SizedBox(height: 4),
        Text('today — $dateKey',
            style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('puzzle_scores')
                .where('date', isEqualTo: dateKey)
                .where('solved', isEqualTo: true)
                .orderBy('guesses')
                .orderBy('secondsTaken')
                .limit(10)
                .get(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: AuraTheme.accent));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('no solvers yet today!',
                    style: TextStyle(color: Colors.white.withOpacity(0.4))));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final medals = ['🥇', '🥈', '🥉'];
                  final rank = i < 3 ? medals[i] : '${i + 1}.';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AuraTheme.accent.withOpacity(0.12)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Text(rank, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['name'] as String? ?? 'Orbiter',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${data['guesses']} guess${data['guesses'] == 1 ? '' : 'es'}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('${data['secondsTaken']}s',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
