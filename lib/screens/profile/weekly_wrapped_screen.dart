import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ── Weekly stats model ────────────────────────────────────────────────────────
class WeeklyStats {
  final String topTrack;
  final String topArtist;
  final String topGenre;
  final String topMood;
  final String topMoodEmoji;
  final int minutesListened;
  final int songsDiscovered;
  final int streakDays;
  final List<int> dailyMinutes; // 7 days Mon-Sun

  const WeeklyStats({
    required this.topTrack,
    required this.topArtist,
    required this.topGenre,
    required this.topMood,
    required this.topMoodEmoji,
    required this.minutesListened,
    required this.songsDiscovered,
    required this.streakDays,
    required this.dailyMinutes,
  });

  // Mock data — replace with real Spotify/Apple Music stats
  static final demo = WeeklyStats(
    topTrack: 'Golden Hour',
    topArtist: 'Phoebe Bridgers',
    topGenre: 'Indie Folk',
    topMood: 'nostalgic',
    topMoodEmoji: '🌙',
    minutesListened: 347,
    songsDiscovered: 18,
    streakDays: 6,
    dailyMinutes: [28, 55, 42, 38, 72, 64, 48],
  );
}

class WeeklyWrappedScreen extends StatefulWidget {
  const WeeklyWrappedScreen({super.key});

  @override
  State<WeeklyWrappedScreen> createState() => _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends State<WeeklyWrappedScreen>
    with TickerProviderStateMixin {
  late AnimationController _bars;
  late AnimationController _glow;
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;
  final _state = OrbitState();
  final _stats = WeeklyStats.demo;

  @override
  void initState() {
    super.initState();
    _bars = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _glow = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bars.dispose();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = bytes!.buffer.asUint8List();
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/aura_weekly_wrapped.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'my week in music on AURA 🎧 ${_state.username}');
    } catch (_) {}
    if (mounted) setState(() => _sharing = false);
  }

  String get _weekLabel {
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[mon.month - 1]} ${mon.day} – ${months[sun.month - 1]} ${sun.day}';
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
            onPressed: () => Navigator.pop(context)),
        title: const Text('weekly wrapped',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(_sharing ? 'saving…' : 'share'),
            style: TextButton.styleFrom(
              foregroundColor: AuraTheme.accent,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── Shareable card ─────────────────────────────────────
          RepaintBoundary(
            key: _cardKey,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: _WrappedCard(
                stats: _stats,
                username: _state.username,
                weekLabel: _weekLabel,
                barsAnim: _bars,
                glowAnim: _glow,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Daily bars breakdown ───────────────────────────────
          _DailyChart(stats: _stats, anim: _bars),
          const SizedBox(height: 16),
          // ── Stat tiles ─────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatTile('🎵', 'minutes', '${_stats.minutesListened}',
                  AuraTheme.accent),
              _StatTile('🔭', 'discovered', '${_stats.songsDiscovered} songs',
                  AuraTheme.cyan),
              _StatTile('🔥', 'streak', '${_stats.streakDays} days',
                  AuraTheme.purple),
              _StatTile(_stats.topMoodEmoji, 'top mood',
                  _stats.topMood, const Color(0xFFEC4899)),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── The shareable card ────────────────────────────────────────────────────────
class _WrappedCard extends StatelessWidget {
  final WeeklyStats stats;
  final String username;
  final String weekLabel;
  final AnimationController barsAnim;
  final AnimationController glowAnim;

  const _WrappedCard({
    required this.stats,
    required this.username,
    required this.weekLabel,
    required this.barsAnim,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D1A), Color(0xFF180A2E),
                         Color(0xFF0A180E)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Glow blobs
          AnimatedBuilder(
            animation: glowAnim,
            builder: (_, __) => CustomPaint(
                painter: _GlowBlobPainter(glowAnim.value)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AuraTheme.accent, AuraTheme.purple],
                    ).createShader(b),
                    child: const Text('AURA',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 4)),
                  ),
                  const Spacer(),
                  Text(username,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                Text('weekly wrapped',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        letterSpacing: 1.5)),
                Text(weekLabel,
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                // Big minute count
                AnimatedBuilder(
                  animation: barsAnim,
                  builder: (_, __) => ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AuraTheme.accent, AuraTheme.purple],
                    ).createShader(b),
                    child: Text(
                      '${(stats.minutesListened * barsAnim.value).round()}',
                      style: const TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1),
                    ),
                  ),
                ),
                Text(
                  'minutes of music this week',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13),
                ),
                const SizedBox(height: 20),
                // Mini daily bars
                SizedBox(
                  height: 48,
                  child: AnimatedBuilder(
                    animation: barsAnim,
                    builder: (_, __) {
                      final maxM = stats.dailyMinutes
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble();
                      final days = ['M','T','W','T','F','S','S'];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final h = (stats.dailyMinutes[i] / maxM) *
                              48 * barsAnim.value;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: Duration.zero,
                                        width: double.infinity,
                                        height: h,
                                        decoration: BoxDecoration(
                                          color: i == 4
                                              ? AuraTheme.accent
                                              : AuraTheme.purple
                                                  .withOpacity(0.55),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Top track + artist
                Row(children: [
                  Expanded(
                    child: _MiniStat(
                        label: 'top track',
                        value: stats.topTrack,
                        color: AuraTheme.cyan),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                        label: 'top artist',
                        value: stats.topArtist,
                        color: AuraTheme.purple),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _MiniStat(
                        label: 'top genre',
                        value: stats.topGenre,
                        color: AuraTheme.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                        label: 'top mood',
                        value:
                            '${stats.topMoodEmoji} ${stats.topMood}',
                        color: const Color(0xFFEC4899)),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              maxLines: 1),
        ]),
      );
}

// ── Daily bar chart ───────────────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  final WeeklyStats stats;
  final AnimationController anim;
  const _DailyChart({required this.stats, required this.anim});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxM = stats.dailyMinutes.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
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
          const Text('daily listening',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3)),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final h = (stats.dailyMinutes[i] / maxM) * 80 * anim.value;
                  final isToday = i == DateTime.now().weekday - 1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${stats.dailyMinutes[i]}m',
                              style: TextStyle(
                                  color: isToday
                                      ? AuraTheme.accent
                                      : Colors.white30,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AuraTheme.accent
                                  : AuraTheme.purple.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(days[i].substring(0, 2),
                              style: TextStyle(
                                  color: isToday
                                      ? AuraTheme.accent
                                      : Colors.white38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _StatTile(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      );
}

// ── Glow blob painter ─────────────────────────────────────────────────────────
class _GlowBlobPainter extends CustomPainter {
  final double t;
  const _GlowBlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      [size.width * 0.8, size.height * 0.2, AuraTheme.accent],
      [size.width * 0.2, size.height * 0.7, AuraTheme.purple],
      [size.width * 0.6, size.height * 0.85, AuraTheme.cyan],
    ];
    for (final b in blobs) {
      final cx = b[0] as double;
      final cy = b[1] as double;
      final color = b[2] as Color;
      final r = size.width * 0.35 +
          math.sin(t * 2 * math.pi) * 20;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            r,
            [color.withOpacity(0.15), Colors.transparent],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowBlobPainter old) => old.t != t;
}
