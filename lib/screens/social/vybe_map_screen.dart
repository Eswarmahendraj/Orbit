import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Friend location data
// ─────────────────────────────────────────────────────────────────────────────

class _Friend {
  final String handle;
  final String emoji;   // mood emoji / bitmoji stand-in
  final String song;
  final String city;
  final Color color;
  final double lat;  // -90 to 90
  final double lon;  // -180 to 180

  const _Friend({
    required this.handle,
    required this.emoji,
    required this.song,
    required this.city,
    required this.color,
    required this.lat,
    required this.lon,
  });
}

const _friends = [
  _Friend(handle: '@maya.k',  emoji: '🎧', song: 'Espresso',          city: 'New York',  color: Color(0xFFFF6B6B), lat: 40.7,  lon: -74.0),
  _Friend(handle: '@zara.w',  emoji: '🌙', song: 'luther',            city: 'London',    color: Color(0xFF7C83FD), lat: 51.5,  lon: -0.1),
  _Friend(handle: '@dev.s',   emoji: '🔥', song: 'APT.',              city: 'Mumbai',    color: Color(0xFF43E97B), lat: 19.1,  lon: 72.9),
  _Friend(handle: '@rina.p',  emoji: '✨', song: 'Golden Hour',       city: 'Seoul',     color: Color(0xFFFAD961), lat: 37.6,  lon: 126.9),
  _Friend(handle: '@jay.r',   emoji: '☀️', song: 'Die With A Smile',  city: 'Sydney',    color: Color(0xFF11998E), lat: -33.9, lon: 151.2),
  _Friend(handle: '@sam.w',   emoji: '🎸', song: 'Blinding Lights',   city: 'LA',        color: Color(0xFFFC6076), lat: 34.1,  lon: -118.2),
  _Friend(handle: '@leo.k',   emoji: '💜', song: 'Peaches',           city: 'Paris',     color: Color(0xFFA18CD1), lat: 48.9,  lon: 2.3),
  _Friend(handle: '@ari.c',   emoji: '🌊', song: 'Levitating',        city: 'Toronto',   color: Color(0xFF4FACFE), lat: 43.7,  lon: -79.4),
  _Friend(handle: '@mia.t',   emoji: '🌸', song: 'STAY',              city: 'Tokyo',     color: Color(0xFFF77062), lat: 35.7,  lon: 139.7),
  _Friend(handle: '@kai.r',   emoji: '⚡', song: 'As It Was',         city: 'Berlin',    color: Color(0xFF667EEA), lat: 52.5,  lon: 13.4),
];

// "You" — Bangalore, India
const _youLat = 12.97;
const _youLon = 77.59;

// ─────────────────────────────────────────────────────────────────────────────
// VybeMapScreen
// ─────────────────────────────────────────────────────────────────────────────

class VybeMapScreen extends StatefulWidget {
  const VybeMapScreen({super.key});
  @override
  State<VybeMapScreen> createState() => _VybeMapScreenState();
}

