import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../reels/create_pulse_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────────────────────

enum PulseType { vybe, collective, battle, drop, snap }

class PulseCard {
  final PulseType type;
  final String song;
  final String artist;
  final String? previewUrl;
  final String? artUrl;
  final List<Color> gradient;
  final String username;
  final String displayName;
  final String avatarEmoji;
  final String mood;
  final String moodEmoji;
  final String caption;
  final int fires;
  final int comments;
  final List<Map<String, String>> others;
  final String? songB;
  final String? artistB;
  final int votesA;
  final int votesB;
  final bool isDrop;
  final String? dropLabel;

  const PulseCard({
    required this.type,
    required this.song,
    required this.artist,
    this.previewUrl,
    this.artUrl,
    required this.gradient,
    required this.username,
    required this.displayName,
    required this.avatarEmoji,
    required this.mood,
    required this.moodEmoji,
    required this.caption,
    required this.fires,
    required this.comments,
    this.others = const [],
    this.songB,
    this.artistB,
    this.votesA = 50,
    this.votesB = 50,
    this.isDrop = false,
    this.dropLabel,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Seed Data
// ─────────────────────────────────────────────────────────────────────────────

const _seedCards = [
  PulseCard(
    type: PulseType.drop,
    song: 'Espresso',
    artist: 'Sabrina Carpenter',
    previewUrl: 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview126/v4/f3/59/61/f35961d7-45a7-6c4e-44c9-7d57e74de695/mzaf_17841427633730504268.plus.aac.p.m4a',
    gradient: [Color(0xFFFF6B35), Color(0xFFFF8C42), Color(0xFFFFD166)],
    username: '@maya.k', displayName: 'Maya K', avatarEmoji: '🎧',
    mood: '2am energy', moodEmoji: '🌙',
    caption: 'literally can\'t stop listening to this ☕',
    fires: 2341, comments: 187, isDrop: true, dropLabel: '🔥 Drop of the Hour',
  ),
  PulseCard(
    type: PulseType.vybe,
    song: 'luther', artist: 'Kendrick Lamar & SZA',
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF1A1A2E)],
    username: '@zara.w', displayName: 'Zara W', avatarEmoji: '🌙',
    mood: 'heartbreak', moodEmoji: '💔',
    caption: 'playing this on repeat at 3am again. send help.',
    fires: 891, comments: 64,
  ),
  PulseCard(
    type: PulseType.collective,
    song: 'APT.', artist: 'ROSÉ & Bruno Mars',
    gradient: [Color(0xFFFC466B), Color(0xFF3F5EFB), Color(0xFF0D0D0D)],
    username: '@dev.s', displayName: 'Dev S', avatarEmoji: '🔥',
    mood: 'hype', moodEmoji: '🔥',
    caption: '5 people in your orbit are obsessed with this right now',
    fires: 1204, comments: 98,
    others: [
      {'name': 'maya.k', 'emoji': '🎧', 'quote': 'this is my personality rn'},
      {'name': 'rina.p', 'emoji': '✨', 'quote': 'apt apt apt apt apt'},
      {'name': 'leo.k', 'emoji': '💜', 'quote': 'someone stop me'},
      {'name': 'kai.r', 'emoji': '⚡', 'quote': 'this has been on loop for 3 days'},
    ],
  ),
  PulseCard(
    type: PulseType.vybe,
    song: 'Golden Hour', artist: 'JVKE',
    gradient: [Color(0xFFF7971E), Color(0xFFFFD200), Color(0xFFFF6B6B)],
    username: '@rina.p', displayName: 'Rina P', avatarEmoji: '✨',
    mood: 'focused', moodEmoji: '🎯',
    caption: 'studying with this on. somehow it works.',
    fires: 445, comments: 31,
  ),
  PulseCard(
    type: PulseType.battle,
    song: 'Blinding Lights', artist: 'The Weeknd',
    songB: 'As It Was', artistB: 'Harry Styles',
    gradient: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    username: '@sam.w', displayName: 'Sam W', avatarEmoji: '🎸',
    mood: 'battle', moodEmoji: '🥊',
    caption: 'settle this once and for all',
    fires: 3102, comments: 256, votesA: 63, votesB: 37,
  ),
  PulseCard(
    type: PulseType.vybe,
    song: 'Peaches', artist: 'Justin Bieber ft. Daniel Caesar',
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFF0D3B35)],
    username: '@leo.k', displayName: 'Leo K', avatarEmoji: '💜',
    mood: 'chill', moodEmoji: '☀️',
    caption: 'sunday morning energy hits different 🍑',
    fires: 678, comments: 45,
  ),
  PulseCard(
    type: PulseType.collective,
    song: 'Die With A Smile', artist: 'Lady Gaga & Bruno Mars',
    gradient: [Color(0xFFE96C9D), Color(0xFFF6A623), Color(0xFF1A0A2E)],
    username: '@ari.c', displayName: 'Ari C', avatarEmoji: '🌊',
    mood: 'euphoric', moodEmoji: '✨',
    caption: '3 of your orbit are crying to this right now',
    fires: 988, comments: 77,
    others: [
      {'name': 'jay.r', 'emoji': '☀️', 'quote': 'every single time man'},
      {'name': 'mia.t', 'emoji': '🌸', 'quote': '😭😭😭'},
      {'name': 'zara.w', 'emoji': '🌙', 'quote': 'I can\'t take this'},
    ],
  ),
  PulseCard(
    type: PulseType.vybe,
    song: 'Levitating', artist: 'Dua Lipa',
    gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE), Color(0xFF0A0A1A)],
    username: '@mia.t', displayName: 'Mia T', avatarEmoji: '🌸',
    mood: 'nostalgia', moodEmoji: '🌊',
    caption: 'this takes me back to 2021. simpler times fr.',
    fires: 534, comments: 29,
  ),
  PulseCard(
    type: PulseType.drop,
    song: 'STAY', artist: 'The Kid LAROI & Justin Bieber',
    gradient: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    username: '@kai.r', displayName: 'Kai R', avatarEmoji: '⚡',
    mood: '2am feels', moodEmoji: '🌙',
    caption: 'your orbit is losing sleep to this right now',
    fires: 1876, comments: 134, isDrop: true, dropLabel: '🌙 Late Night Drop',
  ),
  PulseCard(
    type: PulseType.vybe,
    song: 'Blinding Lights', artist: 'The Weeknd',
    gradient: [Color(0xFFFF0080), Color(0xFF7928CA), Color(0xFF0D0D0D)],
    username: '@jay.r', displayName: 'Jay R', avatarEmoji: '☀️',
    mood: 'hype', moodEmoji: '⚡',
    caption: 'gym mode activated. don\'t talk to me. 🏋️',
    fires: 723, comments: 52,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Particle / Ripple / Note data classes
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy, r, life;
  final Color color;
  _Particle({required this.x, required this.y, required this.vx,
      required this.vy, required this.r, required this.color})
      : life = 1.0;
  void update() {
    x += vx; y += vy; vy += 0.15; vx *= 0.97;
    life = math.max(0, life - 0.024);
  }
}

