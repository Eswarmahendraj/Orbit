import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SnapFilter model
// ─────────────────────────────────────────────────────────────────────────────

class SnapFilter {
  final String id;
  final String name;   // gen z name
  final String emoji;
  final List<Color> chipColors;
  final List<double> matrix; // 4×5 ColorFilter.matrix (20 values)

  const SnapFilter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.chipColors,
    required this.matrix,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// The 10 filters
// ─────────────────────────────────────────────────────────────────────────────

const kSnapFilters = <SnapFilter>[

  // 1 ── glitchcore ⚡
  SnapFilter(
    id: 'glitchcore', name: 'glitchcore', emoji: '⚡',
    chipColors: [Color(0xFFFF0040), Color(0xFF00FFFF)],
    matrix: [
      1.65, 0.15, -0.15, 0, 12,
      0.00, 1.40,  0.00, 0, -12,
      -0.10, 0.00, 1.55, 0, 0,
      0, 0, 0, 1, 0,
    ],
  ),

  // 2 ── npc mode 🎮
  SnapFilter(
    id: 'npc_mode', name: 'npc mode', emoji: '🎮',
    chipColors: [Color(0xFF00FF88), Color(0xFF003388)],
    matrix: [
      0.30, 0.50, 0.20, 0, 0,
      0.28, 0.46, 0.20, 0, 0,
      0.28, 0.44, 0.22, 0, 30,
      0, 0, 0, 1, 0,
    ],
  ),

  // 3 ── y2k drip 🪩
  SnapFilter(
    id: 'y2k_drip', name: 'y2k drip', emoji: '🪩',
    chipColors: [Color(0xFFFFCC00), Color(0xFFFF44AA)],
    matrix: [
      1.50, 0.10, 0.00, 0, 16,
      0.05, 1.25, 0.05, 0,  6,
      0.00, 0.00, 1.05, 0, -14,
      0, 0, 0, 1, 0,
    ],
  ),

  // 4 ── main character 🎬
  SnapFilter(
    id: 'main_character', name: 'main character', emoji: '🎬',
    chipColors: [Color(0xFFD4A94E), Color(0xFF3D2B00)],
    matrix: [
      1.25, 0.10, -0.05, 0, 14,
      0.00, 1.05, -0.05, 0,  7,
      -0.08, -0.05, 0.85, 0, -8,
      0, 0, 0, 1, 0,
    ],
  ),

  // 5 ── it's giving 🌈
  SnapFilter(
    id: 'its_giving', name: "it's giving", emoji: '🌈',
    chipColors: [Color(0xFFFF0099), Color(0xFF00AAFF)],
    matrix: [
      0.82, 0.12, 0.06, 0, 6,
      0.06, 0.82, 0.12, 0, 6,
      0.12, 0.06, 0.82, 0, 6,
      0, 0, 0, 1, 0,
    ],
  ),

  // 6 ── understood 🖤
  SnapFilter(
    id: 'understood', name: 'understood', emoji: '🖤',
    chipColors: [Color(0xFF333333), Color(0xFFAAAAAA)],
    matrix: [
      0.33, 0.59, 0.11, 0, -38,
      0.33, 0.59, 0.11, 0, -38,
      0.33, 0.59, 0.11, 0, -38,
      0, 0, 0, 1, 0,
    ],
  ),

  // 7 ── slay ray 💜
  SnapFilter(
    id: 'slay_ray', name: 'slay ray', emoji: '💜',
    chipColors: [Color(0xFF9B59FF), Color(0xFFFF77FF)],
    matrix: [
      0.85, 0.00, 0.25, 0,  6,
      0.00, 0.78, 0.22, 0,  0,
      0.12, 0.04, 1.38, 0, 12,
      0, 0, 0, 1, 0,
    ],
  ),

  // 8 ── rent free 🌸
  SnapFilter(
    id: 'rent_free', name: 'rent free', emoji: '🌸',
    chipColors: [Color(0xFFFFAACC), Color(0xFFFF6688)],
    matrix: [
      1.28, 0.08, 0.10, 0, 18,
      0.10, 0.92, 0.08, 0, 12,
      0.08, 0.00, 0.74, 0,  8,
      0, 0, 0, 1, 0,
    ],
  ),

  // 9 ── no cap 📼
  SnapFilter(
    id: 'no_cap', name: 'no cap', emoji: '📼',
    chipColors: [Color(0xFF44FF88), Color(0xFF002211)],
    matrix: [
      0.78, 0.18, 0.04, 0,  8,
      0.08, 0.86, 0.12, 0, 12,
      0.04, 0.22, 0.82, 0,  3,
      0, 0, 0, 1, 0,
    ],
  ),

  // 10 ── delulu 🌙
  SnapFilter(
    id: 'delulu', name: 'delulu', emoji: '🌙',
    chipColors: [Color(0xFF0A0025), Color(0xFF6644CC)],
    matrix: [
      0.52, 0.00, 0.22, 0, -26,
      0.00, 0.62, 0.26, 0, -14,
      0.06, 0.06, 1.32, 0,  8,
      0, 0, 0, 1, 0,
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SnapFilterOverlay — self-animating overlay widget for a given filter
// ─────────────────────────────────────────────────────────────────────────────

class SnapFilterOverlay extends StatefulWidget {
  final String filterId;
  const SnapFilterOverlay({super.key, required this.filterId});

  @override
  State<SnapFilterOverlay> createState() => _SnapFilterOverlayState();
}

class _SnapFilterOverlayState extends State<SnapFilterOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static Duration _durationFor(String id) {
    switch (id) {
      case 'glitchcore':    return const Duration(milliseconds: 280);
      case 'npc_mode':      return const Duration(milliseconds: 1600);
      case 'y2k_drip':      return const Duration(milliseconds: 2200);
      case 'main_character':return const Duration(seconds: 7);
      case 'its_giving':    return const Duration(milliseconds: 2800);
      case 'understood':    return const Duration(seconds: 9);
      case 'slay_ray':      return const Duration(milliseconds: 1800);
      case 'rent_free':     return const Duration(milliseconds: 2400);
      case 'no_cap':        return const Duration(milliseconds: 900);
      case 'delulu':        return const Duration(seconds: 5);
      default:              return const Duration(seconds: 2);
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _durationFor(widget.filterId),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _painterFor(widget.filterId, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }

  static CustomPainter _painterFor(String id, double t) {
    switch (id) {
      case 'glitchcore':     return _GlitchcorePainter(t);
      case 'npc_mode':       return _NpcModePainter(t);
      case 'y2k_drip':       return _Y2kDripPainter(t);
      case 'main_character': return _MainCharacterPainter(t);
      case 'its_giving':     return _ItsGivingPainter(t);
      case 'understood':     return _UnderstoodPainter(t);
      case 'slay_ray':       return _SlayRayPainter(t);
      case 'rent_free':      return _RentFreePainter(t);
      case 'no_cap':         return _NoCapPainter(t);
      case 'delulu':         return _DeluluPainter(t);
      default:               return _EmptyPainter();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

void _drawText(Canvas c, String text, Offset pos,
    {Color color = Colors.white,
    double fontSize = 11,
    FontWeight weight = FontWeight.w700,
    String? family}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: family ?? 'monospace',
          letterSpacing: 0.5),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, pos);
}

Path _starPath(Offset center, double outerR, double innerR, int points) {
  final path = Path();
  for (int i = 0; i < points * 2; i++) {
    final angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
    final r = i.isEven ? outerR : innerR;
    final p = Offset(center.dx + math.cos(angle) * r,
                     center.dy + math.sin(angle) * r);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

void _drawStar(Canvas c, Offset pos, double r, Color color, {double opacity = 1}) {
  c.drawPath(
    _starPath(pos, r, r * 0.42, 4),
    Paint()..color = color.withOpacity(opacity),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. GLITCHCORE ⚡
// RGB chromatic aberration + scanlines + digital blocks + neon fringe
// ─────────────────────────────────────────────────────────────────────────────

class _GlitchcorePainter extends CustomPainter {
  final double t;
  _GlitchcorePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42 + (t * 500).toInt());

    // Scanlines
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          Paint()..color = Colors.black.withOpacity(0.14));
    }

    // Left red fringe / right cyan fringe
    final lGrad = LinearGradient(colors: [
      Colors.red.withOpacity(0.35),
      Colors.transparent,
    ]).createShader(Rect.fromLTWH(0, 0, 20, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, 20, size.height), Paint()..shader = lGrad);

    final rGrad = LinearGradient(colors: [
      Colors.transparent,
      const Color(0xFF00FFFF).withOpacity(0.3),
    ]).createShader(Rect.fromLTWH(size.width - 20, 0, 20, size.height));
    canvas.drawRect(Rect.fromLTWH(size.width - 20, 0, 20, size.height), Paint()..shader = rGrad);

    // Digital glitch blocks (flicker based on t)
    final numBlocks = math.sin(t * math.pi * 4).abs() > 0.4 ? 4 : 1;
    for (int i = 0; i < numBlocks; i++) {
      final y = rng.nextDouble() * size.height;
      final h = rng.nextDouble() * 18 + 4;
      final shift = (rng.nextDouble() - 0.5) * 36;
      final colors = [
        Colors.red.withOpacity(0.18),
        const Color(0xFF00FFFF).withOpacity(0.15),
        Colors.white.withOpacity(0.09),
      ];
      canvas.drawRect(
        Rect.fromLTWH(shift, y, size.width, h),
        Paint()..color = colors[i % colors.length],
      );
    }

    // Pixel noise burst
    final noiseCount = math.sin(t * math.pi * 10).abs() > 0.6 ? 60 : 12;
    for (int i = 0; i < noiseCount; i++) {
      final px = rng.nextDouble() * size.width;
      final py = rng.nextDouble() * size.height;
      final ps = rng.nextDouble() * 3.5 + 1;
      final noiseColors = [Colors.red, const Color(0xFF00FFFF), Colors.white, Colors.yellow];
      canvas.drawRect(
        Rect.fromLTWH(px, py, ps, ps),
        Paint()..color = noiseColors[rng.nextInt(noiseColors.length)].withOpacity(0.55 + rng.nextDouble() * 0.35),
      );
    }

    // "ERROR" watermark that flickers
    if (math.sin(t * math.pi * 6) > 0.7) {
      _drawText(canvas, '// SIGNAL_CORRUPTED',
          Offset(14, size.height - 40),
          color: Colors.red.withOpacity(0.8), fontSize: 10);
    }
  }

  @override
  bool shouldRepaint(_GlitchcorePainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. NPC MODE 🎮
// Full game HUD: HP bar, XP bar, targeting reticle, quest text, mini-map
// ─────────────────────────────────────────────────────────────────────────────

class _NpcModePainter extends CustomPainter {
  final double t;
  _NpcModePainter(this.t);

  static const _green = Color(0xFF00FF88);
  static const _ui = Color(0xFF00CCFF);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── HP bar (top-left) ──
    _drawBar(canvas, const Offset(14, 52), 130, 10, 1.0, _green, 'HP  100 / 100');

    // ── Stamina bar (top-left, below HP) ──
    _drawBar(canvas, const Offset(14, 70), 90, 6, 0.72, const Color(0xFFFFDD00), 'STAMINA');

    // ── Mana bar ──
    _drawBar(canvas, const Offset(14, 82), 70, 6, 0.55, _ui, 'MANA');

    // ── Player tag ──
    _drawText(canvas, '▶  @YOU  LVL 7',
        const Offset(14, 38), color: _green, fontSize: 10);

    // ── Quest text ──
    _drawText(canvas, '📍 QUEST: post a snap to your orbit',
        Offset(14, size.height * 0.12), color: const Color(0xFFFFDD00), fontSize: 9);

    // ── Targeting reticle (center, rotating) ──
    _drawReticle(canvas, Offset(cx, cy), t);

    // ── XP bar (bottom) ──
    final xpY = size.height - 38.0;
    _drawBar(canvas, Offset(14, xpY), size.width - 100, 8, 0.62, _ui, null);
    _drawText(canvas, 'XP  6,200 / 10,000',
        Offset(16, xpY - 14), color: _ui, fontSize: 9);

    // ── Mini-map circle (bottom-right) ──
    _drawMiniMap(canvas, Offset(size.width - 50, size.height - 55));

    // ── Compass (top-right) ──
    _drawCompass(canvas, Offset(size.width - 28, 52));

    // ── Corner brackets ──
    _drawBrackets(canvas, size);
  }

  void _drawBar(Canvas c, Offset pos, double w, double h,
      double fill, Color color, String? label) {
    // Track
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, w, h), const Radius.circular(3)),
      Paint()..color = Colors.black.withOpacity(0.55));
    // Fill
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, w * fill, h), const Radius.circular(3)),
      Paint()..color = color.withOpacity(0.9));
    // Border
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(pos.dx, pos.dy, w, h), const Radius.circular(3)),
      Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    if (label != null) {
      _drawText(c, label, Offset(pos.dx, pos.dy + h + 1),
          color: color, fontSize: 8);
    }
  }

