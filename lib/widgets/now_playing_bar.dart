import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/now_playing_service.dart';

/// Compact animated "Now Playing" bar.
/// Pass [color] to tint waveform + border to match context (profile accent,
/// friend's map color, etc.). Set [compact] = true for map / message previews.
class NowPlayingBar extends StatefulWidget {
  final String track;
  final String? artist;
  final String? artUrl;
  final Color color;
  final bool compact;   // true = single-line pill; false = full card
  final bool isPlaying;
  final VoidCallback? onTap;

  const NowPlayingBar({
    super.key,
    required this.track,
    this.artist,
    this.artUrl,
    required this.color,
    this.compact = false,
    this.isPlaying = true,
    this.onTap,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    if (!widget.isPlaying) _wave.stop();
  }

  @override
  void didUpdateWidget(NowPlayingBar old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_wave.isAnimating) _wave.repeat();
    if (!widget.isPlaying && _wave.isAnimating) _wave.stop();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  // ── Waveform bars ──────────────────────────────────────────────────────────
  Widget _waveform({required int bars, required double maxH, required double w}) {
    final phases = [0.0, math.pi / 2, math.pi, math.pi * 1.5, math.pi * 0.75];
    return AnimatedBuilder(
      animation: _wave,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(bars, (i) {
            final h = widget.isPlaying
                ? (math.sin(_wave.value * 2 * math.pi + phases[i % phases.length])
                            * 0.5 +
                        0.5) *
                        maxH +
                    3
                : 4.0;
            return Container(
              width: w,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(w / 2),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: widget.compact ? _pill() : _card(),
    );
  }

  // ── Compact single-line pill ───────────────────────────────────────────────
  Widget _pill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _waveform(bars: 3, maxH: 10, w: 2.5),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              widget.track,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Full card ──────────────────────────────────────────────────────────────
  Widget _card() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: widget.color.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Album art or animated placeholder
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: widget.color.withOpacity(0.15),
              image: widget.artUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.artUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: widget.artUrl == null
                ? Center(
                    child: Icon(Icons.music_note_rounded,
                        color: widget.color.withOpacity(0.7), size: 20))
                : null,
          ),
          const SizedBox(width: 12),
          // Track + artist
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "LISTENING NOW" label
                Row(children: [
                  AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) => Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withOpacity(
                            widget.isPlaying
                                ? 0.6 + _wave.value * 0.4
                                : 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.isPlaying ? 'LISTENING NOW' : 'PAUSED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: widget.color.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(
                  widget.track,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.artist != null)
                  Text(
                    widget.artist!,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.55)),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Waveform
          SizedBox(
            width: 28,
            height: 24,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _waveform(bars: 4, maxH: 18, w: 3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Static factory that reads from NowPlayingService ─────────────────────────
class NowPlayingListener extends StatelessWidget {
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  const NowPlayingListener({
    super.key,
    required this.color,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NowPlayingService(),
      builder: (_, __) {
        final svc = NowPlayingService();
        if (!svc.hasTrack) return const SizedBox.shrink();
        return NowPlayingBar(
          track: svc.track!,
          artist: svc.artist,
          artUrl: svc.artUrl,
          color: color,
          compact: compact,
          isPlaying: svc.isPlaying,
          onTap: onTap,
        );
      },
    );
  }
}