class _Ripple {
  double x, y, r, life;
  final double maxR;
  final Color color;
  _Ripple({required this.x, required this.y,
      required this.maxR, required this.color})
      : r = 0, life = 1.0;
  void update() {
    r += (maxR - r) * 0.07;
    life = math.max(0, life - 0.022);
  }
}

class _FloatNote {
  double x, y, life;
  final double vy, scale;
  final String emoji;
  _FloatNote({required this.x, required this.y, required this.vy,
      required this.emoji, required this.scale})
      : life = 1.0;
  void update() {
    y += vy;
    life = math.max(0, life - 0.008);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle System  (ChangeNotifier — drives its own repaint via createTicker)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleSystem extends ChangeNotifier {
  final List<_Particle> particles = [];
  final List<_Ripple> ripples = [];
  final List<_FloatNote> notes = [];
  late final Ticker _ticker;
  final _rng = math.Random();
  bool active = true;
  int _frame = 0;

  static const _noteEmojis = ['♪', '♫', '♩', '🎵', '🎶'];

  _ParticleSystem(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void _onTick(Duration _) {
    _frame++;
    if (!active) return;
    // auto floating notes every ~55 frames
    if (_frame % 55 == 0) _autoNote();
    for (final p in particles) p.update();
    particles.removeWhere((p) => p.life <= 0);
    for (final r in ripples) r.update();
    ripples.removeWhere((r) => r.life <= 0);
    for (final n in notes) n.update();
    notes.removeWhere((n) => n.life <= 0);
    notifyListeners();
  }

  void _autoNote() {
    notes.add(_FloatNote(
      x: 30 + _rng.nextDouble() * 230,
      y: 450 + _rng.nextDouble() * 40,
      vy: -0.9 - _rng.nextDouble() * 0.5,
      emoji: _noteEmojis[_rng.nextInt(_noteEmojis.length)],
      scale: 0.8 + _rng.nextDouble() * 0.5,
    ));
  }

  void spawnBurst(Offset pos, Color color, {int count = 22}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = _rng.nextDouble() * 5 + 1.5;
      particles.add(_Particle(
        x: pos.dx + _rng.nextDouble() * 40 - 20,
        y: pos.dy + _rng.nextDouble() * 20 - 10,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 2,
        r: _rng.nextDouble() * 4 + 1.5,
        color: color,
      ));
    }
    for (int i = 0; i < 4; i++) {
      notes.add(_FloatNote(
        x: pos.dx + _rng.nextDouble() * 80 - 40,
        y: pos.dy,
        vy: -1.5 - _rng.nextDouble(),
        emoji: _noteEmojis[_rng.nextInt(_noteEmojis.length)],
        scale: 1.0 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  void spawnRipple(Offset pos, Color color) =>
      ripples.add(_Ripple(x: pos.dx, y: pos.dy, maxR: 100, color: color));

  void spawnBeatBurst(Offset pos, Color color) {
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = _rng.nextDouble() * 3 + 1;
      particles.add(_Particle(
        x: pos.dx + _rng.nextDouble() * 30 - 15,
        y: pos.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 1.5,
        r: _rng.nextDouble() * 2.5 + 1,
        color: color,
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PulseScreen
// ─────────────────────────────────────────────────────────────────────────────

class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});
  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen> {
  final _player = AudioPlayer();
  final _pageCtrl = PageController();
  int _tab = 0;
  int _currentIndex = 0;
  final Set<int> _fired = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCard(0));
  }

  @override
  void dispose() {
    _player.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _playCard(int index) async {
    final url = _seedCards[index].previewUrl;
    try {
      await _player.stop();
      if (url != null && url.isNotEmpty) {
        await _player.setUrl(url);
        await _player.setLoopMode(LoopMode.one);
        await _player.play();
      }
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _playCard(index);
  }

  void _toggleFire(int index) => setState(() {
        if (_fired.contains(index)) _fired.remove(index);
        else _fired.add(index);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _TabChip(label: 'For You', selected: _tab == 0,
              onTap: () => setState(() => _tab = 0)),
          const SizedBox(width: 12),
          _TabChip(label: 'Your Orbit', selected: _tab == 1,
              onTap: () => setState(() => _tab = 1)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {}),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AuraTheme.accent, AuraTheme.accentLight],
              ).createShader(b),
              child: const Text('pulse',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ),
          ),
        ),
      ),
      body: Stack(children: [
        PageView.builder(
          controller: _pageCtrl,
          scrollDirection: Axis.vertical,
          itemCount: _seedCards.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (_, i) => _PulseCardWidget(
            card: _seedCards[i],
            index: i,
            isActive: _currentIndex == i,
            fired: _fired.contains(i),
            onFire: () => _toggleFire(i),
            player: _player,
          ),
        ),
        if (_currentIndex == 0)
          const Positioned(bottom: 100, left: 0, right: 0, child: _ScrollHint()),
      ]),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreatePulseScreen())),
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AuraTheme.accent, AuraTheme.accentLight],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AuraTheme.accent.withOpacity(0.5),
                  blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PulseCardWidget
// ─────────────────────────────────────────────────────────────────────────────

class _PulseCardWidget extends StatefulWidget {
  final PulseCard card;
  final int index;
  final bool isActive;
  final bool fired;
  final VoidCallback onFire;
  final AudioPlayer player;

  const _PulseCardWidget({
    required this.card, required this.index, required this.isActive,
    required this.fired, required this.onFire, required this.player,
  });

  @override
  State<_PulseCardWidget> createState() => _PulseCardWidgetState();
}

class _PulseCardWidgetState extends State<_PulseCardWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _bgCtrl;    // 8s — slow bg rotation + viz
  late final AnimationController _beatCtrl;  // 469ms — 128bpm beat pulse
  late final AnimationController _vinylCtrl; // 3s — vinyl rotation
  late final AnimationController _fireCtrl;  // 400ms — fire bounce
  late final Animation<double> _fireAnim;

  // Particle system
  late final _ParticleSystem _ps;

  // Battle state
  int? _battleVote;
  late int _votesA, _votesB;
  bool _captionExpanded = false;

  // Beat burst tracking
  int _beatCount = 0;
  final _rng = math.Random();

  Color get _accent => widget.card.gradient.first;

  @override
  void initState() {
    super.initState();
    _votesA = widget.card.votesA;
    _votesB = widget.card.votesB;

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();

    _beatCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 469))..repeat();

    _vinylCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat();

    _fireCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fireAnim = Tween<double>(begin: 1.0, end: 1.5)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_fireCtrl);

