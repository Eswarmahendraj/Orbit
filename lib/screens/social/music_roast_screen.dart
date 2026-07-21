import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Music Roast — AI-flavored roast of your listening personality
// Template-based using real user data for maximum accuracy + humor
// ─────────────────────────────────────────────────────────────────────────────

class MusicRoastScreen extends StatefulWidget {
  const MusicRoastScreen({super.key});
  @override
  State<MusicRoastScreen> createState() => _MusicRoastScreenState();
}

class _MusicRoastScreenState extends State<MusicRoastScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();

  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  bool _revealed = false;
  List<String> _roastLines = [];
  String _title = '';
  String _closing = '';

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _generateRoast();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  void _generateRoast() {
    final era = _state.currentEra;
    final mood = _state.mood;
    final streak = _state.streakCount;
    final vibe = _state.vibeStatus;
    final name = _state.displayName;
    final hasVibeActive = _state.vibeActive;
    final song = _state.vibeSong;

    final lines = <String>[];

    // ── Opening line ──────────────────────────────────────────────────────────
    if (era == 'villain era') {
      lines.add('$name. the villain era. we love the commitment to the bit.');
    } else if (era == 'healing era') {
      lines.add('$name said "i\'m healing" and then made a 4-hour sad playlist. relatable.');
    } else if (era == 'chaos era') {
      lines.add('$name\'s music taste is what would happen if a shuffle algorithm had a breakdown.');
    } else if (era == 'delulu era') {
      lines.add('$name manifests via music. the delulu to achievement pipeline is real, apparently.');
    } else if (era == 'coquette era') {
      lines.add('$name. coquette era. you definitely own a bow and a Lana Del Rey vinyl.');
    } else if (era == 'revenge era') {
      lines.add('$name\'s revenge era. we respect the petty. we support the petty.');
    } else if (era == 'soft life era') {
      lines.add('$name chose soft life. the aux chord is just guided meditation at this point.');
    } else if (era == 'academia era') {
      lines.add('$name. dark academia era. "studying" with a 3-hour piano playlist again.');
    } else if (era == 'main character') {
      lines.add('$name believes they\'re the main character. and honestly? the playlist confirms it.');
    } else {
      lines.add('we analyzed $name\'s entire music personality. what we found was... something.');
    }

    // ── Streak line ───────────────────────────────────────────────────────────
    if (streak > 30) {
      lines.add('$streak day streak. you\'ve been on here longer than most situationships.');
    } else if (streak > 14) {
      lines.add('$streak days straight. the app is literally the most stable thing in your life rn.');
    } else if (streak > 7) {
      lines.add('$streak day streak. you\'re consistent with this and nothing else. respect.');
    } else if (streak > 0) {
      lines.add('$streak day streak. you\'re trying. we see it.');
    } else {
      lines.add('streak at 0. the accountability era wasn\'t for you.');
    }

    // ── Mood / vibe line ──────────────────────────────────────────────────────
    if (mood == 'sad' || mood == 'heartbroken') {
      lines.add('the current mood is "${_state.moodEmoji} $mood." we\'re not surprised. have you tried water?');
    } else if (mood == 'chaotic') {
      lines.add('"${_state.moodEmoji} $mood" — the music makes more sense now. barely, but still.');
    } else if (mood == 'in my feelings') {
      lines.add('in their feelings, permanently, no plans to leave. very on-brand.');
    } else if (mood == 'chill') {
      lines.add('"${_state.moodEmoji} $mood" — sure, the chill era. we believe you. (we don\'t.)');
    } else {
      lines.add('"${_state.moodEmoji} $mood" is the current vibe. make it make sense. (it doesn\'t have to.)');
    }

    // ── Current song line ─────────────────────────────────────────────────────
    if (hasVibeActive && song.isNotEmpty) {
      lines.add('"$song" is currently the vibe. this tells us everything we needed to know.');
    }

    // ── Vibe status line ──────────────────────────────────────────────────────
    if (vibe.isNotEmpty) {
      lines.add('"$vibe" — the status. typed it. posted it. meant every word. respect.');
    }

    // ── Closing verdict ───────────────────────────────────────────────────────
    final verdicts = [
      'our diagnosis: chronically online, emotionally complex, good taste (mostly).',
      'verdict: a walking playlist waiting to happen. we\'re here for it.',
      'in conclusion: chaotic, iconic, and 100% an orbit main character.',
      'final note: we\'ve seen worse. we\'ve also seen better. you\'re comfortably in between.',
      'the jury has decided: your music taste is a personality. lean in.',
      'closing statement: therapy and a good aux cord. that\'s the full treatment plan.',
    ];
    final idx = (_state.streakCount + _state.sotdReactionCount) % verdicts.length;

    _roastLines = lines;
    _title = '🔥 your music roast 🔥';
    _closing = verdicts[idx];
  }

  Future<void> _reveal() async {
    HapticFeedback.heavyImpact();
    setState(() => _revealed = true);
    _revealCtrl.forward();
  }

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    final text = '''
🔥 MY ORBIT MUSIC ROAST 🔥

${_roastLines.join('\n\n')}

$_closing

get roasted on Orbit ✨
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
        title: const Text('music roast 🔥',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          if (_revealed)
            IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: _share),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: !_revealed
            ? _buildTeaser()
            : FadeTransition(
                opacity: _revealAnim,
                child: _buildRoast(),
              ),
      ),
    );
  }

  Widget _buildTeaser() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 40),
      const Text('🎤', style: TextStyle(fontSize: 80)),
      const SizedBox(height: 24),
      const Text('your music roast is ready',
          style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 24),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('we analyzed your listening personality.\nit\'s... something.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('are you sure you\'re ready?',
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 40),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _reveal,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4444),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: const Text('roast me 🔥',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
      const SizedBox(height: 12),
      Text('this might hurt',
          style: TextStyle(color: Colors.white.withOpacity(0.25),
              fontSize: 11, fontStyle: FontStyle.italic)),
    ]);
  }

  Widget _buildRoast() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Text(_title,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 22),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      Center(
        child: Text('based on your actual orbit data',
            style: TextStyle(color: Colors.white.withOpacity(0.35),
                fontSize: 11)),
      ),
      const SizedBox(height: 24),
      ..._roastLines.asMap().entries.map((e) {
        return _RoastLine(text: e.value, index: e.key);
      }),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF4444), Color(0xFFFF8800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(_closing,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 14),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
          label: const Text('share this roast',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraTheme.accent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ]);
  }
}

class _RoastLine extends StatelessWidget {
  final String text;
  final int index;
  const _RoastLine({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 120),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withOpacity(0.07), width: 1),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white,
                fontSize: 14, height: 1.5)),
      ),
    );
  }
}
