import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';

class VybeMapScreen extends StatefulWidget {
  const VybeMapScreen({super.key});
  @override
  State<VybeMapScreen> createState() => _VybeMapScreenState();
}

class _VybeMapScreenState extends State<VybeMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int? _selected;

  // [xFraction, yFraction, song, handle, count]
  static const _dots = [
    [0.14, 0.24, 'Espresso', '@maya.k', 12],
    [0.36, 0.40, 'luther', '@zara.w', 8],
    [0.55, 0.28, 'APT.', '@dev.s', 22],
    [0.79, 0.42, 'Golden Hour', '@rina.p', 5],
    [0.10, 0.58, 'Die With A Smile', '@jay.r', 7],
    [0.44, 0.22, 'Blinding Lights', '@sam.w', 15],
    [0.64, 0.60, 'Peaches', '@leo.k', 3],
    [0.22, 0.68, 'Levitating', '@ari.c', 9],
    [0.70, 0.20, 'STAY', '@mia.t', 11],
    [0.30, 0.50, 'As It Was', '@kai.r', 6],
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080818),
        foregroundColor: Colors.white,
        title: const Text('vybe map',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded,
                    size: 14, color: AuraTheme.accent),
                SizedBox(width: 6),
                Text('people vibing to the same songs as you',
                    style: TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (ctx, _) => LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return GestureDetector(
                  onTapDown: (det) {
                    // Tap on empty space → deselect
                    setState(() => _selected = null);
                  },
                  child: CustomPaint(
                    painter: _MapPainter(),
                    child: Stack(
                      children: List.generate(_dots.length, (i) {
                        final d = _dots[i];
                        final x = (d[0] as double) * w;
                        final y = (d[1] as double) * h;
                        final phase =
                            _pulse.value * 2 * math.pi + i * 0.6;
                        final ring =
                            (math.sin(phase) * 0.5 + 0.5) * 16 + 6;
                        final isSelected = _selected == i;
                        return Positioned(
                          left: x - 20,
                          top: y - 20,
                          child: GestureDetector(
                            onTap: () {
                              setState(() =>
                                  _selected = _selected == i ? null : i);
                            },
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: ring,
                                      height: ring,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (isSelected
                                                ? AuraTheme.accentLight
                                                : AuraTheme.accent)
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    Container(
                                      width: isSelected ? 13 : 9,
                                      height: isSelected ? 13 : 9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AuraTheme.accentLight
                                            : AuraTheme.accent,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AuraTheme.accent
                                                      .withOpacity(0.6),
                                                  blurRadius: 8,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Info panel
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selected != null
              ? _infoPanel(_dots[_selected!])
              : const SizedBox(height: 60, key: ValueKey('empty')),
        ),
      ]),
    );
  }

  Widget _infoPanel(List<Object> d) => Container(
        key: ValueKey(d[3]),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14142A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.accent.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.music_note_rounded,
                color: AuraTheme.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d[2] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  '${d[3]} · ${d[4]} others vibing',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.4), size: 20),
          ),
        ]),
      );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ocean background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF080818),
    );

    // Grid
    final grid = Paint()
      ..color = const Color(0xFF12122A)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 7; i++) {
      canvas.drawLine(Offset(w * i / 7, 0), Offset(w * i / 7, h), grid);
    }
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(0, h * i / 5), Offset(w, h * i / 5), grid);
    }

    // Continent blobs
    final land = Paint()
      ..color = const Color(0xFF1A1A38)
      ..style = PaintingStyle.fill;

    void blob(double x, double y, double bw, double bh, double r) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * x, h * y, w * bw, h * bh),
            Radius.circular(r)),
        land,
      );
    }

    blob(0.03, 0.15, 0.21, 0.38, 18); // North America
    blob(0.13, 0.55, 0.12, 0.30, 14); // South America
    blob(0.40, 0.10, 0.11, 0.26, 10); // Europe
    blob(0.40, 0.37, 0.12, 0.38, 12); // Africa
    blob(0.51, 0.08, 0.31, 0.38, 18); // Asia
    blob(0.72, 0.54, 0.12, 0.20, 10); // Australia
  }

  @override
  bool shouldRepaint(_MapPainter _) => false;
}