  void _drawReticle(Canvas c, Offset center, double t) {
    final paint = Paint()
      ..color = _green.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = 28.0 + math.sin(t * math.pi * 2) * 3;

    // Outer circle
    c.drawCircle(center, r, paint..color = _green.withOpacity(0.4));

    // Rotating tick marks (4 cardinal + 4 diagonal, outer ring rotates)
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(t * math.pi * 2);
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final r1 = i.isEven ? r + 5 : r + 3;
      c.drawLine(
        Offset(math.cos(angle) * r, math.sin(angle) * r),
        Offset(math.cos(angle) * r1, math.sin(angle) * r1),
        paint..color = _green.withOpacity(i.isEven ? 0.9 : 0.5),
      );
    }
    c.restore();

    // Cross-hair (static)
    const arm = 10.0;
    c.drawLine(Offset(center.dx - arm, center.dy),
        Offset(center.dx - 4, center.dy), paint..color = _green.withOpacity(0.8));
    c.drawLine(Offset(center.dx + 4, center.dy),
        Offset(center.dx + arm, center.dy), paint..color = _green.withOpacity(0.8));
    c.drawLine(Offset(center.dx, center.dy - arm),
        Offset(center.dx, center.dy - 4), paint..color = _green.withOpacity(0.8));
    c.drawLine(Offset(center.dx, center.dy + 4),
        Offset(center.dx, center.dy + arm), paint..color = _green.withOpacity(0.8));

