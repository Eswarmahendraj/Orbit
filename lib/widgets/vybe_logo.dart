import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aura_theme.dart';

/// Animated Orbit logo — glowing O ring with orbiting dot and pulse wave.
class VybeLogo extends StatefulWidget {
  final double size;
  final bool pulse;
  const VybeLogo({super.key, this.size = 120, this.pulse = true});

  @override
  State<VybeLogo> createState() => _VybeLogoState();
}

class _VybeLogoState extends State<VybeLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.pulse) _ctrl.repeat();
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
        size: Size(widget.size, widget.size),
        painter: _OrbitLogoPainter(_ctrl.value),
      ),
    );
  }
}

class _OrbitLogoPainter extends CustomPainter {
  final double t; // 0..1 loop value
  _OrbitLogoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Outer glow ────────────────────────────────────────────────────────────
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.46 + i * 3.0 * math.sin(t * math.pi * 2).abs(),
        Paint()
          ..color = AuraColors.accent.withOpacity(0.06 / i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // ── Dark circle background ────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0A0720)],
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.45)),
    );

    // ── "O" ring ──────────────────────────────────────────────────────────────
    final ringR = w * 0.30;

    // Glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      ringR,
      Paint()
        ..shader = AuraColors.brandGradient.createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: ringR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 6 * math.sin(t * math.pi * 2).abs()),
    );

    // Crisp ring on top
    canvas.drawCircle(
      Offset(cx, cy),
      ringR,
      Paint()
        ..shader = AuraColors.brandGradient.createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: ringR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0,
    );

    // ── Orbiting dot ──────────────────────────────────────────────────────────
    final angle = t * math.pi * 2 - math.pi / 2;
    final dotX = cx + ringR * math.cos(angle);
    final dotY = cy + ringR * math.sin(angle);

    // Dot glow trail
    for (int i = 1; i <= 5; i++) {
      final trailAngle = angle - i * 0.18;
      final tx = cx + ringR * math.cos(trailAngle);
      final ty = cy + ringR * math.sin(trailAngle);
      canvas.drawCircle(
        Offset(tx, ty),
        4.0 - i * 0.5,
        Paint()
          ..color = AuraColors.accent.withOpacity(0.15 * (6 - i) / 5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Dot itself
    canvas.drawCircle(
      Offset(dotX, dotY),
      6.5,
      Paint()
        ..color = AuraColors.accent.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      4.5,
      Paint()..color = Colors.white,
    );

    // ── Outer border ring of the logo circle ──────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = AuraColors.accent.withOpacity(0.25 + 0.15 * math.sin(t * math.pi * 2).abs())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_OrbitLogoPainter old) => old.t != t;
}

/// Static text logo — "ORBIT" with gradient
class VybeTextLogo extends StatelessWidget {
  final double fontSize;
  const VybeTextLogo({super.key, this.fontSize = 48});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AuraColors.brandGradient.createShader(bounds),
      child: Text(
        'ORBIT',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.18,
          color: Colors.white,
        ),
      ),
    );
  }
}
