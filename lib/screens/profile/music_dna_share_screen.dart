import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ── Genre data model ──────────────────────────────────────────────────────────
class _Genre {
  final String name;
  final double score; // 0..1
  final Color color;
  const _Genre(this.name, this.score, this.color);
}

class MusicDnaShareScreen extends StatefulWidget {
  const MusicDnaShareScreen({super.key});

  @override
  State<MusicDnaShareScreen> createState() => _MusicDnaShareScreenState();
}

class _MusicDnaShareScreenState extends State<MusicDnaShareScreen>
    with TickerProviderStateMixin {
  late AnimationController _aura;
  late AnimationController _pulse;
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  final _state = OrbitState();

  // Demo DNA — in production, pull from Spotify/Apple Music stats
  static const _genres = [
    _Genre('Indie',    0.82, Color(0xFF7C3AED)),
    _Genre('Lo-fi',    0.68, Color(0xFF22D3EE)),
    _Genre('Alt R&B',  0.55, Color(0xFFEC4899)),
    _Genre('Indie Pop',0.73, Color(0xFFFF6B00)),
    _Genre('Ambient',  0.44, Color(0xFF10B981)),
    _Genre('Hip-Hop',  0.60, Color(0xFFE879F9)),
  ];

  static const _vibeLabel = 'bedroom pop dreamer';
  static const _topTrack  = 'Golden Hour — JVKE';
  static const _topArtist = 'Phoebe Bridgers';

  @override
  void initState() {
    super.initState();
    _aura  = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _aura.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Capture card as PNG and share ─────────────────────────────────────────
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/aura_music_dna.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'my music dna on AURA 🎧 ${_state.username}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: const Text('music dna',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(_sharing ? 'saving…' : 'share'),
            style: TextButton.styleFrom(
              foregroundColor: AuraTheme.accent,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── Story-format card (9:16 ratio) ─────────────────────
          RepaintBoundary(
            key: _cardKey,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: _DnaCard(
                aura: _aura,
                pulse: _pulse,
                genres: _genres,
                username: _state.username,
                vibeLabel: _vibeLabel,
                topTrack: _topTrack,
                topArtist: _topArtist,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Hint ───────────────────────────────────────────────
          Text(
            'share to Instagram Stories, TikTok, or anywhere 🌍',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          // ── Genre breakdown ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AuraTheme.purple.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('genre breakdown',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3)),
                const SizedBox(height: 14),
                ..._genres.map((g) => _GenreBar(genre: g)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── The card itself (exported as PNG) ────────────────────────────────────────
class _DnaCard extends StatelessWidget {
  final AnimationController aura;
  final AnimationController pulse;
  final List<_Genre> genres;
  final String username;
  final String vibeLabel;
  final String topTrack;
  final String topArtist;

  const _DnaCard({
    required this.aura,
    required this.pulse,
    required this.genres,
    required this.username,
    required this.vibeLabel,
    required this.topTrack,
    required this.topArtist,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D1A), Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // ── Animated radial glow ─────────────────────────────
          AnimatedBuilder(
            animation: aura,
            builder: (_, __) => CustomPaint(
              painter: _GlowPainter(aura.value),
            ),
          ),
          // ── Content ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AURA branding
                Row(children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AuraTheme.purple, AuraTheme.cyan],
                    ).createShader(b),
                    child: const Text('AURA',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 4)),
                  ),
                  const Spacer(),
                  Text(username,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Text('my music dna',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        letterSpacing: 2)),
                const SizedBox(height: 24),
                // Radar chart
                Expanded(
                  flex: 5,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: aura,
                      builder: (_, __) => CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _RadarPainter(genres, aura.value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Vibe label
                AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AuraTheme.purple
                          .withOpacity(0.12 + pulse.value * 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AuraTheme.purple.withOpacity(
                              0.35 + pulse.value * 0.2),
                          width: 1.5),
                    ),
                    child: Text(
                      '✦ $vibeLabel',
                      style: const TextStyle(
                          color: AuraTheme.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(children: [
                  _StatChip(label: 'top track',   value: topTrack,  color: AuraTheme.cyan),
                  const SizedBox(width: 8),
                  _StatChip(label: 'top artist', value: topArtist, color: AuraTheme.accent),
                ]),
                const SizedBox(height: 20),
                // Genre pills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: genres.map((g) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: g.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: g.color.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${g.name}  ${(g.score * 100).round()}%',
                      style: TextStyle(
                          color: g.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              maxLines: 2),
        ]),
      ),
    );
  }
}

// ── Genre bar in bottom breakdown ─────────────────────────────────────────────
class _GenreBar extends StatelessWidget {
  final _Genre genre;
  const _GenreBar({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(genre.name,
              style: TextStyle(
                  color: genre.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const Spacer(),
          Text('${(genre.score * 100).round()}%',
              style: TextStyle(
                  color: genre.color.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: genre.score,
            minHeight: 6,
            backgroundColor: genre.color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(genre.color),
          ),
        ),
      ]),
    );
  }
}

// ── Radar chart painter ───────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<_Genre> genres;
  final double aura; // 0..1 animation tick

  const _RadarPainter(this.genres, this.aura);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 16;
    final n  = genres.length;

    // ── Grid rings ───────────────────────────────────────────
    for (int ring = 1; ring <= 5; ring++) {
      final rr = r * ring / 5;
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi * i / n) - math.pi / 2;
        final px = cx + rr * math.cos(angle);
        final py = cy + rr * math.sin(angle);
        i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // ── Spoke lines ──────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..strokeWidth = 1,
      );
    }

    // ── Animated data polygon ────────────────────────────────
    final glowPaint = Paint()
      ..color = AuraTheme.purple.withOpacity(0.12 + math.sin(aura * 2 * math.pi) * 0.06)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AuraTheme.purple.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final val   = genres[i].score * r;
      final px    = cx + val * math.cos(angle);
      final py    = cy + val * math.sin(angle);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, borderPaint);

    // ── Colored vertex dots + labels ─────────────────────────
    for (int i = 0; i < n; i++) {
      final angle  = (2 * math.pi * i / n) - math.pi / 2;
      final val    = genres[i].score * r;
      final px     = cx + val * math.cos(angle);
      final py     = cy + val * math.sin(angle);

      canvas.drawCircle(Offset(px, py), 5, Paint()..color = genres[i].color);
      canvas.drawCircle(Offset(px, py), 3,
          Paint()..color = Colors.white.withOpacity(0.9));

      // Labels at spoke tip
      final lx = cx + (r + 18) * math.cos(angle);
      final ly = cy + (r + 18) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: genres[i].name,
          style: TextStyle(
            color: genres[i].color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.aura != aura || old.genres != genres;
}

// ── Background glow painter ───────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double t;
  const _GlowPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;
    final r  = size.width * 0.55 +
        math.sin(t * 2 * math.pi) * size.width * 0.06;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          r,
          [
            AuraTheme.purple.withOpacity(0.22),
            AuraTheme.cyan.withOpacity(0.08),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}