    // Center dot
    c.drawCircle(center, 2, Paint()..color = _green);

    // LOCK text on beat
    if (math.sin(t * math.pi * 4) > 0.5) {
      _drawText(c, 'LOCK', Offset(center.dx + r + 6, center.dy - 5),
          color: _green.withOpacity(0.8), fontSize: 9);
    }
  }

  void _drawMiniMap(Canvas c, Offset center) {
    const r = 30.0;
    // Background
    c.drawCircle(center, r, Paint()..color = Colors.black.withOpacity(0.5));
    c.drawCircle(center, r, Paint()
      ..color = _ui.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    // Grid lines
    c.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy),
        Paint()..color = _ui.withOpacity(0.15)..strokeWidth = 0.5);
    c.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r),
        Paint()..color = _ui.withOpacity(0.15)..strokeWidth = 0.5);
    // Player blip
    c.drawCircle(center, 3, Paint()..color = _green);
    // Random enemy blips
    c.drawCircle(Offset(center.dx + 10, center.dy - 12), 2,
        Paint()..color = Colors.red.withOpacity(0.8));
    c.drawCircle(Offset(center.dx - 8, center.dy + 6), 2,
        Paint()..color = Colors.red.withOpacity(0.8));
    _drawText(c, 'MAP', Offset(center.dx - 10, center.dy + r + 3),
        color: _ui.withOpacity(0.6), fontSize: 8);
  }

  void _drawCompass(Canvas c, Offset center) {
    c.drawCircle(center, 14, Paint()..color = Colors.black.withOpacity(0.4));
    c.drawCircle(center, 14, Paint()
      ..color = _ui.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    _drawText(c, 'N', Offset(center.dx - 4, center.dy - 12),
        color: Colors.red.withOpacity(0.9), fontSize: 9);
    _drawText(c, 'S', Offset(center.dx - 3, center.dy + 4),
        color: _ui.withOpacity(0.7), fontSize: 8);
  }

  void _drawBrackets(Canvas c, Size size) {
    final paint = Paint()
      ..color = _green.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const arm = 18.0, pad = 8.0;
    // Top-left
    c.drawLine(Offset(pad, pad + arm), Offset(pad, pad), paint);
    c.drawLine(Offset(pad, pad), Offset(pad + arm, pad), paint);
    // Top-right
    c.drawLine(Offset(size.width - pad, pad + arm), Offset(size.width - pad, pad), paint);
    c.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - arm, pad), paint);
    // Bottom-left
    c.drawLine(Offset(pad, size.height - pad - arm), Offset(pad, size.height - pad), paint);
    c.drawLine(Offset(pad, size.height - pad), Offset(pad + arm, size.height - pad), paint);
    // Bottom-right
    c.drawLine(Offset(size.width - pad, size.height - pad - arm),
        Offset(size.width - pad, size.height - pad), paint);
    c.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - arm, size.height - pad), paint);
  }

  @override
  bool shouldRepaint(_NpcModePainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Y2K DRIP 🪩
// Chrome lens flares, holographic stars, metallic Y2K badge, sparkle dust
// ─────────────────────────────────────────────────────────────────────────────

class _Y2kDripPainter extends CustomPainter {
  final double t;
  _Y2kDripPainter(this.t);

  static const _gold = Color(0xFFFFCC00);
  static const _pink = Color(0xFFFF44AA);
  static const _silver = Color(0xFFDDEEFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);

    // Chrome lens flare stars at corners + random spots
    final flarePositions = [
      Offset(size.width * 0.1, size.height * 0.12),
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.15, size.height * 0.78),
      Offset(size.width * 0.5, size.height * 0.22),
    ];
    for (int i = 0; i < flarePositions.length; i++) {
      final pos = flarePositions[i];
      final pulse = 0.7 + math.sin(t * math.pi * 2 + i * 1.2) * 0.3;
      _drawLensFlare(canvas, pos, 14 * pulse + i * 3,
          [_gold, _pink, _silver, _gold, _pink][i], pulse);
    }

    // Scattered sparkle dust
    for (int i = 0; i < 30; i++) {
      final px = rng.nextDouble() * size.width;
      final py = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 4 + 1.5;
      final pulse = math.sin(t * math.pi * 2 + i * 0.7) * 0.5 + 0.5;
      final spColors = [_gold, _pink, _silver];
      _drawStar(canvas, Offset(px, py), r * pulse,
          spColors[i % spColors.length], opacity: 0.4 + pulse * 0.5);
    }

    // Y2K badge (top-center)
    _drawY2kBadge(canvas, Offset(size.width / 2, 48), t);

    // Bottom holographic sheen
    final sheen = LinearGradient(
      colors: [
        Colors.transparent,
        _pink.withOpacity(0.06 + math.sin(t * math.pi * 2) * 0.04),
        _gold.withOpacity(0.05),
        _silver.withOpacity(0.04),
        Colors.transparent,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0, 0.3, 0.5, 0.7, 1],
    ).createShader(Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
      Paint()..shader = sheen,
    );
  }

  void _drawLensFlare(Canvas c, Offset pos, double r, Color color, double opacity) {
    // 4-point star cross
    for (int arm = 0; arm < 4; arm++) {
      final angle = arm * math.pi / 2;
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ]).createShader(Rect.fromCircle(center: pos, radius: r * 2));
      c.drawLine(
        pos,
        Offset(pos.dx + math.cos(angle) * r * 2.5,
               pos.dy + math.sin(angle) * r * 2.5),
        paint..strokeWidth = r * 0.4..style = PaintingStyle.stroke,
      );
    }
    // Center circle
    c.drawCircle(pos, r * 0.4, Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
  }

  void _drawY2kBadge(Canvas c, Offset center, double t) {
    // Shimmer background pill
    final shimmerX = (t * 160).toDouble();
    final bg = LinearGradient(
      colors: [_gold, _pink, _silver, _gold],
      stops: const [0, 0.3, 0.6, 1],
      transform: GradientRotation(t * math.pi * 2),
    ).createShader(Rect.fromCenter(center: center, width: 110, height: 30));
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 110, height: 30),
          const Radius.circular(15)),
      Paint()..shader = bg,
    );
    _drawText(c, '✦  Y2K DRIP  ✦',
        Offset(center.dx - 50, center.dy - 8),
        color: Colors.black, fontSize: 11, weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(_Y2kDripPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. MAIN CHARACTER 🎬
// Cinematic letterbox, film grain, REC dot, golden sun ray
// ─────────────────────────────────────────────────────────────────────────────

class _MainCharacterPainter extends CustomPainter {
  final double t;
  _MainCharacterPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const barH = 62.0;

    // Cinematic letterbox bars
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, barH),
        Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(0, size.height - barH, size.width, barH),
        Paint()..color = Colors.black);

    // Sun ray (golden hour diagonal from top-right)
    final rayGrad = RadialGradient(
      center: const Alignment(0.8, -0.8),
      radius: 1.2,
      colors: [
        const Color(0xFFFFDD88).withOpacity(0.18 + math.sin(t * math.pi * 2) * 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, barH, size.width, size.height - barH * 2),
        Paint()..shader = rayGrad);

    // Film grain
    final rng = math.Random(77 + (t * 120).toInt());
    for (int i = 0; i < 220; i++) {
      final gx = rng.nextDouble() * size.width;
      final gy = barH + rng.nextDouble() * (size.height - barH * 2);
      final gs = rng.nextDouble() * 1.4 + 0.4;
      canvas.drawCircle(Offset(gx, gy), gs,
          Paint()..color = Colors.white.withOpacity(0.04 + rng.nextDouble() * 0.06));
    }

    // Aspect-ratio guide lines (subtle)
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width * 0.08, midY),
        Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 0.5);
    canvas.drawLine(Offset(size.width * 0.92, midY), Offset(size.width, midY),
        Paint()..color = Colors.white.withOpacity(0.08)..strokeWidth = 0.5);

    // REC indicator (inside top bar)
    final recBlink = math.sin(t * math.pi * 1.5) > 0;
    if (recBlink) {
      canvas.drawCircle(const Offset(20, 31), 5, Paint()..color = Colors.red);
    }
    _drawText(canvas, recBlink ? '● REC' : '○ REC', const Offset(30, 25),
        color: Colors.white.withOpacity(recBlink ? 1 : 0.5), fontSize: 11);

    // Film-format badge
    _drawText(canvas, '2.35:1  ANAMORPHIC',
        Offset(size.width - 130, 25),
        color: Colors.white.withOpacity(0.45), fontSize: 9);

    // Bottom bar — scene + take
    _drawText(canvas, 'INT. YOUR ORBIT — NIGHT',
        Offset(16, size.height - barH + 18),
        color: Colors.white.withOpacity(0.55), fontSize: 9);
    _drawText(canvas, 'SCENE 01  TAKE ${(t * 9).toInt() + 1}',
        Offset(size.width - 110, size.height - barH + 18),
        color: Colors.white.withOpacity(0.45), fontSize: 9);
  }

  @override
  bool shouldRepaint(_MainCharacterPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. IT'S GIVING 🌈
// Animated rainbow prism sweep + holographic sparkle burst
// ─────────────────────────────────────────────────────────────────────────────

class _ItsGivingPainter extends CustomPainter {
  final double t;
  _ItsGivingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Holographic rainbow overlay (sweeps across)
    final sweepX = (t * size.width * 1.8) - size.width * 0.4;
    final rainbowShader = LinearGradient(
      colors: const [
        Colors.transparent,
        Color(0x22FF0000),
        Color(0x22FF8800),
        Color(0x22FFFF00),
        Color(0x2200FF00),
        Color(0x220000FF),
        Color(0x22FF00FF),
        Color(0x22FF0088),
        Colors.transparent,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(sweepX, 0, size.width * 0.7, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = rainbowShader);

    // Edge prism refractions
    for (int i = 0; i < 7; i++) {
      final hue = (i / 7 + t * 0.5) % 1.0;
      final col = HSVColor.fromAHSV(1, hue * 360, 1, 1).toColor();
      final y = (i / 7) * size.height;
      canvas.drawLine(Offset(0, y), Offset(18, y + 14),
          Paint()..color = col.withOpacity(0.45)..strokeWidth = 2.5);
      canvas.drawLine(Offset(size.width, y + 10), Offset(size.width - 18, y + 24),
          Paint()..color = col.withOpacity(0.45)..strokeWidth = 2.5);
    }

    // Sparkle burst at center
    final cx = size.width / 2, cy = size.height * 0.45;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + t * math.pi;
      final dist = 40 + math.sin(t * math.pi * 4 + i) * 20;
      final hue = (i / 12) * 360.0;
      _drawStar(canvas,
          Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
          5 + math.sin(t * math.pi * 3 + i) * 2,
          HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
          opacity: 0.55 + math.sin(t * math.pi * 4 + i) * 0.35);
    }

    // "IT'S GIVING EVERYTHING" text badge
    _drawText(canvas, '✨ ITS GIVING ✨',
        Offset(size.width / 2 - 62, size.height * 0.86),
        color: Colors.white, fontSize: 12, weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(_ItsGivingPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. UNDERSTOOD 🖤
// B&W editorial — brutal vignette, film grain, rule-of-thirds, light leak
// ─────────────────────────────────────────────────────────────────────────────

class _UnderstoodPainter extends CustomPainter {
  final double t;
  _UnderstoodPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep vignette
    final vig = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.72),
      ],
      radius: 0.68,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = vig);

    // Rule of thirds grid (barely visible)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), gridPaint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 3),
        Offset(size.width, size.height / 3), gridPaint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), gridPaint);

    // Vertical light leak (right side, drifts with t)
    final leakX = size.width * 0.82 + math.sin(t * math.pi * 2) * 8;
    final leak = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.09),
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.06),
        Colors.transparent,
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(leakX - 20, 0, 55, size.height));
    canvas.drawRect(Rect.fromLTWH(leakX - 20, 0, 55, size.height),
        Paint()..shader = leak);

    // Heavy film grain
    final rng = math.Random(55 + (t * 80).toInt());
    for (int i = 0; i < 340; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2 + 0.3,
        Paint()..color = Colors.white.withOpacity(0.04 + rng.nextDouble() * 0.08),
      );
    }

    // Editorial watermark
    _drawText(canvas, 'ORBIT  №  ${(t * 24).toInt() + 1}',
        Offset(14, size.height - 24),
        color: Colors.white.withOpacity(0.3), fontSize: 9);
  }

  @override
  bool shouldRepaint(_UnderstoodPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. SLAY RAY 💜
// Falling sparkle/star rain + purple aurora at top + diamond shapes
// ─────────────────────────────────────────────────────────────────────────────

class _SlayRayPainter extends CustomPainter {
  final double t;
  _SlayRayPainter(this.t);

  static const _purple = Color(0xFF9B59FF);
  static const _pink = Color(0xFFFF77FF);

  @override
  void paint(Canvas canvas, Size size) {
    // Purple aurora at top
    final aurora = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _purple.withOpacity(0.45 + math.sin(t * math.pi * 2) * 0.12),
        _pink.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0, 0.35, 1],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.42),
        Paint()..shader = aurora);

    // Side aurora columns
    for (int side = 0; side < 2; side++) {
      final x = side == 0 ? 0.0 : size.width - 30;
      final colGrad = LinearGradient(
        begin: side == 0 ? Alignment.centerLeft : Alignment.centerRight,
        end: side == 0 ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          _purple.withOpacity(0.3 + math.sin(t * math.pi * 2 + side) * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, 0, 40, size.height));
      canvas.drawRect(Rect.fromLTWH(x, 0, 40, size.height),
          Paint()..shader = colGrad);
    }

    // Falling sparkle rain (seeded per "particle" so each has its own lane)
    for (int i = 0; i < 28; i++) {
      final seed = math.Random(i * 17 + 3);
      final laneX = seed.nextDouble() * size.width;
      final speed = 0.4 + seed.nextDouble() * 0.6;
      final offset = seed.nextDouble();
      final y = ((t * speed + offset) % 1.0) * size.height;
      final r = 3 + seed.nextDouble() * 5;
      final pulse = math.sin((t * speed + offset) * math.pi * 2) * 0.3 + 0.7;
      final colors = [_purple, _pink, Colors.white];
      _drawStar(canvas, Offset(laneX, y), r * pulse,
          colors[i % colors.length],
          opacity: 0.6 + pulse * 0.3);
    }

    // Large focal diamonds
    final focalPositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.25),
      Offset(size.width * 0.5, size.height * 0.65),
    ];
    for (int i = 0; i < focalPositions.length; i++) {
      final pulse = math.sin(t * math.pi * 2 + i * 1.4) * 0.3 + 0.7;
      _drawStar(canvas, focalPositions[i], (12 + i * 3) * pulse,
          [_purple, _pink, Colors.white][i], opacity: 0.55 * pulse);
    }

    // "SLAY ✦" text
    _drawText(canvas, '✦  S L A Y  ✦',
        Offset(size.width / 2 - 52, size.height * 0.88),
        color: Colors.white.withOpacity(0.9), fontSize: 13, weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(_SlayRayPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. RENT FREE 🌸
// Edge bloom, floating hearts, cherry blossom dots, warm haze
// ─────────────────────────────────────────────────────────────────────────────

class _RentFreePainter extends CustomPainter {
  final double t;
  _RentFreePainter(this.t);

  static const _rose = Color(0xFFFF6688);
  static const _blush = Color(0xFFFFAACC);

  @override
  void paint(Canvas canvas, Size size) {
    // Edge bloom (white glow at all 4 edges)
    final edgeGrad = RadialGradient(
      colors: [Colors.transparent, Colors.white.withOpacity(0.28)],
      radius: 0.5,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = edgeGrad);

    // Warm pink haze at bottom
    final haze = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        _rose.withOpacity(0.22),
        _blush.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0, 0.4, 1],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = haze);

    // Floating bokeh circles
    final rng = math.Random(33);
    for (int i = 0; i < 18; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final br = 6 + rng.nextDouble() * 16;
      final pulse = math.sin(t * math.pi * 2 + i * 0.8) * 0.3 + 0.7;
      canvas.drawCircle(Offset(bx, by), br * pulse, Paint()
        ..color = [_rose, _blush, Colors.white][i % 3].withOpacity(0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // Floating hearts (rising upward)
    for (int i = 0; i < 14; i++) {
      final seed = math.Random(i * 13 + 7);
      final hx = seed.nextDouble() * size.width;
      final speed = 0.3 + seed.nextDouble() * 0.4;
      final phase = seed.nextDouble();
      final hy = size.height - ((t * speed + phase) % 1.0) * size.height * 1.1;
      final hs = 8 + seed.nextDouble() * 10;
      final alpha = (math.sin((t * speed + phase) * math.pi)).clamp(0.0, 1.0);
      _drawHeart(canvas, Offset(hx, hy), hs, _rose.withOpacity(alpha * 0.75));
    }

    // Cherry blossom dots
    for (int i = 0; i < 20; i++) {
      final seed = math.Random(i * 7 + 11);
      final px = seed.nextDouble() * size.width;
      final speed = 0.2 + seed.nextDouble() * 0.3;
      final py = ((t * speed + seed.nextDouble()) % 1.0) * size.height;
      canvas.drawCircle(Offset(px, py), 3 + seed.nextDouble() * 3,
          Paint()..color = _blush.withOpacity(0.5));
    }

    // "living in my head" text
    _drawText(canvas, '🌸  living rent free  🌸',
        Offset(size.width / 2 - 80, size.height * 0.88),
        color: _rose.withOpacity(0.85), fontSize: 11, weight: FontWeight.w800);
  }

  void _drawHeart(Canvas c, Offset pos, double size, Color color) {
    final path = Path();
    final s = size * 0.06;
    path.moveTo(pos.dx, pos.dy + size * 0.3);
    path.cubicTo(pos.dx, pos.dy - size * 0.1,
        pos.dx - size * 0.7, pos.dy - size * 0.1,
        pos.dx - size * 0.7, pos.dy + size * 0.3);
    path.cubicTo(pos.dx - size * 0.7, pos.dy + size * 0.7,
        pos.dx, pos.dy + size * 1.0,
        pos.dx, pos.dy + size * 1.2);
    path.cubicTo(pos.dx, pos.dy + size * 1.0,
        pos.dx + size * 0.7, pos.dy + size * 0.7,
        pos.dx + size * 0.7, pos.dy + size * 0.3);
    path.cubicTo(pos.dx + size * 0.7, pos.dy - size * 0.1,
        pos.dx, pos.dy - size * 0.1,
        pos.dx, pos.dy + size * 0.3);
    c.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RentFreePainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. NO CAP 📼
// Authentic VHS: timestamp, tracking distortion, color bleed, scan noise
// ─────────────────────────────────────────────────────────────────────────────

class _NoCapPainter extends CustomPainter {
  final double t;
  _NoCapPainter(this.t);

  static const _vhsGreen = Color(0xFF44FF88);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11 + (t * 200).toInt());

    // VHS scanlines (every 2px)
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          Paint()..color = Colors.black.withOpacity(0.07));
    }

    // Tracking distortion (wavy horizontal bands that drift down)
    for (int i = 0; i < 3; i++) {
      final trackY = ((t * 1.4 + i * 0.33) % 1.0) * size.height;
      final trackH = 18.0 + rng.nextDouble() * 10;
      canvas.drawRect(
        Rect.fromLTWH(0, trackY, size.width, trackH),
        Paint()..color = Colors.white.withOpacity(0.06),
      );
      // Color bleed inside tracking band
      canvas.drawRect(
        Rect.fromLTWH(0, trackY, size.width, trackH),
        Paint()..color = const Color(0xFF00FFAA).withOpacity(0.08),
      );
    }

    // Horizontal noise lines
    final numNoise = (math.sin(t * math.pi * 8).abs() * 5).toInt();
    for (int i = 0; i < numNoise; i++) {
      final ny = rng.nextDouble() * size.height;
      canvas.drawLine(Offset(0, ny), Offset(size.width, ny),
          Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 0.8);
    }

    // Left edge color bleed
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, size.height),
        Paint()..color = const Color(0xFF0044FF).withOpacity(0.18));

    // Static noise
    for (int i = 0; i < 30; i++) {
      canvas.drawRect(
        Rect.fromLTWH(rng.nextDouble() * size.width,
            rng.nextDouble() * size.height,
            rng.nextDouble() * 4 + 1, 1),
        Paint()..color = Colors.white.withOpacity(0.35 + rng.nextDouble() * 0.35),
      );
    }

    // VHS badge (top-left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 46, 42, 18), Radius.circular(3)),
      Paint()..color = Colors.black.withOpacity(0.6),
    );
    _drawText(canvas, 'VHS', const Offset(15, 49),
        color: _vhsGreen, fontSize: 10, weight: FontWeight.w900);

    // REC blink (top-right)
    final recOn = math.sin(t * math.pi * 2.5) > 0;
    if (recOn) {
      canvas.drawCircle(Offset(size.width - 22, 55), 5, Paint()..color = Colors.red);
    }
    _drawText(canvas, recOn ? '● REC' : '  REC', Offset(size.width - 52, 49),
        color: Colors.white.withOpacity(recOn ? 1 : 0.4), fontSize: 10);

    // Timestamp (bottom-left, VCR style)
    final mins = (t * 4).toInt().toString().padLeft(2, '0');
    final secs = ((t * 240) % 60).toInt().toString().padLeft(2, '0');
    _drawText(canvas, '00:$mins:$secs  SP',
        Offset(12, size.height - 34),
        color: Colors.white.withOpacity(0.75), fontSize: 11, weight: FontWeight.w900);
    _drawText(canvas, '14-JUN-24',
        Offset(12, size.height - 20),
        color: Colors.white.withOpacity(0.5), fontSize: 9);

    // "NO CAP" watermark
    _drawText(canvas, 'NO CAP FR FR',
        Offset(size.width / 2 - 44, size.height * 0.86),
        color: _vhsGreen.withOpacity(0.7), fontSize: 11, weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(_NoCapPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. DELULU 🌙
// Starfield, constellation lines, moon, aurora borealis, shooting star
// ─────────────────────────────────────────────────────────────────────────────

class _DeluluPainter extends CustomPainter {
  final double t;
  _DeluluPainter(this.t);

  static const _stardust = Color(0xFFCCBBFF);
  static const _aurora1 = Color(0xFF00FF88);
  static const _aurora2 = Color(0xFF6644CC);

  @override
  void paint(Canvas canvas, Size size) {
    // Northern lights aurora (top 40%)
    for (int i = 0; i < 4; i++) {
      final aY = size.height * (0.05 + i * 0.08) +
          math.sin(t * math.pi * 2 + i * 1.7) * 18;
      final aColor = i.isEven ? _aurora1 : _aurora2;
      final aGrad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          aColor.withOpacity(0.0),
          aColor.withOpacity(0.08 + math.sin(t * math.pi * 2 + i) * 0.04),
          aColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, aY - 24, size.width, 48));
      canvas.drawRect(Rect.fromLTWH(0, aY - 24, size.width, 48),
          Paint()..shader = aGrad);
    }

    // Star field (seeded — consistent positions)
    final rng = math.Random(13);
    for (int i = 0; i < 90; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height;
      final sr = rng.nextDouble() * 1.8 + 0.4;
      final twinkle = math.sin(t * math.pi * 2 + i * 0.9) * 0.35 + 0.65;
      canvas.drawCircle(Offset(sx, sy), sr * twinkle,
          Paint()..color = Colors.white.withOpacity(0.5 + twinkle * 0.4));
    }

    // Constellation (7 stars connected by lines)
    final stars = [
      Offset(size.width * 0.22, size.height * 0.18),
      Offset(size.width * 0.38, size.height * 0.12),
      Offset(size.width * 0.52, size.height * 0.20),
      Offset(size.width * 0.45, size.height * 0.32),
      Offset(size.width * 0.30, size.height * 0.28),
      Offset(size.width * 0.18, size.height * 0.35),
      Offset(size.width * 0.60, size.height * 0.14),
    ];
    final linePaint = Paint()
      ..color = _stardust.withOpacity(0.25)
      ..strokeWidth = 0.6;
    final lineConnections = [[0,1],[1,2],[2,3],[3,4],[4,0],[1,6],[4,5]];
    for (final pair in lineConnections) {
      canvas.drawLine(stars[pair[0]], stars[pair[1]], linePaint);
    }
    for (final s in stars) {
      final twinkle = math.sin(t * math.pi * 2 + s.dx * 0.01) * 0.3 + 0.7;
      canvas.drawCircle(s, 3 * twinkle, Paint()..color = _stardust.withOpacity(0.8));
      canvas.drawCircle(s, 5 * twinkle, Paint()
        ..color = _stardust.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    // Crescent moon (top-right)
    _drawMoon(canvas, Offset(size.width - 52, 68));

    // Shooting star (streaks across)
    final shotProgress = (t * 1.2) % 1.0;
    if (shotProgress < 0.5) {
      final sx = shotProgress * size.width * 1.8 - size.width * 0.2;
      final sy = size.height * 0.14 + shotProgress * size.height * 0.1;
      final trailLen = 60.0;
      final shotGrad = LinearGradient(
        colors: [Colors.transparent, Colors.white.withOpacity(0.8)],
      ).createShader(Rect.fromLTWH(sx - trailLen, sy - 4, trailLen, 8));
      canvas.drawLine(Offset(sx - trailLen, sy), Offset(sx, sy),
          Paint()..shader = shotGrad..strokeWidth = 1.5);
    }

    // "delulu but make it cute" text
    _drawText(canvas, '🌙  delulu szn  🌙',
        Offset(size.width / 2 - 58, size.height * 0.87),
        color: _stardust.withOpacity(0.9), fontSize: 11, weight: FontWeight.w800);
  }

  void _drawMoon(Canvas c, Offset center) {
    const r = 22.0;
    // Full circle
    c.drawCircle(center, r, Paint()..color = const Color(0xFFFFEEAA).withOpacity(0.9));
    // Bite out (crescent)
    c.drawCircle(Offset(center.dx + 10, center.dy - 6), r * 0.85,
        Paint()..color = const Color(0xFF0A0025).withOpacity(0.95));
    // Moon glow
    c.drawCircle(center, r + 4, Paint()
      ..color = const Color(0xFFFFEEAA).withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(_DeluluPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty (no-op) painter
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {}
  @override
  bool shouldRepaint(_EmptyPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// SnapFilterPicker — horizontal scroll strip
// ─────────────────────────────────────────────────────────────────────────────

class SnapFilterPicker extends StatelessWidget {
  final SnapFilter? selected;
  final ValueChanged<SnapFilter?> onSelect;

  const SnapFilterPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kSnapFilters.length + 1, // +1 for "None"
        itemBuilder: (_, i) {
          if (i == 0) {
            // "None" chip
            final isNone = selected == null;
            return GestureDetector(
              onTap: () => onSelect(null),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(
                        color: isNone ? Colors.white : Colors.white24,
                        width: isNone ? 2.5 : 1,
                      ),
                    ),
                    child: const Icon(Icons.do_not_disturb_rounded,
                        color: Colors.white54, size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text('none',
                      style: TextStyle(
                          color: isNone ? Colors.white : Colors.white38,
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          }
          final filter = kSnapFilters[i - 1];
          final isSelected = selected?.id == filter.id;
          return GestureDetector(
            onTap: () => onSelect(filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: filter.chipColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 2.5 : 0,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: filter.chipColors.first.withOpacity(0.55),
                            blurRadius: 10, offset: const Offset(0, 3))]
                        : null,
                  ),
                  child: Center(
                    child: Text(filter.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(filter.name,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          );
        },
      ),
    );
  }
}
