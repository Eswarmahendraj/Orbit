import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORBIT DM Wallpapers
// 16 built-in designs + custom photo from gallery.
// All rendered as CustomPainter — no external assets required.
//
// Categories:
//   Vibes   — cosmos · golden hour · neon pulse · midnight mist
//   Music   — vinyl · waveform · equalizer · album mosaic
//   Abstract— constellation · hexagons · neon rain · aurora
//   Gradient— rose mist · deep ocean · forest night · velvet dusk
// ─────────────────────────────────────────────────────────────────────────────

enum DmWallpaper {
  none,
  // vibes
  cosmos,
  goldenHour,
  neonPulse,
  midnightMist,
  // music
  vinyl,
  waveform,
  equalizer,
  albumMosaic,
  // abstract
  constellation,
  hexagons,
  neonRain,
  aurora,
  // gradients
  roseMist,
  deepOcean,
  forestNight,
  velvetDusk,
  // custom (from device gallery)
  custom,
}

extension DmWallpaperX on DmWallpaper {
  String get label {
    switch (this) {
      case DmWallpaper.none:         return 'none';
      case DmWallpaper.cosmos:       return 'dark cosmos';
      case DmWallpaper.goldenHour:   return 'golden hour';
      case DmWallpaper.neonPulse:    return 'neon pulse';
      case DmWallpaper.midnightMist: return 'midnight mist';
      case DmWallpaper.vinyl:        return 'vinyl';
      case DmWallpaper.waveform:     return 'waveform';
      case DmWallpaper.equalizer:    return 'equalizer';
      case DmWallpaper.albumMosaic:  return 'album mosaic';
      case DmWallpaper.constellation:return 'constellation';
      case DmWallpaper.hexagons:     return 'hexagons';
      case DmWallpaper.neonRain:     return 'neon rain';
      case DmWallpaper.aurora:       return 'aurora';
      case DmWallpaper.roseMist:     return 'rose mist';
      case DmWallpaper.deepOcean:    return 'deep ocean';
      case DmWallpaper.forestNight:  return 'forest night';
      case DmWallpaper.velvetDusk:   return 'velvet dusk';
      case DmWallpaper.custom:       return 'my photo';
    }
  }

  String get category {
    switch (this) {
      case DmWallpaper.cosmos:
      case DmWallpaper.goldenHour:
      case DmWallpaper.neonPulse:
      case DmWallpaper.midnightMist: return 'vibes';
      case DmWallpaper.vinyl:
      case DmWallpaper.waveform:
      case DmWallpaper.equalizer:
      case DmWallpaper.albumMosaic:  return 'music';
      case DmWallpaper.constellation:
      case DmWallpaper.hexagons:
      case DmWallpaper.neonRain:
      case DmWallpaper.aurora:       return 'abstract';
      case DmWallpaper.roseMist:
      case DmWallpaper.deepOcean:
      case DmWallpaper.forestNight:
      case DmWallpaper.velvetDusk:   return 'gradients';
      default:                       return '';
    }
  }

  // Dark overlay opacity — some wallpapers need more to keep text readable
  double get overlayOpacity {
    switch (this) {
      case DmWallpaper.goldenHour:  return 0.30;
      case DmWallpaper.albumMosaic: return 0.55;
      case DmWallpaper.aurora:      return 0.25;
      case DmWallpaper.custom:      return 0.50;
      default:                      return 0.0;
    }
  }
}

// ── Wallpaper widget ───────────────────────────────────────────────────────────

class WallpaperWidget extends StatelessWidget {
  final DmWallpaper wallpaper;
  final String? customImagePath;
  final Widget child;

