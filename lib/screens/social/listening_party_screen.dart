import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../../widgets/now_playing_bar.dart';

// ── Track model ───────────────────────────────────────────────────────────────
class _Track {
  final String title;
  final String artist;
  final Color color;
  const _Track(this.title, this.artist, this.color);
}

// ── Party member model ────────────────────────────────────────────────────────
class _Member {
  final String handle;
  final String emoji;
  final Color color;
  String reaction; // live emoji reaction
  bool isHost;
  _Member(this.handle, this.emoji, this.color,
      {this.reaction = '', this.isHost = false});
}

class ListeningPartyScreen extends StatefulWidget {
  const ListeningPartyScreen({super.key});

  @override
  State<ListeningPartyScreen> createState() => _ListeningPartyScreenState();
}

class _ListeningPartyScreenState extends State<ListeningPartyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _wave;
  late AnimationController _ring;

  final _state = OrbitState();
  bool _playing  = true;
  int  _trackIdx = 0;
  Duration _pos  = const Duration(seconds: 38);
  Timer? _ticker;

  static const _queue = [
    _Track('Golden Hour',         'JVKE',            Color(0xFFFF9A3C)),
    _Track('Espresso',            'Sabrina Carpenter',Color(0xFFFF6B6B)),
    _Track('Luther',              'Kendrick Lamar',  Color(0xFF7C83FD)),
    _Track('APT.',                'ROSÉ & Bruno Mars',Color(0xFF43E97B)),
    _Track('Die With A Smile',    'Lady Gaga',       Color(0xFFFAD961)),
  ];

  static const _totalDuration = Duration(minutes: 3, seconds: 20);
  static const _roomCode = 'AURA-7X4K';

  late List<_Member> _members;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _wave  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _ring  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _startTicker();

    _members = [
      _Member('you', '🎧', AuraTheme.accent, isHost: true),
      _Member('@maya.k', '🌸', const Color(0xFFFF6B6B)),
      _Member('@zara.w', '🌙', const Color(0xFF7C83FD)),
      _Member('@dev.s', '🔥', const Color(0xFF43E97B)),
    ];
  }

  @override
  void dispose() {
    _pulse.dispose();
    _wave.dispose();
    _ring.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_playing) return;
      setState(() {
        _pos += const Duration(seconds: 1);
        if (_pos >= _totalDuration) {
          _pos = Duration.zero;
          _trackIdx = (_trackIdx + 1) % _queue.length;
        }
      });
    });
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() => _playing = !_playing);
  }

  void _nextTrack() {
    HapticFeedback.selectionClick();
    setState(() {
      _trackIdx = (_trackIdx + 1) % _queue.length;
      _pos = Duration.zero;
    });
  }

  void _react(String emoji) {
    HapticFeedback.lightImpact();
    setState(() => _members[0].reaction = emoji);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _members[0].reaction = '');
    });
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final track = _queue[_trackIdx];
    final progress = _pos.inMilliseconds / _totalDuration.inMilliseconds;

    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(children: [
        // ── Animated bg ───────────────────────────────────────────
        AnimatedBuilder(
          animation: _ring,
          builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _RingBgPainter(track.color, _ring.value)),
        ),
        SafeArea(
          child: Column(children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context)),
                const Spacer(),
                // Room code chip
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        const ClipboardData(text: _roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Room code copied!'),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: track.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: track.color.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.link_rounded,
                          color: track.color, size: 13),
                      const SizedBox(width: 5),
                      Text(_roomCode,
                          style: TextStyle(
                              color: track.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1)),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Album art ────────────────────────────────────────
            const Spacer(),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Container(
                    width: 220 + _pulse.value * 20,
                    height: 220 + _pulse.value * 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: track.color.withOpacity(
                          0.06 * (1 - _pulse.value)),
                    ),
                  ),
                  Container(
                    width: 180 + _pulse.value * 10,
                    height: 180 + _pulse.value * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: track.color.withOpacity(0.10),
                      border: Border.all(
                          color: track.color.withOpacity(0.35),
                          width: 1.5),
                    ),
                  ),
                  // Art placeholder
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        track.color.withOpacity(0.5),
                        track.color.withOpacity(0.2),
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: track.color.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.music_note_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 56),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Track info + waveform ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                Text(track.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(track.artist,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.55)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 14),
                // Waveform
                SizedBox(
                  height: 28,
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) {
                      final phases = List.generate(
                          20, (i) => i * math.pi / 6);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(20, (i) {
                          final h = _playing
                              ? (math.sin(_wave.value * 2 * math.pi +
                                              phases[i]) *
                                          0.5 +
                                      0.5) *
                                      20 +
                                  4
                              : 4.0;
                          return Container(
                            width: 3,
                            height: h,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: i < (progress * 20)
                                  ? track.color
                                  : track.color.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 10),

            // ── Progress bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                SliderTheme(
                  data: SliderThemeData(
                    thumbColor: track.color,
                    activeTrackColor: track.color,
                    inactiveTrackColor:
                        track.color.withOpacity(0.18),
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) => setState(() =>
                        _pos = Duration(
                            milliseconds:
                                (v * _totalDuration.inMilliseconds)
                                    .round())),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_pos),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4))),
                    Text(_fmt(_totalDuration),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Controls ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 36,
                    color: Colors.white54,
                    onPressed: () => setState(() {
                      _trackIdx =
                          (_trackIdx - 1 + _queue.length) % _queue.length;
                      _pos = Duration.zero;
                    }),
                  ),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: track.color,
                          boxShadow: [
                            BoxShadow(
                                color: track.color.withOpacity(0.5),
                                blurRadius: 20)
                          ]),
                      child: Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 36,
                    color: Colors.white54,
                    onPressed: _nextTrack,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Reaction strip ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['🔥', '💜', '😭', '🤯', '❤️'].map((e) =>
                GestureDetector(
                  onTap: () => _react(e),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 20))),
                  ),
                )
              ).toList(),
            ),

            const SizedBox(height: 20),

            // ── Members strip ─────────────────────────────────────
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final m = _members[i];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(alignment: Alignment.topRight, children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m.color.withOpacity(0.18),
                              border: Border.all(
                                  color: m.color.withOpacity(
                                      0.4 + _pulse.value * 0.3),
                                  width: 1.5),
                            ),
                            child: Center(
                                child: Text(m.emoji,
                                    style: const TextStyle(
                                        fontSize: 20))),
                          ),
                        ),
                        if (m.reaction.isNotEmpty)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54),
                            child: Center(
                                child: Text(m.reaction,
                                    style:
                                        const TextStyle(fontSize: 11))),
                          ),
                        if (m.isHost)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: track.color,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        m.isHost ? 'you' : m.handle.substring(1),
                        style: TextStyle(
                            color: m.isHost
                                ? track.color
                                : Colors.white38,
                            fontSize: 9,
                            fontWeight: m.isHost
                                ? FontWeight.w700
                                : FontWeight.w500),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────
class _RingBgPainter extends CustomPainter {
  final Color color;
  final double t;
  const _RingBgPainter(this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AuraTheme.background);
    for (int i = 1; i <= 4; i++) {
      final r = size.width * 0.35 * i +
          math.sin(t * 2 * math.pi + i) * 20;
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.38),
        r,
        Paint()
          ..color = color.withOpacity(0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_RingBgPainter old) =>
      old.t != t || old.color != color;
}
