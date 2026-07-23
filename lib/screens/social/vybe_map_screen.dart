import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Friend location data
// ─────────────────────────────────────────────────────────────────────────────

class _Friend {
  final String handle;
  final String emoji;
  final String song;
  final String city;
  final Color color;
  final double lat;
  final double lon;

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
  final _mapController = MapController();
  _Friend? _selected;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanLine = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scanLine.dispose();
    super.dispose();
  }

  // Generate N intermediate lat/lon points for the connection arc
  List<LatLng> _arcPoints(LatLng from, LatLng to) {
    const steps = 48;
    return List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060614),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060614),
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [AuraTheme.accent, Color(0xFFFF8C42), AuraTheme.accent],
          ).createShader(r),
          child: const Text(
            'VYBE_MAP',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AuraTheme.accent, Color(0xFFFF8C42)],
            ).createShader(r),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _centerOnMe,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [AuraTheme.accent, Color(0xFFFF8C42)],
                ).createShader(r),
                child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AuraTheme.accent, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: Column(children: [
        // ── Legend chips ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            GestureDetector(
              onTap: _showFriendsVibingSheet,
              child: _chip('🎵 ${_friends.length} friends vibing', tappable: true),
            ),
            const SizedBox(width: 8),
            _chip('🌍 pinch to zoom · drag to explore'),
            const Spacer(),
          ]),
        ),

        // ── World map (CartoDB dark matter tiles) ──────────────────
        Expanded(
          child: Stack(
            children: [
              // flutter_map — real tile-based world map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: const LatLng(20, 10),
                  zoom: 2.2,
                  minZoom: 1.2,
                  maxZoom: 8.0,
                  backgroundColor: const Color(0xFF060A1A),
                  onTap: (_, __) {
                    if (_selected != null) setState(() => _selected = null);
                  },
                ),
                children: [
                  // ── Dark Matter tile layer (no API key required) ──
                  TileLayer(
                    urlTemplate:
                        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_matter/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.aura',
                    backgroundColor: const Color(0xFF060A1A),
                    maxZoom: 8,
                  ),

                  // ── Connection arc (YOU → selected friend) ────────
                  if (_selected != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _arcPoints(
                            const LatLng(_youLat, _youLon),
                            LatLng(_selected!.lat, _selected!.lon),
                          ),
                          color: _selected!.color.withOpacity(0.25),
                          strokeWidth: 1.8,
                        ),
                      ],
                    ),

                  // ── Animated dot traveling the arc ────────────────
                  if (_selected != null)
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) {
                        final head = (_pulse.value * 1.4).clamp(0.0, 1.0);
                        final sel = _selected;
                        if (sel == null) return const SizedBox.shrink();
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _youLat + (sel.lat - _youLat) * head,
                                _youLon + (sel.lon - _youLon) * head,
                              ),
                              width: 14,
                              height: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel.color,
                                  boxShadow: [
                                    BoxShadow(
                                      color: sel.color.withOpacity(0.7),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // ── Friend + YOU pins ─────────────────────────────
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => MarkerLayer(
                      markers: [
                        // YOU pin
                        Marker(
                          point: const LatLng(_youLat, _youLon),
                          width: 44,
                          height: 44,
                          child: _YouPin(pulse: _pulse.value),
                        ),
                        // Friend pins
                        ..._friends.map(
                          (f) => Marker(
                            point: LatLng(f.lat, f.lon),
                            width: _selected == f ? 58 : 44,
                            height: _selected == f ? 62 : 44,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selected = _selected == f ? null : f),
                              child: _FriendPin(
                                friend: f,
                                selected: _selected == f,
                                pulse: _pulse.value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Scan-line HUD overlay ──────────────────────────────
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _scanLine,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _ScanLinePainter(progress: _scanLine.value),
                  ),
                ),
              ),

              // ── HUD corner brackets ────────────────────────────────
              const IgnorePointer(child: _HudCorners()),

              // ── HUD coordinates readout ────────────────────────────
              Positioned(
                bottom: 10,
                left: 14,
                child: Text(
                  'LAT: 12.97°N  ·  LON: 77.59°E  ·  ● SIGNAL ACTIVE',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 7,
                    color: AuraTheme.accent.withOpacity(0.55),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
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

  Widget _chip(String text, {bool tappable = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tappable
              ? AuraTheme.accent.withOpacity(0.18)
              : AuraTheme.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.accent.withOpacity(tappable ? 0.5 : 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text,
              style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: AuraTheme.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          if (tappable) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_right_rounded,
                color: AuraTheme.accent, size: 13),
          ],
        ]),
      );

  void _showFriendsVibingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1030),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('${_friends.length} friends vibing globally 🌍',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 4),
              const Text('tap a friend to see their pin',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _friends.length,
                  itemBuilder: (_, i) {
                    final f = _friends[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: f.color.withOpacity(0.2),
                          border: Border.all(
                              color: f.color.withOpacity(0.5)),
                        ),
                        child: Center(
                            child: Text(f.emoji,
                                style: const TextStyle(fontSize: 20))),
                      ),
                      title: Text(f.handle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      subtitle: Row(children: [
                        const Icon(Icons.music_note_rounded,
                            color: AuraTheme.accent, size: 11),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(f.song,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                                overflow: TextOverflow.ellipsis)),
                      ]),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white38, size: 13),
                            const SizedBox(width: 2),
                            Text(f.city,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ]),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selected = f);
                        _mapController.move(LatLng(f.lat, f.lon), 4.0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(_Friend f) => Container(
        key: ValueKey(f.handle),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: f.color.withOpacity(0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: f.color.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[SIGNAL_LOCK // ${f.city.toUpperCase()}]',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 7,
                color: f.color.withOpacity(0.7),
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: f.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: f.color.withOpacity(0.5), width: 1.5)),
                child: Center(
                    child:
                        Text(f.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.handle,
                        style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: f.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.music_note_rounded,
                            color: AuraTheme.accent, size: 11),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            f.song,
                            style: TextStyle(
                                fontFamily: 'SpaceMono',
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ]),
              ),
              GestureDetector(
                onTap: () => setState(() => _selected = null),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5), size: 14),
                ),
              ),
            ]),
          ],
        ),
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
              onTap: () {
                setState(() => _selected = f);
                _mapController.move(LatLng(f.lat, f.lon), 4.0);
              },
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
    _mapController.move(const LatLng(_youLat, _youLon), 5.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend pin widget
// ─────────────────────────────────────────────────────────────────────────────

class _FriendPin extends StatelessWidget {
  final _Friend friend;
  final bool selected;
  final double pulse; // 0..1

  const _FriendPin({
    required this.friend,
    required this.selected,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final ring = (math.sin(pulse * 2 * math.pi) * 0.5 + 0.5) * 18 + 8;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: friend.color.withOpacity(0.22),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 36 : 30,
              height: selected ? 36 : 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? friend.color : friend.color.withOpacity(0.85),
                border: selected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: friend.color.withOpacity(selected ? 0.7 : 0.4),
                    blurRadius: selected ? 14 : 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(friend.emoji,
                    style: TextStyle(fontSize: selected ? 16 : 13)),
              ),
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: friend.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  friend.handle.substring(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YOU pin widget
// ─────────────────────────────────────────────────────────────────────────────

class _YouPin extends StatelessWidget {
  final double pulse;
  const _YouPin({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final ring =
        (math.sin((pulse + 0.5) * 2 * math.pi) * 0.5 + 0.5) * 24 + 10;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: ring,
          height: ring,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuraTheme.accent.withOpacity(0.25),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AuraTheme.accent,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AuraTheme.accent.withOpacity(0.7), blurRadius: 10)
            ],
          ),
          child: const Center(
            child: Text('YOU',
                style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: Colors.white,
                    fontSize: 5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan-line painter — HUD overlay drawn on top of the tile map
// ─────────────────────────────────────────────────────────────────────────────

class _ScanLinePainter extends CustomPainter {
  final double progress;
  const _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final scanY = size.height * progress;
    // Soft glow band
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 50, size.width, 100),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AuraTheme.accent.withOpacity(0.05),
            AuraTheme.accent.withOpacity(0.12),
            AuraTheme.accent.withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0, 0.3, 0.5, 0.7, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, scanY - 50, size.width, 100)),
    );
    // Sharp leading edge
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = AuraTheme.accent.withOpacity(0.38)
        ..strokeWidth = 1.0,
    );
    // Secondary trailing edge
    canvas.drawLine(
      Offset(0, scanY - 6),
      Offset(size.width, scanY - 6),
      Paint()
        ..color = AuraTheme.accent.withOpacity(0.12)
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// HUD corner brackets
// ─────────────────────────────────────────────────────────────────────────────

class _HudCorners extends StatelessWidget {
  const _HudCorners();

  Widget _corner() => CustomPaint(
        size: const Size(22, 22),
        painter: _CornerPainter(),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _corner(),
              Transform.scale(scaleX: -1, child: _corner()),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Transform.scale(scaleY: -1, child: _corner()),
              Transform.scale(scaleX: -1, scaleY: -1, child: _corner()),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const len = 18.0;
    final paint = Paint()
      ..color = AuraTheme.accent.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawCircle(
        Offset.zero, 2.5, Paint()..color = AuraTheme.accent.withOpacity(0.9));
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}
