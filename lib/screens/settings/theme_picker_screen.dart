import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/theme_service.dart';
import '../../theme/aura_theme.dart';

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = ThemeService().id;
    _glow = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _pick(AuraThemePreset preset) {
    HapticFeedback.lightImpact();
    setState(() => _selected = preset.id);
    ThemeService().setPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('app theme',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pick your aesthetic ✦',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.3),
            ),
            const SizedBox(height: 20),
            // ── Grid of theme cards ──────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: AuraThemePresets.all.length,
              itemBuilder: (_, i) {
                final preset = AuraThemePresets.all[i];
                final active = _selected == preset.id;
                return _ThemeCard(
                  preset: preset,
                  active: active,
                  glow: _glow,
                  onTap: () => _pick(preset),
                );
              },
            ),
            const SizedBox(height: 24),
            // ── Note ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'themes change accent colors, card tints, and gradients across the whole app.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual theme card ─────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final AuraThemePreset preset;
  final bool active;
  final AnimationController glow;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.preset,
    required this.active,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: glow,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: preset.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? preset.accent.withOpacity(0.7 + glow.value * 0.3)
                    : Colors.white.withOpacity(0.08),
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: preset.accent
                            .withOpacity(0.25 + glow.value * 0.15),
                        blurRadius: 20,
                        spreadRadius: 0,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // ── Gradient preview ──────────────────────────
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: CustomPaint(
                      painter: _PreviewPainter(
                          preset: preset, t: glow.value),
                    ),
                  ),
                ),
                // ── Content ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji + checkmark
                      Row(children: [
                        Text(preset.emoji,
                            style: const TextStyle(fontSize: 26)),
                        const Spacer(),
                        if (active)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: preset.accent,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                          ),
                      ]),
                      const Spacer(),
                      // Name
                      Text(
                        preset.name,
                        style: TextStyle(
                          color: preset.accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.tagline,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Color swatch row
                      Row(children: [
                        _Swatch(preset.accent),
                        const SizedBox(width: 5),
                        _Swatch(preset.accentLight),
                        const SizedBox(width: 5),
                        _Swatch(preset.purple),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch(this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
            color: color, shape: BoxShape.circle),
      );
}

// ── Background preview painter ────────────────────────────────────────────────
class _PreviewPainter extends CustomPainter {
  final AuraThemePreset preset;
  final double t;
  const _PreviewPainter({required this.preset, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Radial glow at top-right
    final r = size.width * (0.5 + math.sin(t * 2 * math.pi) * 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          preset.accent.withOpacity(0.18),
          Colors.transparent,
        ]).createShader(
            Rect.fromCircle(center: Offset(size.width, 0), radius: r)),
    );
    // Diagonal gradient stripe
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            preset.gradient[0].withOpacity(0.08),
            preset.gradient[1].withOpacity(0.04),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.t != t || old.preset.id != preset.id;
}