    _ps = _ParticleSystem(this);

    // Beat-triggered micro bursts every 4 beats
    _beatCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && widget.isActive) {
        _beatCount++;
        if (_beatCount % 4 == 0) {
          _ps.spawnBeatBurst(
            Offset(60 + _rng.nextDouble() * 200, 480),
            _accent,
          );
        }
      }
    });

    // Initial particle burst when card loads active
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sz = MediaQuery.of(context).size;
        _ps.spawnBurst(Offset(sz.width * 0.6, sz.height * 0.48), _accent, count: 16);
        _ps.spawnRipple(Offset(sz.width * 0.5, sz.height * 0.48), _accent);
      });
    }
  }

  @override
  void didUpdateWidget(_PulseCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ps.active = true;
      final sz = MediaQuery.of(context).size;
      _ps.spawnBurst(Offset(sz.width * 0.6, sz.height * 0.48), _accent, count: 12);
      _ps.spawnRipple(Offset(sz.width * 0.5, sz.height * 0.48), _accent);
    } else if (!widget.isActive) {
      _ps.active = false;
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _beatCtrl.dispose();
    _vinylCtrl.dispose();
    _fireCtrl.dispose();
    _ps.dispose();
    super.dispose();
  }

  void _onFire() {
    widget.onFire();
    _fireCtrl.forward(from: 0);
    final sz = MediaQuery.of(context).size;
    _ps.spawnBurst(Offset(sz.width - 28, sz.height * 0.58), Colors.deepOrange, count: 28);
    _ps.spawnRipple(Offset(sz.width - 28, sz.height * 0.58), Colors.orange);
  }

  void _castVote(int side) {
    if (_battleVote != null) return;
    setState(() {
      _battleVote = side;
      if (side == 0) _votesA += 4; else _votesB += 4;
    });
  }

  // beat amplitude: sharp attack at cycle start, decays to 0 by 40%
  double get _beat => math.max(0.0, 1.0 - _beatCtrl.value * 2.5);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final card = widget.card;

    return AnimatedBuilder(
      animation: Listenable.merge([_bgCtrl, _beatCtrl, _vinylCtrl]),
      builder: (_, __) {
        final beat = _beat;
        return Stack(fit: StackFit.expand, children: [

          // ── Layer 1: Animated gradient bg + aurora streaks + vignette ──
          CustomPaint(
            painter: _GradientBgPainter(
              colors: card.gradient,
              progress: _bgCtrl.value,
              beat: beat,
            ),
          ),

          // ── Layer 2: Radial freq bars + waveform + rings + aura glow ──
          CustomPaint(
            painter: _VisualizerPainter(
              progress: _bgCtrl.value,
              beat: beat,
              accentColor: _accent,
              isActive: widget.isActive,
            ),
          ),

          // ── Layer 3: Particles + ripples + floating notes (self-repaints) ──
          RepaintBoundary(
            child: CustomPaint(
              painter: _ParticleRipplePainter(system: _ps),
              size: size,
            ),
          ),

          // ── Beat flash ──
          if (beat > 0.75 && widget.isActive)
            IgnorePointer(
              child: Container(
                color: Colors.white.withOpacity((beat - 0.75) * 0.1),
              ),
            ),

          // ── Drop badge ──
          if (card.isDrop && card.dropLabel != null)
            Positioned(
              top: 100, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AuraTheme.accent.withOpacity(0.6)),
                  ),
                  child: Text(card.dropLabel!,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3)),
                ),
              ),
            ),

          // ── Type-specific overlays ──
          if (card.type == PulseType.collective) _CollectiveOverlay(card: card)
          else if (card.type == PulseType.battle)
            _BattleOverlay(card: card, votesA: _votesA, votesB: _votesB,
                myVote: _battleVote, onVote: _castVote),

          // ── Bottom + top gradient fades ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0, height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Right action buttons + animated vinyl ──
          Positioned(
            right: 14, bottom: 120,
            child: Column(children: [
              _ActionBtn(
                child: ScaleTransition(
                  scale: _fireAnim,
                  child: Text(widget.fired ? '🔥' : '🤍',
                      style: const TextStyle(fontSize: 28)),
                ),
                label: '${card.fires + (widget.fired ? 1 : 0)}',
                onTap: _onFire,
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white, size: 28),
                label: '${card.comments}',
                onTap: () => _showComments(context, card),
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                child: const Icon(Icons.near_me_outlined, color: Colors.white, size: 28),
                label: 'Share', onTap: () {},
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 28),
                label: 'Add', onTap: () {},
              ),
              const SizedBox(height: 20),
              // Animated vinyl disc
              SizedBox(
                width: 48, height: 48,
                child: CustomPaint(
                  painter: _VinylPainter(
                    accentColor: _accent,
                    turns: widget.isActive ? _vinylCtrl.value : 0,
                    beat: beat,
                  ),
                ),
              ),
            ]),
          ),

          // ── Bottom-left user info ──
          Positioned(
            left: 16, right: 80, bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: card.gradient.first.withOpacity(0.8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(child: Text(card.avatarEmoji,
                        style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 8),
                  Text(card.username,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('+ sync',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${card.moodEmoji} ${card.mood}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _captionExpanded = !_captionExpanded),
                  child: Text(card.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 14,
                          height: 1.4, fontWeight: FontWeight.w500),
                      maxLines: _captionExpanded ? 5 : 2,
                      overflow: _captionExpanded
                          ? TextOverflow.visible : TextOverflow.ellipsis),
                ),
                const SizedBox(height: 10),
                // Song strip with animated EQ bars
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.isActive)
                      _EqBars(progress: _bgCtrl.value, beat: beat, accentColor: _accent)
                    else
                      Icon(Icons.music_note_rounded, color: _accent, size: 13),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('${card.song} · ${card.artist}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ]);
      },
    );
  }

  void _showComments(BuildContext context, PulseCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(card: card),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Layer 1 — rotating gradient + aurora streaks + vignette
class _GradientBgPainter extends CustomPainter {
  final List<Color> colors;
  final double progress;
  final double beat;

  const _GradientBgPainter({
    required this.colors, required this.progress, required this.beat,
  });

  Color _boost(Color c, double f) => Color.fromARGB(
    c.alpha,
    (c.red * f).clamp(0, 255).toInt(),
    (c.green * f).clamp(0, 255).toInt(),
    (c.blue * f).clamp(0, 255).toInt(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final angle = progress * 2 * math.pi;
    final pulse = 1.0 + beat * 0.09;
    final cx = size.width / 2;

    final grad = LinearGradient(
      begin: Alignment(math.cos(angle) * 0.8, math.sin(angle) * 0.6 - 0.4),
      end: Alignment(-math.cos(angle) * 0.8, -math.sin(angle) * 0.6 + 0.4),
      colors: [
        _boost(colors[0], pulse),
        colors.length > 1 ? colors[1] : colors[0],
        colors.length > 2 ? colors[2] : colors[0],
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad,
    );

    // Aurora horizontal shimmer bands
    for (int i = 0; i < 3; i++) {
      final sy = size.height * (0.26 + i * 0.15) +
          math.sin(progress * 2 * math.pi + i * 2.1) * 38;
      final bandH = 52.0;
      final aGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.032 + beat * 0.042 + i * 0.008),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, sy - bandH / 2, size.width, bandH));
      canvas.drawRect(
        Rect.fromLTWH(0, sy - bandH / 2, size.width, bandH),
        Paint()..shader = aGrad,
      );
    }

    // Radial shimmer on beat
    if (beat > 0.3) {
      final radGrad = RadialGradient(
        colors: [
          Colors.white.withOpacity((beat - 0.3) * 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, size.height * 0.45),
        radius: size.width * 0.6,
      ));
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = radGrad,
      );
    }

    // Vignette
    final vig = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.42)],
    ).createShader(Rect.fromCircle(
      center: Offset(cx, size.height / 2),
      radius: size.width * 0.85,
    ));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = vig,
    );
  }

  @override
  bool shouldRepaint(_GradientBgPainter o) => true;
}

