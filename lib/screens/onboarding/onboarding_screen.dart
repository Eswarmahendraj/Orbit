import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Genre data
// ─────────────────────────────────────────────────────────────────────────────

const _genres = [
  ('Hip-Hop', '🎤', Color(0xFFFC466B)),
  ('R&B', '🌙', Color(0xFF7C3AED)),
  ('Pop', '✨', Color(0xFFFF6B35)),
  ('Indie', '🌿', Color(0xFF43E97B)),
  ('Electronic', '⚡', Color(0xFF4FACFE)),
  ('Jazz', '🎺', Color(0xFFF7971E)),
  ('Alt / Rock', '🎸', Color(0xFFFF0080)),
  ('Metal', '🤘', Color(0xFF888888)),
  ('Folk', '🪕', Color(0xFF81C784)),
  ('Latin', '💃', Color(0xFFFF6B35)),
  ('K-Pop', '💜', Color(0xFFE040FB)),
  ('Classical', '🎻', Color(0xFF64B5F6)),
  ('Afrobeats', '🌍', Color(0xFFFFA000)),
  ('Country', '🤠', Color(0xFFBCAAA4)),
  ('Soul', '🔥', Color(0xFFFF8A65)),
  ('Lo-Fi', '📻', Color(0xFF80CBC4)),
  ('Dance', '🕺', Color(0xFFEC407A)),
  ('Punk', '🖤', Color(0xFF757575)),
];

