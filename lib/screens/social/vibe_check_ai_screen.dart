import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';

// ── Mood option model ─────────────────────────────────────────────────────────
class _Mood {
  final String emoji;
  final String label;
  final Color color;
  final List<String> tags; // Keywords that influence the personality result
  const _Mood(this.emoji, this.label, this.color, this.tags);
}

// ── Personality result model ──────────────────────────────────────────────────
class _Result {
  final String label;     // e.g. "hyperpop menace"
  final String emoji;
  final String description;
  final Color color;
  final List<String> tracks;
  const _Result({
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
    required this.tracks,
  });
}

class VibeCheckAiScreen extends StatefulWidget {
  const VibeCheckAiScreen({super.key});

  @override
  State<VibeCheckAiScreen> createState() => _VibeCheckAiScreenState();
}

class _VibeCheckAiScreenState extends State<VibeCheckAiScreen>
    with TickerProviderStateMixin {
  late AnimationController _bg;
  late AnimationController _pulse;
  late AnimationController _reveal;

  static const _moods = [
    _Mood('🌑', 'dark & moody',   Color(0xFF4F8EFF), ['dark', 'moody', 'melancholy']),
    _Mood('☀️', 'sunny & hype',   Color(0xFFFF9A3C), ['hype', 'bright', 'energy']),
    _Mood('🌸', 'soft & floaty',  Color(0xFFFF6EC7), ['soft', 'pastel', 'gentle']),
    _Mood('⚡', 'wired & chaotic',Color(0xFFFF2D9B), ['chaos', 'energy', 'electric']),
    _Mood('🌿', 'calm & earthy',  Color(0xFF4CAF82), ['calm', 'nature', 'chill']),
    _Mood('🌊', 'deep & oceanic', Color(0xFF22D3EE), ['depth', 'reflective', 'ocean']),
    _Mood('🔥', 'obsessed mode',  Color(0xFFFF6B00), ['obsessed', 'hyperfocus', 'passion']),
    _Mood('🫧', 'dreamy & lost',  Color(0xFFBF5FFF), ['dream', 'ethereal', 'lost']),
  ];

  // Personality results matrix [moodA][moodB] combos simplified to mood index mapping
  static const _results = [
    _Result(
      label: 'dark academia girlie',
      emoji: '📚',
      description: 'You romanticize rainy days, vintage bookshops, and songs that hit different at 2am. Phoebe Bridgers has your whole heart.',
      color: Color(0xFFD4A843),
      tracks: ['Motion Sickness — Phoebe Bridgers', 'Liability — Lorde', 'Godspeed — Frank Ocean'],
    ),
    _Result(
      label: 'hyperpop menace',
      emoji: '⚡',
      description: 'You eat up distorted drops for breakfast. 100 gecs, Charli XCX, and whatever\'s trending on SoundCloud. Pure chaos energy.',
      color: Color(0xFFFF2D9B),
      tracks: ['Speed Drive — Charli XCX', '360 — Charli XCX', 'Ringtone —100 gecs'],
    ),
    _Result(
      label: 'bedroom pop dreamer',
      emoji: '🛏️',
      description: 'Lo-fi beats, indie guitar, songs that sound like having feelings at golden hour. Rex Orange County understands you.',
      color: Color(0xFF7C3AED),
      tracks: ['Golden Hour — JVKE', 'Loving Is Easy — Rex Orange County', 'Retrograde — James Blake'],
    ),
    _Result(
      label: 'cottagecore bard',
      emoji: '🌿',
      description: 'Fleetwood Mac in a meadow. You want folk music and a picnic blanket. Your soul is 40% Taylor Swift folklore era.',
      color: Color(0xFF4CAF82),
      tracks: ['the 1 — Taylor Swift', 'Holocene — Bon Iver', 'Landslide — Fleetwood Mac'],
    ),
    _Result(
      label: 'ocean mystic',
      emoji: '🌊',
      description: 'Deep, introspective, a little dramatic. You\'re a Frank Ocean documentary happening in slow motion. Certified healer.',
      color: Color(0xFF22D3EE),
      tracks: ['Pink + White — Frank Ocean', 'Self Control — Frank Ocean', 'Nikes — Frank Ocean'],
    ),
    _Result(
      label: 'main character syndrome',
      emoji: '🎬',
      description: 'Every song you play is your movie trailer. Olivia Rodrigo is your patron saint. Sour was your villain arc.',
      color: Color(0xFFEC4899),
      tracks: ['good 4 u — Olivia Rodrigo', 'drivers license — Olivia Rodrigo', 'Die With A Smile — Lady Gaga'],
    ),
    _Result(
      label: 'night shift philosopher',
      emoji: '🌙',
      description: 'Big thoughts, heavy playlists. You find meaning in The Weeknd\'s falsetto and Lana Del Rey\'s cinematics.',
      color: Color(0xFF4F8EFF),
      tracks: ['Blinding Lights — The Weeknd', 'Video Games — Lana Del Rey', 'A Case of You — Joni Mitchell'],
    ),
    _Result(
      label: 'vaporwave ghost',
      emoji: '👻',
      description: 'You live between 1984 and the metaverse. Aesthetic is everything. Your playlist is half synthwave, half ambient sadcore.',
      color: Color(0xFFBF5FFF),
      tracks: ['Sunflower — Post Malone', 'Feels Like We Only Go Backwards — Tame Impala', 'New Flesh — Current Joys'],
    ),
  ];

  final _selected = <int>{};
  _Result? _result;
  bool _loading = false;
  int _page = 0; // 0 = mood picker, 1 = loading, 2 = result

  @override
  void initState() {
    super.initState();
    _bg     = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulse  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _bg.dispose();
    _pulse.dispose();
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _analyzeVibe() async {
    if (_selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() { _page = 1; _loading = true; });

    // Simulate AI processing (would call real API in production)
    await Future.delayed(const Duration(milliseconds: 2200));

    // Deterministic result from selection pattern
    final idx = _selected.fold(0, (sum, i) => sum + i) % _results.length;
    _result = _results[idx];

    if (mounted) {
      setState(() { _page = 2; _loading = false; });
      _reveal.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _BgPainter(_bg.value),
            ),
          ),
          // Content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _page == 0
                  ? _moodPicker()
                  : _page == 1
                      ? _loadingScreen()
                      : _resultScreen(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 0: Mood picker ──────────────────────────────────────────────────
  Widget _moodPicker() {
    return Column(
      key: const ValueKey('picker'),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
          ]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AuraTheme.purple, AuraTheme.cyan],
              ).createShader(b),
              child: const Text(
                'vibe check ✦',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'pick everything you\'re feeling rn',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 14),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        // Mood grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.0,
            ),
            itemCount: _moods.length,
            itemBuilder: (_, i) {
              final m = _moods[i];
              final sel = _selected.contains(i);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    sel ? _selected.remove(i) : _selected.add(i);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? m.color.withOpacity(0.18)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel
                          ? m.color.withOpacity(0.7)
                          : Colors.white.withOpacity(0.08),
                      width: sel ? 1.8 : 1,
                    ),
                    boxShadow: sel
                        ? [BoxShadow(
                            color: m.color.withOpacity(0.25),
                            blurRadius: 12)]
                        : [],
                  ),
                  child: Row(children: [
                    Text(m.emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.label,
                          style: TextStyle(
                            color: sel ? m.color : Colors.white54,
                            fontWeight: sel
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 12,
                          )),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        // Analyse button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: GestureDetector(
            onTap: _selected.isEmpty ? null : _analyzeVibe,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _selected.isNotEmpty
                    ? const LinearGradient(
                        colors: [AuraTheme.purple, AuraTheme.cyan])
                    : null,
                color: _selected.isEmpty
                    ? Colors.white.withOpacity(0.06)
                    : null,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _selected.isEmpty
                    ? 'pick at least one vibe'
                    : 'read my vibe ✦',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selected.isEmpty
                      ? Colors.white30
                      : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Page 1: Loading / AI "thinking" ──────────────────────────────────────
  Widget _loadingScreen() {
    return Center(
      key: const ValueKey('loading'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 80 + _pulse.value * 20,
            height: 80 + _pulse.value * 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraTheme.purple.withOpacity(0.12 + _pulse.value * 0.08),
              border: Border.all(
                  color: AuraTheme.purple.withOpacity(0.4 + _pulse.value * 0.3),
                  width: 2),
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
        const SizedBox(height: 28),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AuraTheme.purple, AuraTheme.cyan],
          ).createShader(b),
          child: const Text(
            'reading your vibe…',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'analyzing your energy signature',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      ]),
    );
  }

  // ── Page 2: Result ────────────────────────────────────────────────────────
  Widget _resultScreen() {
    final r = _result!;
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (_, child) => Opacity(
          opacity: _reveal.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _reveal.value) * 30),
            child: child,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() {
                  _page = 0;
                  _selected.clear();
                  _result = null;
                  _reveal.reset();
                }),
              ),
            ]),
            const SizedBox(height: 8),
            // Label
            Center(
              child: Column(children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Text(
                    r.emoji,
                    style: TextStyle(
                        fontSize: 64 + _pulse.value * 8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'you are a',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [r.color, AuraTheme.purple],
                  ).createShader(b),
                  child: Text(
                    r.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            // Description card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: r.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: r.color.withOpacity(0.25), width: 1.5),
              ),
              child: Text(
                r.description,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            // Playlist
            Text(
              'your vibe playlist ✦',
              style: TextStyle(
                  color: r.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3),
            ),
            const SizedBox(height: 10),
            ...r.tracks.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AuraTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: r.color.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: r.color.withOpacity(0.15),
                  ),
                  child: Center(
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              color: r.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
                Icon(Icons.play_circle_outline_rounded,
                    color: r.color.withOpacity(0.6), size: 20),
              ]),
            )),
            const SizedBox(height: 20),
            // Redo button
            GestureDetector(
              onTap: () => setState(() {
                _page = 0;
                _selected.clear();
                _result = null;
                _reveal.reset();
              }),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text(
                  'check again →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  const _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = AuraTheme.background);

    for (int i = 0; i < 3; i++) {
      final cx = size.width * [0.2, 0.8, 0.5][i];
      final cy = size.height * [0.25, 0.55, 0.8][i];
      final r  = size.width * 0.4 +
          math.sin(t * 2 * math.pi + i * 2) * 40;
      final colors = [
        [AuraTheme.purple, AuraTheme.cyan],
        [AuraTheme.accent, AuraTheme.pink],
        [AuraTheme.cyan, AuraTheme.purple],
      ][i];
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            colors[0].withOpacity(0.08),
            Colors.transparent,
          ]).createShader(
              Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}