  const WallpaperWidget({
    super.key,
    required this.wallpaper,
    this.customImagePath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (wallpaper == DmWallpaper.none) return child;

    return Stack(children: [
      // Wallpaper layer
      Positioned.fill(
        child: wallpaper == DmWallpaper.custom && customImagePath != null
            ? Image.file(File(customImagePath!), fit: BoxFit.cover)
            : CustomPaint(
                painter: _wallpaperPainter(wallpaper),
                child: const SizedBox.expand(),
              ),
      ),
      // Dark overlay for readability
      if (wallpaper.overlayOpacity > 0)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(wallpaper.overlayOpacity),
          ),
        ),
      // Content
      child,
    ]);
  }

  CustomPainter _wallpaperPainter(DmWallpaper w) {
    switch (w) {
      case DmWallpaper.cosmos:        return _CosmosPainter();
      case DmWallpaper.goldenHour:    return _GoldenHourPainter();
      case DmWallpaper.neonPulse:     return _NeonPulsePainter();
      case DmWallpaper.midnightMist:  return _MidnightMistPainter();
      case DmWallpaper.vinyl:         return _VinylPainter();
      case DmWallpaper.waveform:      return _WaveformPainter();
      case DmWallpaper.equalizer:     return _EqualizerPainter();
      case DmWallpaper.albumMosaic:   return _AlbumMosaicPainter();
      case DmWallpaper.constellation: return _ConstellationPainter();
      case DmWallpaper.hexagons:      return _HexagonsPainter();
      case DmWallpaper.neonRain:      return _NeonRainPainter();
      case DmWallpaper.aurora:        return _AuroraPainter();
      case DmWallpaper.roseMist:      return _RoseMistPainter();
      case DmWallpaper.deepOcean:     return _DeepOceanPainter();
      case DmWallpaper.forestNight:   return _ForestNightPainter();
      case DmWallpaper.velvetDusk:    return _VelvetDuskPainter();
      default:                        return _CosmosPainter();
    }
  }
}

// ── Wallpaper picker sheet ─────────────────────────────────────────────────────

class WallpaperPickerSheet extends StatefulWidget {
  final DmWallpaper current;
  final String? currentImagePath;
  final void Function(DmWallpaper wallpaper, String? imagePath) onPicked;

  const WallpaperPickerSheet({
    super.key,
    required this.current,
    this.currentImagePath,
    required this.onPicked,
  });

  @override
  State<WallpaperPickerSheet> createState() => _WallpaperPickerSheetState();
}

class _WallpaperPickerSheetState extends State<WallpaperPickerSheet> {
  late DmWallpaper _selected;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _imagePath = widget.currentImagePath;
  }

  static const _categories = ['vibes', 'music', 'abstract', 'gradients'];

  List<DmWallpaper> _forCategory(String cat) => DmWallpaper.values
      .where((w) => w != DmWallpaper.none && w != DmWallpaper.custom && w.category == cat)
      .toList();

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;
      if (mounted) {
        setState(() {
          _selected = DmWallpaper.custom;
          _imagePath = picked.path;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open gallery.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              const Text('chat wallpaper',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const Spacer(),
              // None option
              GestureDetector(
                onTap: () => setState(() {
                  _selected = DmWallpaper.none;
                  _imagePath = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selected == DmWallpaper.none
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 0.5),
                  ),
                  child: const Text('none',
                      style: TextStyle(
                          color: Colors.white, fontSize: 12)),
                ),
              ),
            ]),
          ),
          // Scrollable grid
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // Gallery picker
                _GalleryPickerCard(
                  hasImage: _imagePath != null,
                  imagePath: _imagePath,
                  isSelected: _selected == DmWallpaper.custom,
                  onTap: _pickFromGallery,
                ),
                const SizedBox(height: 16),
                // Each category
                ..._categories.map((cat) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(cat,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666680),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6)),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.5,
                      children: _forCategory(cat).map((w) =>
                          _WallpaperTile(
                            wallpaper: w,
                            isSelected: _selected == w,
                            onTap: () => setState(() {
                              _selected = w;
                              _imagePath = null;
                            }),
                          )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                )),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onPicked(_selected, _imagePath);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('apply wallpaper',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Gallery picker card ────────────────────────────────────────────────────────

class _GalleryPickerCard extends StatelessWidget {
  final bool hasImage;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalleryPickerCard({
    required this.hasImage,
    this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.12),
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(children: [
          // Preview
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: hasImage && imagePath != null
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withOpacity(0.06),
                      child: Icon(Icons.photo_library_outlined,
                          color: Colors.white.withOpacity(0.4), size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(hasImage ? 'my photo' : 'choose from gallery',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                hasImage ? 'tap to change' : 'use any photo as background',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.3), size: 20),
          ),
        ]),
      ),
    );
  }
}