/// Layer 2 — concentric rings + 64-bar radial freq + waveform + aura glow
class _VisualizerPainter extends CustomPainter {
  final double progress;
  final double beat;
  final Color accentColor;
  final bool isActive;

  const _VisualizerPainter({
    required this.progress, required this.beat,
    required this.accentColor, required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;
    final cx = size.width / 2;
    final cy = size.height * 0.46;
    final p = progress * 2 * math.pi;

    // 1. Concentric glow rings
    for (int i = 1; i <= 5; i++) {
      final r = 54.0 * i + math.sin(p + i * 0.8) * 10 + beat * 22 * (6 - i) * 0.14;
      canvas.drawCircle(Offset(cx, cy), r, Paint()
        ..color = Colors.white.withOpacity(0.028 * (6 - i) + beat * 0.018)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7 + beat * 0.55);
    }

    // 2. 64-bar radial frequency ring
    const N = 64;
    final accentPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8;
    for (int i = 0; i < N; i++) {
      final angle = (i / N) * math.pi * 2 - math.pi / 2;
      final noise = (math.sin(p * 1.5 + i * 0.42) * 0.4 +
              math.sin(p * 0.7 + i * 0.8) * 0.3 +
              beat * 0.3)
          .clamp(-1.0, 1.0);
      final nC = (noise * 0.5 + 0.5).clamp(0.0, 1.0);
      const r1 = 36.0;
      final r2 = r1 + (18.0 + beat * 30) * nC;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * r1, cy + math.sin(angle) * r1),
        Offset(cx + math.cos(angle) * r2, cy + math.sin(angle) * r2),
        accentPaint..color = accentColor.withOpacity(0.28 + nC * 0.48),
      );
    }

