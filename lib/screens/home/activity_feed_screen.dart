import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity item model
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityType {
  newSync,
  momentPosted,
  songFire,
  campfireJoin,
  vibeMatch,
  songShare,
  milestone,
}

class _Activity {
  final _ActivityType type;
  final String handle;
  final String emoji;
  final Color color;
  final String text;        // main action text
  final String? sub;        // song title / extra detail
  final DateTime time;
  final bool isNew;

  const _Activity({
    required this.type,
    required this.handle,
    required this.emoji,
    required this.color,
    required this.text,
    this.sub,
    required this.time,
    this.isNew = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Seed activity data (would come from Firestore in production)
// ─────────────────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _activities = [
  _Activity(
    type: _ActivityType.newSync,
    handle: '@maya.k', emoji: '🎧', color: Color(0xFFFF6B6B),
    text: 'synced with you', sub: 'now at bronze orbit',
    time: _now.subtract(const Duration(minutes: 3)), isNew: true,
  ),
  _Activity(
    type: _ActivityType.songFire,
    handle: '@zara.w', emoji: '🌙', color: Color(0xFF7C83FD),
    text: 'fired your Pulse card',
    sub: 'Espresso · Sabrina Carpenter',
    time: _now.subtract(const Duration(minutes: 11)), isNew: true,
  ),
  _Activity(
    type: _ActivityType.momentPosted,
    handle: '@dev.s', emoji: '🔥', color: Color(0xFF43E97B),
    text: 'posted a Moment ✨',
    sub: '"can\'t stop this song 🔥"',
    time: _now.subtract(const Duration(minutes: 28)), isNew: true,
  ),
  _Activity(
    type: _ActivityType.vibeMatch,
    handle: '@rina.p', emoji: '✨', color: Color(0xFFFAD961),
    text: 'is vibing the same as you',
    sub: '🌙 nostalgic · 2 hrs ago',
    time: _now.subtract(const Duration(hours: 1, minutes: 5)), isNew: true,
  ),
  _Activity(
    type: _ActivityType.campfireJoin,
    handle: '@jay.r', emoji: '☀️', color: Color(0xFF11998E),
    text: 'joined Late Night Crew 🔥',
    time: _now.subtract(const Duration(hours: 2, minutes: 30)),
  ),
  _Activity(
    type: _ActivityType.songShare,
    handle: '@sam.w', emoji: '🎸', color: Color(0xFFFC6076),
    text: 'shared a song in Late Night Crew',
    sub: 'Blinding Lights · The Weeknd',
    time: _now.subtract(const Duration(hours: 3, minutes: 15)),
  ),
  _Activity(
    type: _ActivityType.milestone,
    handle: '@leo.k', emoji: '💜', color: Color(0xFFA18CD1),
    text: 'hit a 7-day Moment streak 🏆',
    time: _now.subtract(const Duration(hours: 5)),
  ),
  _Activity(
    type: _ActivityType.songFire,
    handle: '@ari.c', emoji: '🌊', color: Color(0xFF4FACFE),
    text: 'fired your Pulse card',
    sub: 'luther · Kendrick Lamar & SZA',
    time: _now.subtract(const Duration(hours: 6, minutes: 45)),
  ),
  _Activity(
    type: _ActivityType.momentPosted,
    handle: '@mia.t', emoji: '🌸', color: Color(0xFFF77062),
    text: 'posted a Moment ✨',
    sub: '"okay this track is everything"',
    time: _now.subtract(const Duration(hours: 9)),
  ),
  _Activity(
    type: _ActivityType.newSync,
    handle: '@kai.r', emoji: '⚡', color: Color(0xFF667EEA),
    text: 'synced with you', sub: 'now at bronze orbit',
    time: _now.subtract(const Duration(hours: 11)),
  ),
  // Yesterday
  _Activity(
    type: _ActivityType.vibeMatch,
    handle: '@maya.k', emoji: '🎧', color: Color(0xFFFF6B6B),
    text: 'matched your vibe',
    sub: '🎧 focused · same time',
    time: _now.subtract(const Duration(hours: 26)),
  ),
  _Activity(
    type: _ActivityType.campfireJoin,
    handle: '@dev.s', emoji: '🔥', color: Color(0xFF43E97B),
    text: 'started a new campfire',
    sub: '🎵 Study Grind',
    time: _now.subtract(const Duration(hours: 30)),
  ),
  _Activity(
    type: _ActivityType.milestone,
    handle: 'You', emoji: '🌟', color: AuraTheme.accent,
    text: 'reached a 5-day Moment streak! 🔥',
    time: _now.subtract(const Duration(hours: 33)),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  String _timeLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  bool _isToday(DateTime t) =>
      DateTime.now().difference(t).inHours < 24;

  @override
  Widget build(BuildContext context) {
    final todayItems = _activities.where((a) => _isToday(a.time)).toList();
    final earlierItems = _activities.where((a) => !_isToday(a.time)).toList();
    final newCount = _activities.where((a) => a.isNew).length;

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: Row(children: [
          const Text('orbit activity',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (newCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AuraTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$newCount new',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          if (todayItems.isNotEmpty) ...[
            _sectionHeader('Today'),
            ...todayItems.map((a) => _ActivityTile(a: a, timeLabel: _timeLabel(a.time))),
          ],
          if (earlierItems.isNotEmpty) ...[
            _sectionHeader('Earlier'),
            ...earlierItems.map((a) => _ActivityTile(a: a, timeLabel: _timeLabel(a.time))),
          ],
          const SizedBox(height: 32),
          Center(
            child: Text("you're all caught up ✨",
                style: TextStyle(color: AuraTheme.textMuted.withOpacity(0.5), fontSize: 13)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: AuraTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final _Activity a;
  final String timeLabel;
  const _ActivityTile({required this.a, required this.timeLabel});

  IconData get _typeIcon {
    switch (a.type) {
      case _ActivityType.newSync:       return Icons.sync_rounded;
      case _ActivityType.momentPosted:  return Icons.auto_awesome_rounded;
      case _ActivityType.songFire:      return Icons.local_fire_department_rounded;
      case _ActivityType.campfireJoin:  return Icons.group_rounded;
      case _ActivityType.vibeMatch:     return Icons.favorite_rounded;
      case _ActivityType.songShare:     return Icons.music_note_rounded;
      case _ActivityType.milestone:     return Icons.emoji_events_rounded;
    }
  }

  Color get _typeColor {
    switch (a.type) {
      case _ActivityType.newSync:       return const Color(0xFF43E97B);
      case _ActivityType.momentPosted:  return AuraTheme.accentLight;
      case _ActivityType.songFire:      return Colors.deepOrange;
      case _ActivityType.campfireJoin:  return AuraTheme.accent;
      case _ActivityType.vibeMatch:     return const Color(0xFFFC6076);
      case _ActivityType.songShare:     return AuraTheme.accent;
      case _ActivityType.milestone:     return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: a.isNew
            ? AuraTheme.accent.withOpacity(0.05)
            : AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: a.isNew
            ? Border.all(color: AuraTheme.accent.withOpacity(0.15))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a.color.withOpacity(0.15),
              ),
              child: Center(child: Text(a.emoji, style: const TextStyle(fontSize: 20))),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: _typeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AuraTheme.background, width: 1.5),
                ),
                child: Icon(_typeIcon, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 13, height: 1.4),
            children: [
              TextSpan(
                text: a.handle == 'You' ? 'You' : a.handle,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: a.handle == 'You' ? AuraTheme.accent : AuraTheme.textPrimary,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: a.text),
            ],
          ),
        ),
        subtitle: a.sub != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(a.sub!,
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeLabel,
                style: const TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
            if (a.isNew) ...[
              const SizedBox(height: 4),
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: AuraTheme.accent, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