// ── Individual wallpaper tile ──────────────────────────────────────────────────

class _WallpaperTile extends StatelessWidget {
  final DmWallpaper wallpaper;
  final bool isSelected;
  final VoidCallback onTap;

  const _WallpaperTile({
    required this.wallpaper,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              // Wallpaper preview (full CustomPaint)
              Positioned.fill(
                child: CustomPaint(
                  painter: WallpaperWidget(
                    wallpaper: wallpaper,
                    child: const SizedBox.shrink(),
                  )._wallpaperPainter(wallpaper),
                  child: const SizedBox.expand(),
                ),
              ),
              // Selection border
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 0.5),
                  ),
                ),
              ),
              // Checkmark
              if (isSelected)
                Positioned(
                  top: 5, right: 5,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check,
                        color: Colors.black, size: 12),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        Text(wallpaper.label,
            style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER IMPLEMENTATIONS
// ─────────────────────────────────────────────────────────────────────────────

// ── Shared helpers ─────────────────────────────────────────────────────────────

void _paintStars(Canvas canvas, Size size, math.Random rng, int count,
    {double maxRadius = 1.5}) {
  final paint = Paint();
  for (var i = 0; i < count; i++) {
    final x = rng.nextDouble() * size.width;
    final y = rng.nextDouble() * size.height;
    final r = rng.nextDouble() * maxRadius + 0.3;
    final a = rng.nextDouble() * 0.7 + 0.3;
    paint.color = Colors.white.withOpacity(a);
    canvas.drawCircle(Offset(x, y), r, paint);
  }
}

void _paintRadialGlow(Canvas canvas, Size size,
    {required double cx, required double cy, required double radius,
     required Color color}) {
  final paint = Paint()
    ..shader = RadialGradient(
      colors: [color, Colors.transparent],
    ).createShader(Rect.fromCircle(
        center: Offset(cx * size.width, cy * size.height),
        radius: radius * size.width));
  canvas.drawRect(Offset.zero & size, paint);
}

// ══════════════════════════════════════════════════════════
// VIBES
// ══════════════════════════════════════════════════════════

class _CosmosPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF07070F), Color(0xFF1B0A3C), Color(0xFF0D0821)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Nebula glow
    _paintRadialGlow(canvas, size,
        cx: 0.6, cy: 0.3, radius: 0.55,
        color: const Color(0xFF7F5AC8).withOpacity(0.3));
    _paintRadialGlow(canvas, size,
        cx: 0.2, cy: 0.7, radius: 0.4,
        color: const Color(0xFF3040A0).withOpacity(0.2));

    // Stars
    _paintStars(canvas, size, math.Random(42), 120);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GoldenHourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF1A0A00), Color(0xFF7A3210),
          Color(0xFFD85A30), Color(0xFFFF8C42),
        ],
        stops: const [0.0, 0.35, 0.7, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Sun glow at horizon
    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.72, radius: 0.9,
        color: const Color(0xFFFFC850).withOpacity(0.35));

    // Stars in upper sky
    _paintStars(canvas, size, math.Random(7), 30,
        maxRadius: 1.0);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _NeonPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF030308));

    final cx = size.width * 0.5;
    final cy = size.height * 0.35;

    // Concentric rings
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final r = size.width * (0.08 + i * 0.07);
      final a = 0.04 + i * 0.02;
      ringPaint.color = const Color(0xFFFF6B1E).withOpacity(a);
      ringPaint.strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    }

    // Central glow
    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.35, radius: 0.3,
        color: const Color(0xFFFF8C42).withOpacity(0.6));

    // Faint secondary glow
    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.35, radius: 0.7,
        color: const Color(0xFFFF4040).withOpacity(0.08));

    _paintStars(canvas, size, math.Random(13), 40);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MidnightMistPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080812));

    _paintRadialGlow(canvas, size,
        cx: 0.3, cy: 0.8, radius: 0.65,
        color: const Color(0xFF3C3278).withOpacity(0.25));
    _paintRadialGlow(canvas, size,
        cx: 0.75, cy: 0.5, radius: 0.45,
        color: const Color(0xFF281E58).withOpacity(0.2));
    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.2, radius: 0.4,
        color: const Color(0xFF1E2860).withOpacity(0.15));

    _paintStars(canvas, size, math.Random(99), 90);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════