    // 3. Waveform strip
    final wy = size.height * 0.79;
    final wavePath = Path()..moveTo(0, wy);
    for (int x = 0; x <= size.width.toInt(); x++) {
      final xn = x / size.width;
      final y = wy
          + math.sin(xn * math.pi * 8 + p * 2) * 5 * beat
          + math.sin(xn * math.pi * 14 - p) * 3.5 * (0.3 + beat * 0.4)
          + math.sin(xn * math.pi * 4 + p * 0.6) * 7 * (0.2 + beat * 0.35);
      wavePath.lineTo(x.toDouble(), y);
    }
    canvas.drawPath(wavePath, Paint()
      ..color = accentColor.withOpacity(0.42 + beat * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // waveform fill
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [accentColor.withOpacity(0.1 + beat * 0.08), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, wy, size.width, size.height - wy)));

    // 4. Song aura glow behind info strip
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      Paint()..shader = RadialGradient(
        colors: [accentColor.withOpacity(0.17 + beat * 0.14), Colors.transparent],
        center: Alignment(-0.3, 0),
        radius: 0.9,
      ).createShader(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28)),
    );
  }

  @override
  bool shouldRepaint(_VisualizerPainter o) => true;
}

/// Layer 3 — particles, ripples, floating notes (self-repaints via ChangeNotifier)
class _ParticleRipplePainter extends CustomPainter {
  final _ParticleSystem system;

