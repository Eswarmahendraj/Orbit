import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';
import 'meme_studio_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Trending Sounds — ranked by Drop usage count
// ─────────────────────────────────────────────────────────────────────────────

class _TrendSound {
  final String song;
  final String artist;
  final Color color;
  final String emoji;
  final int drops;
  final double change; // % change in last 24h (positive = rising)
  const _TrendSound(this.song, this.artist, this.color, this.emoji, this.drops, this.change);
}

const _trending = [
  _TrendSound('Espresso',         'Sabrina Carpenter', Color(0xFFFF6B35), '☕', 8421,  12.4),
  _TrendSound('luther',           'Kendrick & SZA',    Color(0xFF7C83FD), '💜', 6203,  8.1),
  _TrendSound('APT.',             'ROSÉ & Bruno Mars', Color(0xFFFC466B), '🪷', 5891,  5.7),
  _TrendSound('Golden Hour',      'JVKE',              Color(0xFFF7971E), '🌅', 4320,  -2.3),
  _TrendSound('Die With A Smile', 'Lady Gaga & Bruno', Color(0xFFE96C9D), '😭', 3874,  19.2),
  _TrendSound('Blinding Lights',  'The Weeknd',        Color(0xFFFF0080), '⚡', 3102,  1.4),
  _TrendSound('good 4 u',         'Olivia Rodrigo',    Color(0xFF43E97B), '🔪', 2944,  -0.8),
  _TrendSound('As It Was',        'Harry Styles',      Color(0xFF4FACFE), '🌊', 2711,  3.6),
  _TrendSound('Heat Waves',       'Glass Animals',     Color(0xFF56CCF2), '🌊', 2403,  -4.1),
  _TrendSound('Dynamite',         'BTS',               Color(0xFFFF6B6B), '💥', 2187,  22.9),
  _TrendSound('Levitating',       'Dua Lipa',          Color(0xFFB24AFF), '🪐', 1934,  6.3),
  _TrendSound('Stay',             'Kid LAROI & Bieber',Color(0xFF00F0FF), '🤍', 1721,  -1.5),
];

class TrendingSoundsScreen extends StatefulWidget {
  const TrendingSoundsScreen({super.key});

  @override
  State<TrendingSoundsScreen> createState() => _TrendingSoundsScreenState();
}

class _TrendingSoundsScreenState extends State<TrendingSoundsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  int? _hovering;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  String _fmtDrops(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFC466B), Color(0xFF7C83FD)],
          ).createShader(b),
          child: const Text('🔥 Trending Sounds',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(children: [
              const Icon(Icons.access_time_rounded,
                  size: 12, color: Colors.white54),
              const SizedBox(width: 4),
              Text('24h', style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // Top 3 podium
        _Podium(sounds: _trending.take(3).toList(), fmtDrops: _fmtDrops),
        const SizedBox(height: 4),

        // "ALL SOUNDS" label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            Text('ALL SOUNDS', style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
            const Spacer(),
            Text('${_trending.length} tracks', style: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 10)),
          ]),
        ),

        // Full ranked list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: _trending.length,
            itemBuilder: (_, i) {
              final s = _trending[i];
              final isTop3 = i < 3;
              return _SoundRow(
                rank: i + 1,
                sound: s,
                fmtDrops: _fmtDrops,
                isTop3: isTop3,
                onUse: () => _openMemeStudio(s),
                onDrop: () => _openMemeStudio(s),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _openMemeStudio(_TrendSound s) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MemeStudioScreen(
        preSelectedSong: s.song,
        preSelectedArtist: s.artist,
        preSelectedColor: s.color,
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Podium — top 3 highlighted
// ─────────────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_TrendSound> sounds;
  final String Function(int) fmtDrops;
  const _Podium({required this.sounds, required this.fmtDrops});

  @override
  Widget build(BuildContext context) {
    // order: #2, #1, #3 for visual podium effect
    final order = [sounds[1], sounds[0], sounds[2]];
    final heights = [90.0, 116.0, 80.0];
    final ranks = ['2', '1', '3'];
    final crowns = ['🥈', '🥇', '🥉'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final s = order[i];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: i == 1 ? 6 : 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(crowns[i], style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(s.emoji, style: TextStyle(fontSize: i == 1 ? 24 : 18)),
                  const SizedBox(height: 6),
                  Text(s.song,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: i == 1 ? 12 : 11)),
                  const SizedBox(height: 2),
                  Text('${fmtDrops(s.drops)} drops',
                      style: TextStyle(color: s.color, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    height: heights[i],
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [s.color.withOpacity(0.3), s.color.withOpacity(0.1)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border.all(color: s.color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(ranks[i],
                          style: TextStyle(
                              color: s.color,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single row in the full ranked list
// ─────────────────────────────────────────────────────────────────────────────

class _SoundRow extends StatefulWidget {
  final int rank;
  final _TrendSound sound;
  final String Function(int) fmtDrops;
  final bool isTop3;
  final VoidCallback onUse;
  final VoidCallback onDrop;

  const _SoundRow({
    required this.rank,
    required this.sound,
    required this.fmtDrops,
    required this.isTop3,
    required this.onUse,
    required this.onDrop,
  });

  @override
  State<_SoundRow> createState() => _SoundRowState();
}

class _SoundRowState extends State<_SoundRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;
    final rising = s.change > 0;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _expanded
              ? s.color.withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? s.color.withOpacity(0.25)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Rank
              SizedBox(
                width: 26,
                child: Text('#${widget.rank}',
                    style: TextStyle(
                        color: widget.isTop3 ? s.color : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              // Color disc + emoji
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [s.color.withOpacity(0.35), s.color.withOpacity(0.1)],
                  ),
                  border: Border.all(color: s.color.withOpacity(0.4)),
                ),
                child: Center(child: Text(s.emoji,
                    style: const TextStyle(fontSize: 19))),
              ),
              const SizedBox(width: 12),
              // Name + artist
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.song,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(s.artist,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              const SizedBox(width: 8),
              // Stats + trend
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  Text(widget.fmtDrops(s.drops),
                      style: TextStyle(
                          color: s.color, fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('💧', style: const TextStyle(fontSize: 11)),
                ]),
                Row(children: [
                  Icon(
                    rising
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 12,
                    color: rising ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${rising ? '+' : ''}${s.change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: rising ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ]),
              const SizedBox(width: 8),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.white24, size: 18,
              ),
            ]),
          ),

          // Expanded action strip
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                // Use for Meme
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onUse,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [s.color, s.color.withOpacity(0.7)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(
                            color: s.color.withOpacity(0.3), blurRadius: 10)],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎭', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text('Make Meme',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Use for Drop
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDrop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: s.color.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💧', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text('Post Drop',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ]),
      ),
    );
  }
}