// MUSIC
// ══════════════════════════════════════════════════════════

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A0A12));

    const accent = Color(0xFFFF8C42);
    final cx = size.width * 0.5;
    final cy = size.height * 0.38;
    final maxR = size.width * 0.38;

    // Groove rings
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    var r = maxR;
    while (r > size.width * 0.06) {
      final frac = r / maxR;
      groovePaint.color = accent.withOpacity(0.03 + (1 - frac) * 0.12);
      canvas.drawCircle(Offset(cx, cy), r, groovePaint);
      r -= size.width * 0.018;
    }

    // Outer rim
    canvas.drawCircle(Offset(cx, cy), maxR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withOpacity(0.5));

    // Label disc
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.09, Paint()..color = accent);

    // Label text ring (decorative)
    canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.075,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.white.withOpacity(0.3));

    // Centre hole
    canvas.drawCircle(
        Offset(cx, cy), size.width * 0.015,
        Paint()..color = const Color(0xFF0A0A12));

    // Tonearm line
    final armPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(size.width * 0.82, size.height * 0.06),
        Offset(cx + maxR * 0.6, cy - maxR * 0.15),
        armPaint);

    _paintStars(canvas, size, math.Random(5), 25);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF07070F), Color(0xFF0F0F2A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final rng = math.Random(17);
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const rows = 12;
    for (var row = 0; row < rows; row++) {
      final y = size.height * (0.06 + row / rows * 0.88);
      final amp = 2.0 + rng.nextDouble() * 6.0;
      final freq = 0.18 + rng.nextDouble() * 0.12;
      final phase = rng.nextDouble() * math.pi * 2;
      final alpha = 0.07 + row / rows * 0.18;
      wavePaint.color = const Color(0xFFFF8C42).withOpacity(alpha);

      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 1.5) {
        path.lineTo(x, y + math.sin(x * freq + phase) * amp);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _EqualizerPainter extends CustomPainter {
  static const _barHeights = [
    0.28, 0.52, 0.74, 0.92, 0.60, 0.82, 0.38, 0.96,
    0.54, 0.78, 0.34, 0.66, 0.88, 0.44, 0.70, 0.50,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF05050E));

    const cols = 16;
    const gap = 3.0;
    final bw = (size.width - gap * (cols + 1)) / cols;

    for (var i = 0; i < cols; i++) {
      final ht = _barHeights[i % _barHeights.length];
      final bh = size.height * ht * 0.82;
      final x = gap + (bw + gap) * i;
      final y = size.height - bh - size.height * 0.04;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFF8C42).withOpacity(0.95),
            const Color(0xFFFF8C42).withOpacity(0.15),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, bw, bh));

      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, bh), const Radius.circular(2));
      canvas.drawRRect(rr, paint);

      // Peak dot
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y - 4, bw, 2.5),
              const Radius.circular(1)),
          Paint()..color = const Color(0xFFFF8C42));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AlbumMosaicPainter extends CustomPainter {
  static const _palette = [
    Color(0xFF1B0F1A), Color(0xFF2A0F2A), Color(0xFF0F1B2A),
    Color(0xFF1A2A0F), Color(0xFF2A1A0F), Color(0xFF0F2A1A),
    Color(0xFF1A0F2A), Color(0xFF2A0A0A), Color(0xFF0A1A2A),
  ];
  static const _accents = [
    Color(0xFFFF8C42), Color(0xFF7F77DD), Color(0xFF1D9E75),
    Color(0xFFD85A30), Color(0xFFBA7517), Color(0xFF534AB7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 28.0;
    final rng = math.Random(101);
    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final color = _palette[rng.nextInt(_palette.length)];
        canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 1.5, cellSize - 1.5),
            Paint()..color = color);

        if (rng.nextDouble() < 0.14) {
          canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 1.5, cellSize - 1.5),
              Paint()..color = _accents[rng.nextInt(_accents.length)].withOpacity(0.35));
        }
      }
    }

    // Dark overlay
    final overlay = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.45),
          Colors.black.withOpacity(0.65),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, overlay);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════