const _moods = [
  ('chill', '☀️', Color(0xFFF7971E)),
  ('hype', '🔥', Color(0xFFFC466B)),
  ('cozy', '🫶', Color(0xFFE96C9D)),
  ('2am', '🌙', Color(0xFF4FACFE)),
  ('focused', '🎧', Color(0xFF7C3AED)),
  ('heartbreak', '💔', Color(0xFFFC466B)),
  ('euphoric', '✨', Color(0xFF43E97B)),
  ('nostalgia', '🎞️', Color(0xFFF7971E)),
];

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pages = PageController();
  int _step = 0;
  static const _totalSteps = 4;

  // Controllers
  late final AnimationController _bgCtrl;
  late final AnimationController _introCtrl;

  // Form fields
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  File? _pfp;

  // Selections
  final Set<String> _selectedGenres = {};
  String _mood     = 'chill';
  String _moodEmoji = '☀️';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 12))..repeat();
    _introCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _introCtrl.dispose();
    _pages.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _pages.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic);
      setState(() => _step++);
      HapticFeedback.selectionClick();
    } else {
      _finish();
    }
  }

  Future<void> _pickPhoto() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _pfp = File(f.path));
  }

  void _finish() {
    final state = OrbitState();
    final name = _nameCtrl.text.trim();
    state.displayName = name.isEmpty ? 'You' : name;
    final raw = _usernameCtrl.text.trim();
    state.username = raw.isEmpty
        ? '@you'
        : (raw.startsWith('@') ? raw : '@$raw');
    if (_pfp != null) state.pfpFile = _pfp;
    state.mood      = _mood;
    state.moodEmoji = _moodEmoji;
    state.hasOnboarded = true;
    state.save();
    HapticFeedback.heavyImpact();
    widget.onDone();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0: return true;
      case 1: return _selectedGenres.length >= 3;
      case 2: return _nameCtrl.text.trim().isNotEmpty;
      case 3: return true;
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: Stack(children: [
        // ── Particle galaxy background ──────────────────────────────────
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) => CustomPaint(
            painter: _GalaxyPainter(progress: _bgCtrl.value),
            size: MediaQuery.of(context).size,
          ),
        ),

        // ── Page content ────────────────────────────────────────────────
        SafeArea(
          child: Column(children: [
            // Step dots
            if (_step > 0) ...[
              const SizedBox(height: 16),
              _StepDots(current: _step - 1, total: _totalSteps - 1),
            ],
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IntroPage(ctrl: _introCtrl, onStart: _next),
                  _GenrePage(
                    selected: _selectedGenres,
                    onToggle: (g) => setState(() {
                      if (_selectedGenres.contains(g)) _selectedGenres.remove(g);
                      else _selectedGenres.add(g);
                    }),
                    onNext: _canAdvance ? _next : null,
                  ),
                  _ProfilePage(
                    nameCtrl: _nameCtrl,
                    usernameCtrl: _usernameCtrl,
                    pfp: _pfp,
                    onPickPhoto: _pickPhoto,
                    onNext: _canAdvance ? _next : null,
                    onNameChanged: () => setState(() {}),
                  ),
                  _MoodPage(
                    selected: _mood,
                    onSelect: (m, e) => setState(() { _mood = m; _moodEmoji = e; }),
                    onDone: _finish,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step dots
// ─────────────────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int current, total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: current == i ? 24 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: current == i
              ? AuraTheme.accent
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 0 — Cinematic intro
// ─────────────────────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  final AnimationController ctrl;
  final VoidCallback onStart;
  const _IntroPage({required this.ctrl, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    final slide = CurvedAnimation(parent: ctrl, curve: const Interval(0.2, 0.9, curve: Curves.easeOut));
    final btnFade = CurvedAnimation(parent: ctrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut));

    return FadeTransition(
      opacity: fade,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Logo
            SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(slide),
              child: Column(children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AuraTheme.accent.withOpacity(0.6), width: 2),
                    color: AuraTheme.accent.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(color: AuraTheme.accent.withOpacity(0.4),
                          blurRadius: 30, spreadRadius: 4),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌌',
                        style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('Orbit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1)),
                const SizedBox(height: 10),
                Text(
                  'your music. your orbit.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 16,
                      letterSpacing: 0.5),
                ),
              ]),
            ),
            const Spacer(flex: 3),
            FadeTransition(
              opacity: btnFade,
              child: Column(children: [
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AuraTheme.accent, AuraTheme.purple],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: AuraTheme.accent.withOpacity(0.4),
                        blurRadius: 24, offset: const Offset(0, 6),
                      )],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Enter Orbit',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3)),
                        SizedBox(width: 8),
                        Text('→', style: TextStyle(color: Colors.white, fontSize: 17)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('the music social app for gen z',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 12,
                        letterSpacing: 0.5)),
              ]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Genre fingerprint quiz
// ─────────────────────────────────────────────────────────────────────────────

class _GenrePage extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback? onNext;
  const _GenrePage({required this.selected, required this.onToggle, this.onNext});

  @override
  Widget build(BuildContext context) {
    final enough = selected.length >= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('🎵', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        const Text('Your genre\nfingerprint',
            style: TextStyle(color: Colors.white,
                fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 6),
        Text('Pick at least 3 genres you vibe with',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 14)),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _genres.map((g) {
                final sel = selected.contains(g.$1);
                return GestureDetector(
                  onTap: () => onToggle(g.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? g.$3.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: sel ? g.$3.withOpacity(0.7) : Colors.white.withOpacity(0.1),
                        width: sel ? 1.5 : 1,
                      ),
                      boxShadow: sel ? [BoxShadow(
                        color: g.$3.withOpacity(0.25),
                        blurRadius: 8,
                      )] : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(g.$2, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(g.$1,
                          style: TextStyle(
                              color: sel ? g.$3 : Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Counter
        Row(children: [
          Text(
            '${selected.length} selected',
            style: TextStyle(
                color: enough ? AuraTheme.accent : Colors.white.withOpacity(0.3),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          if (!enough)
            Text(' — pick ${3 - selected.length} more',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.25), fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        _PrimaryBtn(
          label: 'Continue →',
          enabled: enough,
          onTap: onNext,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Profile setup
// ─────────────────────────────────────────────────────────────────────────────

class _ProfilePage extends StatelessWidget {
  final TextEditingController nameCtrl, usernameCtrl;
  final File? pfp;
  final VoidCallback onPickPhoto;
  final VoidCallback? onNext;
  final VoidCallback onNameChanged;

  const _ProfilePage({
    required this.nameCtrl, required this.usernameCtrl,
    required this.pfp, required this.onPickPhoto,
    this.onNext, required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const Text('👤', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        const Text('Set up your\nidentity',
            style: TextStyle(color: Colors.white,
                fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 6),
        Text('How should your orbit know you?',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 14)),
        const SizedBox(height: 28),

        // Avatar picker
        Center(
          child: GestureDetector(
            onTap: onPickPhoto,
            child: Stack(children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraTheme.accent.withOpacity(0.1),
                  border: Border.all(
                      color: AuraTheme.accent.withOpacity(0.5), width: 2),
                  boxShadow: [BoxShadow(
                    color: AuraTheme.accent.withOpacity(0.2),
                    blurRadius: 16,
                  )],
                  image: pfp != null
                      ? DecorationImage(image: FileImage(pfp!), fit: BoxFit.cover)
                      : null,
                ),
                child: pfp == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: AuraTheme.accent, size: 28),
                          SizedBox(height: 4),
                          Text('photo',
                              style: TextStyle(
                                  color: AuraTheme.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : null,
              ),
              if (pfp != null)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraTheme.accent,
                      border: Border.all(color: const Color(0xFF07070F), width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 13),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 28),

        _OnboardField(controller: nameCtrl, label: 'Display name',
            hint: 'e.g. Eswar', onChanged: (_) => onNameChanged()),
        const SizedBox(height: 14),
        _OnboardField(controller: usernameCtrl, label: 'Username',
            hint: 'e.g. eswar.m'),
        const SizedBox(height: 32),

        _PrimaryBtn(
          label: 'Continue →',
          enabled: nameCtrl.text.trim().isNotEmpty,
          onTap: onNext,
        ),
        const SizedBox(height: 12),
        // Skip photo if not taken
        if (pfp == null)
          Center(
            child: GestureDetector(
              onTap: onPickPhoto,
              child: Text('+ add a profile photo',
                  style: TextStyle(
                      color: AuraTheme.accent.withOpacity(0.6), fontSize: 12)),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Mood / vibe picker
// ─────────────────────────────────────────────────────────────────────────────

class _MoodPage extends StatelessWidget {
  final String selected;
  final void Function(String mood, String emoji) onSelect;
  final VoidCallback onDone;
  const _MoodPage({required this.selected, required this.onSelect, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Text(_moods.firstWhere((m) => m.$1 == selected).$2,
            style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text("What's your\ndefault vibe?",
            style: TextStyle(color: Colors.white,
                fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 6),
        Text('Sets the tone for your Orbit profile',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 14)),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: _moods.map((m) {
              final sel = selected == m.$1;
              return GestureDetector(
                onTap: () { onSelect(m.$1, m.$2); HapticFeedback.selectionClick(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? m.$3.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel ? m.$3.withOpacity(0.7) : Colors.white.withOpacity(0.08),
                      width: sel ? 1.5 : 1,
                    ),
                    boxShadow: sel ? [BoxShadow(
                      color: m.$3.withOpacity(0.25), blurRadius: 12,
                    )] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.$2, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(m.$1,
                          style: TextStyle(
                            color: sel ? m.$3 : Colors.white.withOpacity(0.6),
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onDone,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AuraTheme.accent, AuraTheme.purple],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: AuraTheme.accent.withOpacity(0.4),
                blurRadius: 24, offset: const Offset(0, 6),
              )],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🚀', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Text('Enter Orbit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: [AuraTheme.accent, AuraTheme.purple])
              : null,
          color: enabled ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled ? [BoxShadow(
            color: AuraTheme.accent.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 5),
          )] : null,
        ),
        child: Center(child: Text(
          label,
          style: TextStyle(
              color: enabled ? Colors.white : Colors.white30,
              fontSize: 16,
              fontWeight: FontWeight.w900),
        )),
      ),
    );
  }
}

class _OnboardField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final ValueChanged<String>? onChanged;
  const _OnboardField({required this.controller, required this.label,
      required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              color: AuraTheme.accent.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2), fontSize: 14),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AuraTheme.accent.withOpacity(0.6), width: 1.5),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Galaxy background painter
// ─────────────────────────────────────────────────────────────────────────────

class _GalaxyPainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);

  static final _stars = List.generate(80, (i) => [
    _rng.nextDouble(), // x fraction
    _rng.nextDouble(), // y fraction
    _rng.nextDouble() * 1.8 + 0.4, // radius
    _rng.nextDouble(), // phase
  ]);

  static final _orbs = List.generate(6, (i) => [
    0.3 + _rng.nextDouble() * 0.4,           // orbit r fraction
    _rng.nextDouble() * 2 * math.pi,          // phase
    _rng.nextDouble() * 0.4 + 0.6,            // speed factor
    _rng.nextDouble(),                         // color index
  ]);

  static const _orbColors = [
    Color(0xFF7C3AED),
    Color(0xFF4FACFE),
    Color(0xFFFC466B),
    Color(0xFF43E97B),
    Color(0xFFF7971E),
    Color(0xFFFF0080),
  ];

  const _GalaxyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.48;

    // Stars
    for (final s in _stars) {
      final twinkle = 0.4 + 0.6 * math.sin(progress * 2 * math.pi * 1.3 + s[3] * 6);
      canvas.drawCircle(
        Offset(s[0] * size.width, s[1] * size.height),
        s[2],
        Paint()..color = Colors.white.withOpacity(twinkle * 0.7),
      );
    }

    // Faint orbit rings
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.28 * i,
        Paint()
          ..color = Colors.white.withOpacity(0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Orbiting color dots
    for (int i = 0; i < _orbs.length; i++) {
      final o = _orbs[i];
      final angle = progress * 2 * math.pi * o[2] + o[1];
      final r = size.width * (o[0] * 0.42);
      final dx = cx + r * math.cos(angle);
      final dy = cy + r * math.sin(angle);
      final col = _orbColors[(o[3] * _orbColors.length).floor() % _orbColors.length];
      // Glow
      canvas.drawCircle(Offset(dx, dy), 6,
          Paint()..color = col.withOpacity(0.15)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(Offset(dx, dy), 2.5,
          Paint()..color = col.withOpacity(0.7));
    }

    // Central nebula glow
    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.5));
    canvas.drawCircle(Offset(cx, cy), size.width * 0.5, nebula);
  }

  @override
  bool shouldRepaint(_GalaxyPainter old) => old.progress != progress;
}
