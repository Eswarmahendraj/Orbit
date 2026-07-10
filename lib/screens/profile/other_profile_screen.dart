import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

enum _SyncState { idle, pending, synced }

// Sync level ring colors
const _syncLevelColors = {
  'bronze': Color(0xFFCD7F32),
  'silver': Color(0xFFC0C0C0),
  'gold': Color(0xFFFFD700),
  'platinum': Color(0xFF00D2FF),
};

class OtherProfileScreen extends StatefulWidget {
  final String name;
  final String handle;
  final Color userColor;
  final String initial;
  final String mood;
  final String moodEmoji;
  final String songTitle;
  final String artistName;
  final String? previewUrl;
  final List<String>? moodTags;

  const OtherProfileScreen({
    super.key,
    required this.name,
    required this.handle,
    required this.userColor,
    required this.initial,
    required this.mood,
    required this.moodEmoji,
    required this.songTitle,
    required this.artistName,
    this.previewUrl,
    this.moodTags,
  });

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringAnim;
  _SyncState _syncState = _SyncState.idle;
  bool _isPlaying = false;
  final _player = AudioPlayer();

  final List<Map<String, dynamic>> _mutuals = const [
    {'initial': 'M', 'color': Color(0xFFFF4500)},
    {'initial': 'Z', 'color': Color(0xFFFF7A50)},
    {'initial': 'A', 'color': Color(0xFF6C63FF)},
  ];

  @override
  void initState() {
    super.initState();
    _ringAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _ringAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      if (widget.previewUrl != null) {
        try {
          await _player.setUrl(widget.previewUrl!);
          await _player.play();
        } catch (_) {
          setState(() => _isPlaying = false);
        }
      }
    }
  }

  void _onSyncTap() {
    if (_syncState == _SyncState.synced) {
      _showDesyncDialog();
    } else if (_syncState == _SyncState.idle) {
      setState(() => _syncState = _SyncState.pending);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _syncState = _SyncState.synced);
      });
    }
  }

  void _showDesyncDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AuraTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('desync?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('remove ${widget.name} from your orbit?',
            style: const TextStyle(color: AuraTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('cancel',
                style: TextStyle(color: AuraTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _syncState = _SyncState.idle);
              Navigator.pop(context);
            },
            child: const Text('desync',
                style: TextStyle(color: AuraTheme.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    switch (_syncState) {
      case _SyncState.idle:
        return ElevatedButton(
          onPressed: _onSyncTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraTheme.accent,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('sync',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        );
      case _SyncState.pending:
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraTheme.surface,
            foregroundColor: AuraTheme.textMuted,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AuraTheme.textMuted)),
              ),
              const SizedBox(width: 8),
              const Text('syncing...',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        );
      case _SyncState.synced:
        return OutlinedButton(
          onPressed: _onSyncTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AuraTheme.textMuted,
            side: BorderSide(color: AuraTheme.textMuted.withOpacity(0.4)),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: AuraTheme.textMuted),
              SizedBox(width: 6),
              Text('synced',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags =
        widget.moodTags ?? ['indie', 'late nights', 'lo-fi', 'road trips'];

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Avatar with ring
                Center(
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (context, child) => CustomPaint(
                      painter: _RingPainter(
                          progress: _ringAnim.value,
                          color: widget.userColor),
                      child: child,
                    ),
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.userColor.withOpacity(0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initial,
                        style: TextStyle(
                            color: widget.userColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(widget.handle,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 14)),
                  const SizedBox(width: 6),
                  _SyncLevelBadge(handle: widget.handle),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.moodEmoji} ${widget.mood}',
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Mutual synced friends
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Stacked avatars
                      SizedBox(
                        width: 60,
                        height: 28,
                        child: Stack(
                          children: List.generate(
                            _mutuals.length,
                            (i) => Positioned(
                              left: i * 18.0,
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: (_mutuals[i]['color'] as Color)
                                    .withOpacity(0.15),
                                child: Text(
                                  _mutuals[i]['initial'] as String,
                                  style: TextStyle(
                                      color:
                                          _mutuals[i]['color'] as Color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${_mutuals.length} mutual syncs',
                          style: const TextStyle(
                              color: AuraTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _StatChip(label: 'vybes', value: '247'),
                      _StatChip(label: 'synced', value: '89'),
                      _StatChip(label: 'streak', value: '14🔥'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Now vibing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AuraTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                          left: BorderSide(
                              color: AuraTheme.accent, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AuraTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note,
                              color: AuraTheme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.songTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(widget.artistName,
                                  style: const TextStyle(
                                      color: AuraTheme.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: AuraTheme.accent,
                                shape: BoxShape.circle),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mood tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AuraTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: AuraTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(child: _buildSyncButton()),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AuraTheme.textMuted.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            color: AuraTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text('their vybes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),

          // Vybe grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Container(
                  decoration: BoxDecoration(
                    color: widget.userColor
                        .withOpacity(0.08 + (i % 3) * 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note,
                      color: AuraTheme.accent, size: 24),
                ),
                childCount: 9,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AuraTheme.textPrimary)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AuraTheme.textMuted)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Badge chip showing sync level (bronze / silver / gold / platinum)
class _SyncLevelBadge extends StatelessWidget {
  final String handle;
  const _SyncLevelBadge({required this.handle});

  @override
  Widget build(BuildContext context) {
    final level = OrbitState().syncLevels[handle];
    if (level == null) return const SizedBox.shrink();
    final color = _syncLevelColors[level] ?? AuraTheme.accent;
    final emoji = {
      'bronze': '🥉',
      'silver': '🥈',
      'gold': '🥇',
      'platinum': '💎',
    }[level] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('$emoji $level',
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}
