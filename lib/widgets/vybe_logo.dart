import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aura_theme.dart';

/// Animated Vybe logo — glowing V with a pulse wave inside.
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
    if (widget.pulse) _ctrl.repeat(reverse: true);
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
        painter: _VybeLogoPainter(_ctrl.value),
      ),
    );
  }
}

class _VybeLogoPainter extends CustomPainter {
  final double t; // 0..1 pulse value
  _VybeLogoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // ── Outer glow ring ───────────────────────────────────────────────────────
    final glowAlpha = 0.08 + 0.12 * t;
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        w * 0.46 + i * 4.0 * t,
        Paint()
          ..color = AuraColors.accent.withOpacity(glowAlpha / i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // ── Circle background ──────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1A1040), Color(0xFF0A0720)],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.45));
    canvas.drawCircle(Offset(cx, cy), w * 0.46, bgPaint);

    // Border ring
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = AuraColors.accent.withOpacity(0.4 + 0.3 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── "V" shape ──────────────────────────────────────────────────────────────
    final vLeft  = Offset(w * 0.18, h * 0.28);
    final vTip   = Offset(cx, h * 0.72);
    final vRight = Offset(w * 0.82, h * 0.28);

    final vGlowPaint = Paint()
      ..shader = AuraColors.brandGradient.createShader(
          Rect.fromPoints(vLeft, vRight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 6 * t);

    final vPath = Path()
      ..moveTo(vLeft.dx, vLeft.dy)
      ..lineTo(vTip.dx, vTip.dy)
      ..lineTo(vRight.dx, vRight.dy);

    canvas.drawPath(vPath, vGlowPaint);

    // Crisp V on top
    final vPaint = Paint()
      ..shader = AuraColors.brandGradient.createShader(
          Rect.fromPoints(vLeft, vRight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(vPath, vPaint);

    // ── Pulse wave inside V ────────────────────────────────────────────────────
    // Draw a small waveform along the bottom half of the V center
    final wavePaint = Paint()
      ..color = AuraColors.cyan.withOpacity(0.7 + 0.3 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

    final wavePath = Path();
    const steps = 40;
    final waveW = w * 0.36;
    final waveX0 = cx - waveW / 2;
    final waveY = h * 0.52;
    const amp = 6.0;

    for (int i = 0; i <= steps; i++) {
      final dx = waveX0 + (waveW * i / steps);
      final progress = i / steps;
      // Sine wave with envelope (fades at edges)
      final envelope = math.sin(progress * math.pi);
      final dy = waveY -
          amp * envelope * math.sin((progress * 4 + t * 2) * math.pi * 2);
      if (i == 0) {
        wavePath.moveTo(dx, dy);
      } else {
        wavePath.lineTo(dx, dy);
      }
    }
    canvas.drawPath(wavePath, wavePaint);

    // ── Center dot ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      vTip,
      3.5 + 2 * t,
      Paint()
        ..color = AuraColors.pink.withOpacity(0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * t + 2),
    );
    canvas.drawCircle(
      vTip,
      2.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_VybeLogoPainter old) => old.t != t;
}

/// Static text logo — "VYBE" with gradient
class VybeTextLogo extends StatelessWidget {
  final double fontSize;
  const VybeTextLogo({super.key, this.fontSize = 48});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          AuraColors.brandGradient.createShader(bounds),
      child: Text(
        'VYBE',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.18,
          color: Colors.white, // masked by shader
        ),
      ),
    );
  }
}