class _VybeMapScreenState extends State<VybeMapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _scanLine;
  _Friend? _selected;
  final TransformationController _xform = TransformationController();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanLine = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    // Start slightly zoomed in on user location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final mapH = size.height * 0.78;
      final mapW = size.width;
      final (ux, uy) = _latLonToXY(_youLat, _youLon, mapW, mapH);
      final cx = mapW / 2 - ux * 1.4;
      final cy = mapH / 2 - uy * 1.4;
      _xform.value = Matrix4.identity()
        ..scale(1.4)
        ..translate(cx / 1.4, cy / 1.4);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scanLine.dispose();
    _xform.dispose();
    super.dispose();
  }

  static (double, double) _latLonToXY(
      double lat, double lon, double w, double h) {
    // Mercator-ish projection
    final x = (lon + 180) / 360 * w;
    final latRad = lat * math.pi / 180;
    final mercN = math.log(math.tan(math.pi / 4 + latRad / 2));
    final y = (h / 2) - (w * mercN / (2 * math.pi));
    return (x.clamp(0, w), y.clamp(0, h));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060614),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060614),
        foregroundColor: Colors.white,
        title: const Text('vybe map 🌍',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: AuraTheme.accent),
            onPressed: _centerOnMe,
            tooltip: 'Find me',
          ),
        ],
      ),
      body: Column(children: [
        // ── Legend chip ────────────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            _chip('🎵 ${_friends.length} friends vibing'),
            const SizedBox(width: 8),
            _chip('📍 tap to explore'),
          ]),
        ),

        // ── Interactive map ────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTapDown: (_) {
              if (_selected != null) setState(() => _selected = null);
            },
            child: InteractiveViewer(
              transformationController: _xform,
              minScale: 0.5,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(200),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _scanLine]),
                builder: (_, __) => LayoutBuilder(
                  builder: (ctx, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Map canvas
                        CustomPaint(
                          size: Size(w, h),
                          painter: _WorldMapPainter(
                              scanProgress: _scanLine.value),
                        ),

                        // Friend pins
                        ..._friends.map((f) {
                          final (x, y) =
                              _latLonToXY(f.lat, f.lon, w, h);
                          final isSelected = _selected == f;
                          final ring =
                              (math.sin(_pulse.value * 2 * math.pi) *
                                          0.5 +
                                      0.5) *
                                  20 +
                                  8;
                          return Positioned(
                            left: x - 22,
                            top: y - 22,
                            child: GestureDetector(
                              onTap: () {
                                setState(() =>
                                    _selected = isSelected ? null : f);
                              },
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Pulse ring
                                      Container(
                                        width: ring,
                                        height: ring,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: f.color.withOpacity(
                                                0.2)),
                                      ),
                                      // Avatar bubble
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: isSelected ? 36 : 30,
                                        height: isSelected ? 36 : 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? f.color
                                              : f.color.withOpacity(0.85),
                                          border: isSelected
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 2.5)
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: f.color
                                                  .withOpacity(0.5),
                                              blurRadius: 8,
                                            )
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(f.emoji,
                                              style: TextStyle(
                                                  fontSize:
                                                      isSelected
                                                          ? 16
                                                          : 13)),
                                        ),
                                      ),
                                    ]),
                              ),
                            ),
                          );
                        }),

                        // "YOU" pulsing dot
                        Builder(builder: (_) {
                          final (x, y) = _latLonToXY(
                              _youLat, _youLon, w, h);
                          final youRing =
                              (math.sin(_pulse.value * 2 * math.pi +
                                              1.0) *
                                          0.5 +
                                      0.5) *
                                  24 +
                                  10;
                          return Positioned(
                            left: x - 22,
                            top: y - 22,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Container(
                                  width: youRing,
                                  height: youRing,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AuraTheme.accent
                                          .withOpacity(0.25)),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AuraTheme.accent,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AuraTheme.accent
                                              .withOpacity(0.7),
                                          blurRadius: 10)
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text('me',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 6,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // ── Info panel ─────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _selected != null
              ? _infoCard(_selected!)
              : _friendsRow(),
        ),
      ]),
    );
  }

  Widget _chip(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AuraTheme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _infoCard(_Friend f) => Container(
        key: ValueKey(f.handle),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111128),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: f.color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: f.color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: f.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: f.color.withOpacity(0.4))),
            child: Center(
                child: Text(f.emoji,
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.handle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.music_note_rounded,
                        color: AuraTheme.accent, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(f.song,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFF7C83FD), size: 12),
                    const SizedBox(width: 4),
                    Text(f.city,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                  ]),
                ]),
          ),
          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.4), size: 20),
          ),
        ]),
      );

  Widget _friendsRow() => Container(
        key: const ValueKey('row'),
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _friends.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final f = _friends[i];
            return GestureDetector(
              onTap: () => setState(() => _selected = f),
              child: Column(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: f.color.withOpacity(0.2),
                      border: Border.all(
                          color: f.color.withOpacity(0.5), width: 1.5)),
                  child: Center(
                      child: Text(f.emoji,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(height: 4),
                Text(f.handle.substring(1),
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ]),
            );
          },
        ),
      );

  void _centerOnMe() {
    final size = MediaQuery.of(context).size;
    final mapH = size.height * 0.78;
    final mapW = size.width;
    final (ux, uy) = _latLonToXY(_youLat, _youLon, mapW, mapH);
    final cx = mapW / 2 - ux * 2.0;
    final cy = mapH / 2 - uy * 2.0;
    final target = Matrix4.identity()
      ..scale(2.0)
      ..translate(cx / 2.0, cy / 2.0);
    // Animate
    final begin = _xform.value.clone();
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Animation<Matrix4> anim = Matrix4Tween(begin: begin, end: target)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    ctrl.addListener(() => _xform.value = anim.value);
    ctrl.forward().then((_) => ctrl.dispose());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// World Map Painter (night-mode satellite-style)
// ─────────────────────────────────────────────────────────────────────────────

class _WorldMapPainter extends CustomPainter {
  final double scanProgress;
  const _WorldMapPainter({required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ocean
    final oceanPaint = Paint()..color = const Color(0xFF060A1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), oceanPaint);

    // Subtle latitude/longitude grid
    final gridPaint = Paint()
      ..color = const Color(0xFF0D1530)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 9; i++) {
      canvas.drawLine(
          Offset(w * i / 9, 0), Offset(w * i / 9, h), gridPaint);
    }
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(
          Offset(0, h * i / 6), Offset(w, h * i / 6), gridPaint);
    }

    // Equator & Prime Meridian highlights
    final eqPaint = Paint()
      ..color = const Color(0xFF1A2550).withOpacity(0.6)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, h * 0.51), Offset(w, h * 0.51), eqPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), eqPaint);

    // ── Continents ─────────────────────────────────────────────────
    void land(Path p) {
      canvas.drawPath(
          p,
          Paint()
            ..color = const Color(0xFF1B2545)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          p,
          Paint()
            ..color = const Color(0xFF2A3B6A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }

    // North America
    final na = Path();
    na.moveTo(w * 0.09, h * 0.08);
    na.lineTo(w * 0.33, h * 0.06);
    na.lineTo(w * 0.35, h * 0.14);
    na.lineTo(w * 0.30, h * 0.22);
    na.quadraticBezierTo(w * 0.28, h * 0.40, w * 0.20, h * 0.55);
    na.lineTo(w * 0.16, h * 0.62);
    na.lineTo(w * 0.12, h * 0.55);
    na.quadraticBezierTo(w * 0.06, h * 0.38, w * 0.07, h * 0.20);
    na.close();
    land(na);

    // Greenland
    final gl = Path();
    gl.addOval(Rect.fromCenter(
        center: Offset(w * 0.415, h * 0.07), width: w * 0.06, height: h * 0.10));
    land(gl);

    // South America
    final sa = Path();
    sa.moveTo(w * 0.20, h * 0.56);
    sa.quadraticBezierTo(w * 0.28, h * 0.52, w * 0.31, h * 0.60);
    sa.lineTo(w * 0.30, h * 0.74);
    sa.quadraticBezierTo(w * 0.27, h * 0.86, w * 0.24, h * 0.90);
    sa.lineTo(w * 0.20, h * 0.85);
    sa.quadraticBezierTo(w * 0.17, h * 0.72, w * 0.18, h * 0.60);
    sa.close();
    land(sa);

    // Europe
    final eu = Path();
    eu.moveTo(w * 0.445, h * 0.08);
    eu.lineTo(w * 0.545, h * 0.08);
    eu.lineTo(w * 0.555, h * 0.22);
    eu.quadraticBezierTo(w * 0.535, h * 0.30, w * 0.51, h * 0.32);
    eu.lineTo(w * 0.445, h * 0.30);
    eu.quadraticBezierTo(w * 0.430, h * 0.22, w * 0.445, h * 0.08);
    land(eu);

    // Africa
    final af = Path();
    af.moveTo(w * 0.445, h * 0.30);
    af.lineTo(w * 0.565, h * 0.28);
    af.lineTo(w * 0.585, h * 0.38);
    af.quadraticBezierTo(w * 0.585, h * 0.58, w * 0.545, h * 0.70);
    af.lineTo(w * 0.510, h * 0.78);
    af.quadraticBezierTo(w * 0.480, h * 0.78, w * 0.455, h * 0.68);
    af.quadraticBezierTo(w * 0.435, h * 0.52, w * 0.445, h * 0.30);
    land(af);

    // Middle East
    final me = Path();
    me.addOval(Rect.fromCenter(
        center: Offset(w * 0.595, h * 0.32), width: w * 0.07, height: h * 0.10));
    land(me);

    // Asia (large mass)
    final as = Path();
    as.moveTo(w * 0.550, h * 0.08);
    as.lineTo(w * 0.945, h * 0.06);
    as.lineTo(w * 0.960, h * 0.16);
    as.quadraticBezierTo(w * 0.950, h * 0.30, w * 0.900, h * 0.38);
    as.lineTo(w * 0.840, h * 0.42);
    as.quadraticBezierTo(w * 0.780, h * 0.46, w * 0.730, h * 0.42);
    as.lineTo(w * 0.680, h * 0.45);
    as.quadraticBezierTo(w * 0.640, h * 0.42, w * 0.620, h * 0.38);
    as.lineTo(w * 0.565, h * 0.32);
    as.lineTo(w * 0.550, h * 0.08);
    land(as);

    // Indian subcontinent
    final ind = Path();
    ind.moveTo(w * 0.610, h * 0.38);
    ind.lineTo(w * 0.655, h * 0.38);
    ind.quadraticBezierTo(w * 0.668, h * 0.50, w * 0.638, h * 0.56);
    ind.quadraticBezierTo(w * 0.618, h * 0.52, w * 0.610, h * 0.38);
    land(ind);

    // Southeast Asia
    final sea = Path();
    sea.moveTo(w * 0.730, h * 0.42);
    sea.lineTo(w * 0.760, h * 0.40);
    sea.lineTo(w * 0.780, h * 0.48);
    sea.lineTo(w * 0.760, h * 0.52);
    sea.lineTo(w * 0.730, h * 0.50);
    sea.close();
    land(sea);

    // Australia
    final au = Path();
    au.moveTo(w * 0.755, h * 0.59);
    au.quadraticBezierTo(w * 0.860, h * 0.56, w * 0.905, h * 0.62);
    au.quadraticBezierTo(w * 0.920, h * 0.72, w * 0.890, h * 0.78);
    au.quadraticBezierTo(w * 0.820, h * 0.82, w * 0.765, h * 0.75);
    au.quadraticBezierTo(w * 0.745, h * 0.68, w * 0.755, h * 0.59);
    land(au);

    // Japan islands
    final jp = Path();
    jp.addOval(Rect.fromCenter(
        center: Offset(w * 0.862, h * 0.245), width: w * 0.022, height: h * 0.07));
    land(jp);

    // Philippines / Indonesia (small islands)
    for (final pos in [
      [0.800, 0.480],
      [0.818, 0.510],
      [0.840, 0.530],
      [0.860, 0.500],
    ]) {
      final isPath = Path()
        ..addOval(Rect.fromCenter(
            center: Offset(w * pos[0], h * pos[1]),
            width: w * 0.016,
            height: h * 0.022));
      land(isPath);
    }

    // Antarctica hint
    final ant = Paint()
      ..color = const Color(0xFF1D2B50)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.90, w, h * 0.10), ant);

    // ── City light clusters ─────────────────────────────────────────
    final cityPaint = Paint()..style = PaintingStyle.fill;
    for (final c in [
      (0.220, 0.355, const Color(0xFFFFEE99)),  // New York
      (0.133, 0.380, const Color(0xFFFFEE99)),  // LA
      (0.472, 0.220, const Color(0xFFFFEE99)),  // London
      (0.480, 0.245, const Color(0xFFFFEE99)),  // Paris
      (0.502, 0.205, const Color(0xFFFFEE99)),  // Berlin
      (0.638, 0.400, const Color(0xFFFFEE99)),  // Mumbai
      (0.641, 0.430, const Color(0xFFFFEE99)),  // Bangalore
      (0.863, 0.248, const Color(0xFFFFEE99)),  // Tokyo
      (0.860, 0.300, const Color(0xFFFFEE99)),  // Seoul
      (0.836, 0.660, const Color(0xFFFFEE99)),  // Sydney
    ]) {
      final (cx, cy, col) = c;
      cityPaint.color = col.withOpacity(0.15);
      canvas.drawCircle(Offset(w * cx, h * cy), 5, cityPaint);
      cityPaint.color = col.withOpacity(0.6);
      canvas.drawCircle(Offset(w * cx, h * cy), 1.5, cityPaint);
    }

    // ── Scan-line effect ────────────────────────────────────────────
    final scanY = h * scanProgress;
    final scanGrad = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AuraTheme.accent.withOpacity(0.04),
          AuraTheme.accent.withOpacity(0.08),
          AuraTheme.accent.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0, 0.3, 0.5, 0.7, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanY - 30, w, 60));
    canvas.drawRect(
        Rect.fromLTWH(0, scanY - 30, w, 60), scanGrad);
  }

  @override
  bool shouldRepaint(_WorldMapPainter old) =>
      old.scanProgress != scanProgress;
}