// ABSTRACT
// ══════════════════════════════════════════════════════════

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF06060F));

    final rng = math.Random(33);
    final pts = List.generate(28, (_) => Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height));

    // Connect nearby points
    final linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;
    for (final p1 in pts) {
      for (final p2 in pts) {
        if (p1 == p2) continue;
        final d = (p2 - p1).distance;
        if (d < size.width * 0.28 && d > 4) {
          final a = (0.12 - d / (size.width * 0.28) * 0.12).clamp(0.0, 0.12);
          linePaint.color = const Color(0xFF7F77DD).withOpacity(a);
          canvas.drawLine(p1, p2, linePaint);
        }
      }
    }

    // Star dots
    final dotPaint = Paint()..color = const Color(0xFFCCC8FF).withOpacity(0.85);
    for (final p in pts) {
      canvas.drawCircle(p, 1.4, dotPaint);
    }

    _paintStars(canvas, size, math.Random(44), 55, maxRadius: 0.9);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HexagonsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF080812));

    final rng = math.Random(22);
    const s = 18.0; // hex size
    final rows = (size.height / (s * 1.732)).ceil() + 2;
    final cols = (size.width / (s * 2)).ceil() + 2;
    final hexPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.7;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * s * 2 + (r % 2) * s - s * 0.5;
        final cy = r * s * 1.732 - s;
        final a = 0.04 + rng.nextDouble() * 0.1;
        hexPaint.color = const Color(0xFFFF8C42).withOpacity(a);

        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = math.pi / 3 * i - math.pi / 6;
          final px = cx + s * 0.88 * math.cos(angle);
          final py = cy + s * 0.88 * math.sin(angle);
          if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, hexPaint);

        // Occasional filled hex
        if (rng.nextDouble() < 0.04) {
          canvas.drawPath(path,
              Paint()..color = const Color(0xFFFF8C42).withOpacity(0.06));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _NeonRainPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFFF641E), Color(0xFF7F64E6), Color(0xFF1EB478),
    Color(0xFFFF8C42), Color(0xFF534AB7), Color(0xFF1D9E75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF030308));

    final rng = math.Random(77);
    for (var i = 0; i < 55; i++) {
      final x = rng.nextDouble() * size.width;
      final y1 = rng.nextDouble() * size.height;
      final len = size.height * (0.04 + rng.nextDouble() * 0.16);
      final color = _colors[rng.nextInt(_colors.length)];
      final alpha = 0.4 + rng.nextDouble() * 0.45;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(alpha), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x - 0.5, y1, 1, len))
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, y1), Offset(x, y1 + len), paint);

      // Glow dot at top
      canvas.drawCircle(Offset(x, y1), 1.0,
          Paint()..color = color.withOpacity(alpha * 0.8));
    }

    _paintStars(canvas, size, math.Random(88), 20);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF030C10));

    // Background glow pools
    _paintRadialGlow(canvas, size,
        cx: 0.25, cy: 0.35, radius: 0.85,
        color: const Color(0xFF1D9E75).withOpacity(0.22));
    _paintRadialGlow(canvas, size,
        cx: 0.72, cy: 0.55, radius: 0.65,
        color: const Color(0xFF7F77DD).withOpacity(0.18));
    _paintRadialGlow(canvas, size,
        cx: 0.45, cy: 0.22, radius: 0.5,
        color: const Color(0xFF1E8CB4).withOpacity(0.14));

    // Aurora curtain bands
    final rng = math.Random(55);
    final bandPaint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.12 + i * 0.085);
      final amp = 4.0 + i * 3.5;
      final alpha = 0.04 + i * 0.025;
      final width = 2.0 + i * 0.5;
      bandPaint.color = const Color(0xFF1DCA8C).withOpacity(alpha);
      bandPaint.strokeWidth = width;

      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 2) {
        path.lineTo(x,
            y + math.sin(x * 0.045 + i * 0.7 + rng.nextDouble()) * amp);
      }
      canvas.drawPath(path, bandPaint);
    }

    _paintStars(canvas, size, math.Random(56), 55);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════
