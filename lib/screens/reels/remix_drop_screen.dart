import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RemixDropScreen — TikTok-style stitch/duet UI
// ─────────────────────────────────────────────────────────────────────────────

enum _RemixMode { duet, stitch }

class RemixDropScreen extends StatefulWidget {
  final String handle;
  final String displayName;
  final String avatarEmoji;
  final Color accentColor;
  final String caption;
  final String song;
  final String artist;
  final String? videoUrl;

  const RemixDropScreen({
    super.key,
    required this.handle,
    required this.displayName,
    required this.avatarEmoji,
    required this.accentColor,
    required this.caption,
    required this.song,
    required this.artist,
    this.videoUrl,
  });

  @override
  State<RemixDropScreen> createState() => _RemixDropScreenState();
}

class _RemixDropScreenState extends State<RemixDropScreen>
    with SingleTickerProviderStateMixin {
  _RemixMode _mode = _RemixMode.duet;
  bool _useSound = true;
  bool _recording = false;
  bool _posted = false;
  int _recordSecs = 0;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _accent => widget.accentColor;

  void _toggleRecord() {
    HapticFeedback.mediumImpact();
    setState(() => _recording = !_recording);
    if (_recording) {
      // Simulate recording progress
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_recording) return false;
        setState(() => _recordSecs++);
        if (_recordSecs >= 60) { setState(() => _recording = false); return false; }
        return true;
      });
    }
  }

  void _post() {
    HapticFeedback.heavyImpact();
    setState(() { _recording = false; _posted = true; });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Text('🔁', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Text('Remix dropped!', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: widget.accentColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  String _fmtSecs(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [_accent, Colors.white],
          ).createShader(b),
          child: Text('Remix 🔁 @${widget.handle}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ModeToggle(
              mode: _mode,
              accent: _accent,
              onChange: (m) => setState(() => _mode = m),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Main split view
        Expanded(
          child: _mode == _RemixMode.duet
              ? _DuetView(
                  original: _OriginalPanel(
                    handle: widget.handle,
                    displayName: widget.displayName,
                    avatarEmoji: widget.avatarEmoji,
                    accentColor: _accent,
                    caption: widget.caption,
                    song: widget.song,
                  ),
                  myPanel: _MyPanel(
                    recording: _recording,
                    recordSecs: _recordSecs,
                    pulseCtrl: _pulseCtrl,
                    accent: _accent,
                    fmtSecs: _fmtSecs,
                  ),
                )
              : _StitchView(
                  original: _OriginalPanel(
                    handle: widget.handle,
                    displayName: widget.displayName,
                    avatarEmoji: widget.avatarEmoji,
                    accentColor: _accent,
                    caption: widget.caption,
                    song: widget.song,
                  ),
                  myPanel: _MyPanel(
                    recording: _recording,
                    recordSecs: _recordSecs,
                    pulseCtrl: _pulseCtrl,
                    accent: _accent,
                    fmtSecs: _fmtSecs,
                  ),
                ),
        ),

        // Bottom controls
        _BottomBar(
          recording: _recording,
          posted: _posted,
          useSound: _useSound,
          recordSecs: _recordSecs,
          accent: _accent,
          song: widget.song,
          fmtSecs: _fmtSecs,
          onToggleRecord: _toggleRecord,
          onToggleSound: () => setState(() => _useSound = !_useSound),
          onPost: _post,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode toggle (Duet | Stitch)
// ─────────────────────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _RemixMode mode;
  final Color accent;
  final ValueChanged<_RemixMode> onChange;
  const _ModeToggle({required this.mode, required this.accent, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Pill('Duet', mode == _RemixMode.duet, accent,
            () => onChange(_RemixMode.duet)),
        const SizedBox(width: 2),
        _Pill('Stitch', mode == _RemixMode.stitch, accent,
            () => onChange(_RemixMode.stitch)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  const _Pill(this.label, this.active, this.accent, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? accent : Colors.white38,
                fontWeight: FontWeight.w700,
                fontSize: 11)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Duet layout (side by side)
// ─────────────────────────────────────────────────────────────────────────────

class _DuetView extends StatelessWidget {
  final Widget original;
  final Widget myPanel;
  const _DuetView({required this.original, required this.myPanel});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: original),
      Container(width: 1, color: Colors.white.withOpacity(0.1)),
      Expanded(child: myPanel),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stitch layout (original on top smaller, yours below bigger)
// ─────────────────────────────────────────────────────────────────────────────

class _StitchView extends StatelessWidget {
  final Widget original;
  final Widget myPanel;
  const _StitchView({required this.original, required this.myPanel});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 160, child: original),
      Container(height: 1, color: Colors.white.withOpacity(0.1)),
      Expanded(child: myPanel),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Original Drop panel
// ─────────────────────────────────────────────────────────────────────────────

class _OriginalPanel extends StatelessWidget {
  final String handle;
  final String displayName;
  final String avatarEmoji;
  final Color accentColor;
  final String caption;
  final String song;

  const _OriginalPanel({
    required this.handle,
    required this.displayName,
    required this.avatarEmoji,
    required this.accentColor,
    required this.caption,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.25),
            Colors.black.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Original content placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.2),
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 2),
                  ),
                  child: Center(child: Text(avatarEmoji,
                      style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 8),
                Text('@$handle',
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Original label badge
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(children: [
                Icon(Icons.play_circle_fill_rounded,
                    color: accentColor, size: 10),
                const SizedBox(width: 4),
                const Text('ORIGINAL',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My recording panel
// ─────────────────────────────────────────────────────────────────────────────

class _MyPanel extends StatelessWidget {
  final bool recording;
  final int recordSecs;
  final AnimationController pulseCtrl;
  final Color accent;
  final String Function(int) fmtSecs;

  const _MyPanel({
    required this.recording,
    required this.recordSecs,
    required this.pulseCtrl,
    required this.accent,
    required this.fmtSecs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, __) => Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording
                          ? accent.withOpacity(0.1 + pulseCtrl.value * 0.1)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: recording
                            ? accent.withOpacity(0.6)
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      recording
                          ? Icons.fiber_manual_record_rounded
                          : Icons.videocam_off_rounded,
                      color: recording ? accent : Colors.white38,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recording ? fmtSecs(recordSecs) : 'Tap ● to start',
                  style: TextStyle(
                    color: recording ? accent : Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // "YOUR REMIX" label
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text('YOUR REMIX',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),

          // Live recording indicator
          if (recording)
            Positioned(
              top: 10, left: 10,
              child: AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent
                        .withOpacity(0.6 + pulseCtrl.value * 0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom control bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool recording;
  final bool posted;
  final bool useSound;
  final int recordSecs;
  final Color accent;
  final String song;
  final String Function(int) fmtSecs;
  final VoidCallback onToggleRecord;
  final VoidCallback onToggleSound;
  final VoidCallback onPost;

  const _BottomBar({
    required this.recording, required this.posted,
    required this.useSound, required this.recordSecs,
    required this.accent, required this.song,
    required this.fmtSecs, required this.onToggleRecord,
    required this.onToggleSound, required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    final canPost = recordSecs > 0 && !recording;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Sound toggle + info
        Row(children: [
          GestureDetector(
            onTap: onToggleSound,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: useSound
                    ? accent.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: useSound
                      ? accent.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(children: [
                Icon(
                  useSound ? Icons.music_note_rounded : Icons.music_off_rounded,
                  color: useSound ? accent : Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  useSound ? 'Using original sound' : 'Sound muted',
                  style: TextStyle(
                    color: useSound ? accent : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          if (useSound)
            Expanded(
              child: Text(song,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
        ]),
        const SizedBox(height: 14),

        // Record + post row
        Row(children: [
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: recordSecs / 60,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmtSecs(recordSecs)} / 01:00',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Record button
          GestureDetector(
            onTap: onToggleRecord,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 54, height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recording
                    ? Colors.redAccent.withOpacity(0.2)
                    : accent.withOpacity(0.15),
                border: Border.all(
                  color: recording ? Colors.redAccent : accent,
                  width: 2.5,
                ),
              ),
              child: Icon(
                recording
                    ? Icons.stop_rounded
                    : Icons.fiber_manual_record_rounded,
                color: recording ? Colors.redAccent : accent,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Post button
          GestureDetector(
            onTap: canPost ? onPost : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: canPost
                    ? LinearGradient(
                        colors: [accent, accent.withOpacity(0.7)])
                    : null,
                color: canPost ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                boxShadow: canPost ? [BoxShadow(
                    color: accent.withOpacity(0.35), blurRadius: 12)] : null,
              ),
              child: posted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 22)
                  : Text(
                      'Drop 🔁',
                      style: TextStyle(
                        color: canPost ? Colors.white : Colors.white24,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ]),
      ]),
    );
  }
}