  _ParticleRipplePainter({required this.system}) : super(repaint: system);

  @override
  void paint(Canvas canvas, Size size) {
    // Ripples
    for (final r in system.ripples) {
      canvas.drawCircle(
        Offset(r.x, r.y), r.r,
        Paint()
          ..color = r.color.withOpacity(r.life * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * r.life,
      );
    }

    // Particles
    for (final p in system.particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        math.max(0.1, p.r * p.life),
        Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0) * 0.88),
      );
    }

    // Floating music notes (drawn as TextPainter)
    for (final n in system.notes) {
      final alpha = (math.min(n.life * 3, 1.0) * n.life * 0.8).clamp(0.0, 1.0);
      if (alpha < 0.02) continue;
      final tp = TextPainter(
        text: TextSpan(
          text: n.emoji,
          style: TextStyle(fontSize: 15 * n.scale,
              color: Colors.white.withOpacity(alpha)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(n.x - tp.width / 2, n.y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_ParticleRipplePainter o) => false;
}

/// Vinyl disc with grooves, colored label, highlight arc, beat halo
class _VinylPainter extends CustomPainter {
  final Color accentColor;
  final double turns; // 0→1
  final double beat;

  const _VinylPainter({
    required this.accentColor, required this.turns, required this.beat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(turns * math.pi * 2);

    // Disc body
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFF111111));

    // Groove rings
    for (int i = 1; i <= 4; i++) {
      final rg = r - i * r * 0.13;
      canvas.drawCircle(Offset.zero, rg, Paint()
        ..color = Colors.white.withOpacity(0.06 + beat * 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }

    // Center label
    canvas.drawCircle(Offset.zero, r * 0.4, Paint()..color = accentColor);

    // Center hole
    canvas.drawCircle(Offset.zero, r * 0.09,
        Paint()..color = const Color(0xFF1A1A1A));

    // Highlight arc (top-right)
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r - 1),
      -math.pi / 2, math.pi * 0.55, false,
      Paint()
        ..color = Colors.white.withOpacity(0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.restore();

    // Beat halo (stays fixed, doesn't rotate)
    if (beat > 0.25) {
      canvas.drawCircle(Offset(cx, cy), r + 2 + beat * 5, Paint()
        ..color = accentColor.withOpacity(beat * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(_VinylPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// EQ Bars (beat-reactive)
// ─────────────────────────────────────────────────────────────────────────────

class _EqBars extends StatelessWidget {
  final double progress;
  final double beat;
  final Color accentColor;

  const _EqBars({required this.progress, required this.beat, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    const base = [7.0, 4.0, 9.5, 5.0];
    return Row(
      children: List.generate(4, (i) {
        final h = (base[i]
            + math.sin(progress * 2 * math.pi * 3 + i * 1.3) * 4.5
            + beat * 5.5).clamp(2.0, 13.0);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 2.5, height: h,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Collective Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CollectiveOverlay extends StatelessWidget {
  final PulseCard card;
  const _CollectiveOverlay({required this.card});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 56,
            child: Stack(
              children: List.generate(math.min(card.others.length, 4), (i) =>
                Positioned(
                  left: i * 32.0,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(child: Text(card.others[i]['emoji']!,
                        style: const TextStyle(fontSize: 22))),
                  ),
                )),
            ),
          ),
          const SizedBox(height: 16),
          Text(card.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 16),
          ...card.others.take(3).map((o) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Text(o['emoji']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text('@${o['name']}',
                  style: const TextStyle(color: AuraTheme.accentLight,
                      fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('"${o['quote']}"',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Battle Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _BattleOverlay extends StatelessWidget {
  final PulseCard card;
  final int votesA, votesB;
  final int? myVote;
  final ValueChanged<int> onVote;

  const _BattleOverlay({
    required this.card, required this.votesA, required this.votesB,
    required this.myVote, required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final total = votesA + votesB;
    final pA = votesA / total;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🥊 BATTLE',
              style: TextStyle(color: AuraTheme.accent, fontWeight: FontWeight.w900,
                  fontSize: 13, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _battleCard(card.song, card.artist, 0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('VS',
                  style: TextStyle(color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w900, fontSize: 20)),
            ),
            Expanded(child: _battleCard(card.songB ?? '', card.artistB ?? '', 1)),
          ]),
          if (myVote != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(children: [
                Container(height: 28, color: Colors.white.withOpacity(0.15)),
                AnimatedFractionallySizedBox(
                  widthFactor: pA,
                  duration: const Duration(milliseconds: 600),
                  child: Container(height: 28, color: AuraTheme.accent),
                ),
                Row(children: [
                  Expanded(child: Center(child: Text('${(pA * 100).round()}%',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 12)))),
                  Expanded(child: Center(child: Text('${((1 - pA) * 100).round()}%',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 12)))),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _battleCard(String song, String artist, int side) {
    final picked = myVote == side;
    return GestureDetector(
      onTap: () => onVote(side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: picked ? AuraTheme.accent.withOpacity(0.85) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: picked ? AuraTheme.accent : Colors.white.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(side == 0 ? '🎵' : '🎶', style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(song, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 2),
          Text(artist, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.child, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      child,
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          )),
    ),
  );
}

class _ScrollHint extends StatefulWidget {
  const _ScrollHint();
  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0, end: 12)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _a.value),
      child: const Column(children: [
        Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 28),
        Text('swipe up', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Comments Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final PulseCard card;
  const _CommentsSheet({required this.card});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  final _comments = <(String, String, String)>[
    ('maya.k', '🎧', 'this song is living in my head rent free'),
    ('zara.w', '🌙', 'okay but WHY does this hit so hard'),
    ('dev.s', '🔥', 'i was just listening to this omg'),
    ('rina.p', '✨', 'the way this perfectly describes my week'),
    ('leo.k', '💜', 'adding this to every playlist immediately'),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text('${_comments.length} comments',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 16)),
        const Divider(color: Colors.white12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _comments.length,
            itemBuilder: (_, i) {
              final c = _comments[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 34, height: 34,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white12),
                      child: Center(child: Text(c.$2,
                          style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('@${c.$1}',
                        style: const TextStyle(color: AuraTheme.accent,
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(c.$3, style: const TextStyle(color: Colors.white,
                        fontSize: 13, height: 1.4)),
                  ])),
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                ]),
              );
            },
          ),
        ),
        Container(
          color: const Color(0xFF1A1A1A),
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AuraTheme.accent),
              child: Center(child: Text(
                OrbitState().displayName.isNotEmpty ? OrbitState().displayName[0] : 'Y',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 13),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true, fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  setState(() {
                    _comments.insert(0, (
                        OrbitState().username.replaceAll('@', ''), '😊', v.trim()));
                    _ctrl.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final v = _ctrl.text.trim();
                if (v.isEmpty) return;
                setState(() {
                  _comments.insert(0,
                      (OrbitState().username.replaceAll('@', ''), '😊', v));
                  _ctrl.clear();
                });
              },
              child: Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                    color: AuraTheme.accent, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
