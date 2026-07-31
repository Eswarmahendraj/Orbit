import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import 'vibe_match_service.dart';

/// Badge shown on OtherProfileScreen — tap to reveal full breakdown
class VibeMatchBadge extends StatefulWidget {
  final String myUid;
  final String theirUid;
  final String theirName;

  const VibeMatchBadge({
    super.key,
    required this.myUid,
    required this.theirUid,
    required this.theirName,
  });

  @override
  State<VibeMatchBadge> createState() => _VibeMatchBadgeState();
}

class _VibeMatchBadgeState extends State<VibeMatchBadge>
    with SingleTickerProviderStateMixin {
  final _service = VibeMatchService();
  VibeMatchResult? _result;
  bool _loading = true;
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _load();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Try cache first
    var result =
        await _service.getCachedMatch(widget.myUid, widget.theirUid);
    if (result == null) {
      result =
          await _service.computeMatch(widget.myUid, widget.theirUid);
      await _service.cacheMatch(widget.myUid, widget.theirUid, result);
    }
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;

    if (_loading) {
      return AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) => Container(
          width: 100,
          height: 32,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    final r = _result!;
    final color = _scoreColor(r.score, theme);

    return GestureDetector(
      onTap: () => _showBreakdown(context, r, theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '${r.score}% match',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score, AuraTheme theme) {
    if (score >= 70) return Colors.orange;
    if (score >= 50) return theme.accent;
    if (score >= 30) return Colors.blue;
    return theme.textMuted;
  }

  void _showBreakdown(
      BuildContext context, VibeMatchResult r, AuraTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VibeMatchSheet(
        result: r,
        theirName: widget.theirName,
        theme: theme,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full breakdown sheet
// ─────────────────────────────────────────────────────────────────────────────
class _VibeMatchSheet extends StatelessWidget {
  final VibeMatchResult result;
  final String theirName;
  final AuraTheme theme;

  const _VibeMatchSheet({
    required this.result,
    required this.theirName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = result.score >= 70
        ? Colors.orange
        : result.score >= 50
            ? theme.accent
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // Big score
          Text(result.emoji,
              style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            '${result.score}%',
            style: TextStyle(
                color: color,
                fontSize: 48,
                fontWeight: FontWeight.w800),
          ),
          Text(
            result.label,
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'You & ${theirName.split(' ').first}',
            style: TextStyle(color: theme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.score / 100,
              minHeight: 10,
              backgroundColor: theme.cardBackground,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 24),

          // Common artists
          if (result.commonArtists.isNotEmpty) ...[
            _SectionHeader(label: 'Artists you both love', theme: theme),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: result.commonArtists
                  .map((a) => _Chip(label: a, theme: theme, color: color))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Common genres
          if (result.commonGenres.isNotEmpty) ...[
            _SectionHeader(label: 'Shared genres', theme: theme),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: result.commonGenres
                  .map((g) => _Chip(
                      label: g,
                      theme: theme,
                      color: theme.accentSecondary))
                  .toList(),
            ),
          ],

          if (result.commonArtists.isEmpty && result.commonGenres.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'You two are from different musical worlds — could be exciting!',
                style: TextStyle(
                    color: theme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final AuraTheme theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(label,
            style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final AuraTheme theme;
  final Color color;
  const _Chip(
      {required this.label, required this.theme, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      );
}