// GRADIENTS
// ══════════════════════════════════════════════════════════

class _RoseMistPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF1A0612), Color(0xFF4A1030), Color(0xFF1A0618)],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.4, radius: 0.65,
        color: const Color(0xFFD4537E).withOpacity(0.2));
    _paintRadialGlow(canvas, size,
        cx: 0.2, cy: 0.75, radius: 0.45,
        color: const Color(0xFF993556).withOpacity(0.14));

    _paintStars(canvas, size, math.Random(61), 45);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DeepOceanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF020A18), Color(0xFF052040), Color(0xFF051030)],
        stops: const [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Light shimmer lines
    final shimPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
    final rng = math.Random(71);
    for (var i = 0; i < 14; i++) {
      final y = size.height * (0.28 + i * 0.056);
      final alpha = 0.04 + i * 0.012;
      shimPaint.color = const Color(0xFF1864C8).withOpacity(alpha);
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 3) {
        path.lineTo(x, y + math.sin(x * 0.12 + i * 0.4 + rng.nextDouble()) * 3);
      }
      canvas.drawPath(path, shimPaint);
    }

    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.15, radius: 0.5,
        color: const Color(0xFF1864C8).withOpacity(0.12));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ForestNightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF040C06), Color(0xFF0A200E), Color(0xFF051008)],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _paintRadialGlow(canvas, size,
        cx: 0.5, cy: 0.18, radius: 0.7,
        color: const Color(0xFF1D9E50).withOpacity(0.1));
    _paintRadialGlow(canvas, size,
        cx: 0.3, cy: 0.8, radius: 0.45,
        color: const Color(0xFF0A5020).withOpacity(0.15));

    _paintStars(canvas, size, math.Random(83), 70, maxRadius: 1.2);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _VelvetDuskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF0D0520), Color(0xFF2D0F50),
          Color(0xFF180830), Color(0xFF0A0415),
        ],
        stops: const [0.0, 0.4, 0.78, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _paintRadialGlow(canvas, size,
        cx: 0.22, cy: 0.3, radius: 0.5,
        color: const Color(0xFFBA7517).withOpacity(0.18));
    _paintRadialGlow(canvas, size,
        cx: 0.75, cy: 0.65, radius: 0.45,
        color: const Color(0xFF534AB7).withOpacity(0.22));

    _paintStars(canvas, size, math.Random(91), 65);
  }

  @override
  bool shouldRepaint(_) => false;
}
