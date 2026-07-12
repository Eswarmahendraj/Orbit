import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'song_clip_screen.dart';

class ClipStreaksScreen extends StatefulWidget {
  const ClipStreaksScreen({super.key});

  @override
  State<ClipStreaksScreen> createState() => _ClipStreaksScreenState();
}

class _ClipStreaksScreenState extends State<ClipStreaksScreen> {
  final _friendColors = <String, Color>{
    '@maya.k': const Color(0xFFFF8C42),
    '@zara.w': const Color(0xFF6C63FF),
    '@dev.s': const Color(0xFFFF7A50),
    '@rina.p': const Color(0xFF00B894),
    '@jay.r': const Color(0xFFE17055),
  };

  Color _colorFor(String handle) =>
      _friendColors[handle] ??
      Color(0xFF000000 | (handle.hashCode & 0xFFFFFF)).withOpacity(1);

  String _initial(String handle) =>
      handle.replaceAll('@', '').substring(0, 1).toUpperCase();

  String _name(String handle) =>
      handle.replaceAll('@', '').split('.').first;

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final streaks = state.clipStreaks;

    // Also show friends without streaks yet (from syncLevels as demo)
    final allHandles = {
      ...streaks.keys,
      ...state.syncLevels.keys,
    }.toList()
      ..sort((a, b) {
        final ac = (streaks[a]?['streakCount'] as int?) ?? 0;
        final bc = (streaks[b]?['streakCount'] as int?) ?? 0;
        return bc.compareTo(ac);
      });

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('clip streaks',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: allHandles.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: allHandles.length,
              itemBuilder: (_, i) => _streakCard(allHandles[i], streaks[allHandles[i]]),
            ),
    );
  }

  Widget _streakCard(String handle, Map<String, dynamic>? data) {
    final streakCount = (data?['streakCount'] as int?) ?? 0;
    final bestStreak = (data?['bestStreak'] as int?) ?? 0;
    final sentToday = data?['lastSentDate'] == _todayStr();
    final receivedToday = data?['lastReceivedDate'] == _todayStr();
    final mutual = List<String>.from(data?['mutualDates'] ?? []);
    final color = _colorFor(handle);
    final initial = _initial(handle);
    final name = _name(handle);
    final broken = streakCount == 0 && mutual.isNotEmpty;
    final never = mutual.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: streakCount > 0
            ? Border.all(
                color: AuraTheme.accent.withOpacity(0.25), width: 1.5)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            child: Text(initial,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                handle,
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 11),
              ),
            ]),
          ),
          // Flame + count
          if (streakCount > 0) ...[
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
            Text('$streakCount',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.accent)),
          ] else if (broken) ...[
            const Icon(Icons.local_fire_department_outlined,
                color: AuraTheme.textMuted, size: 24),
            const SizedBox(width: 4),
            const Text('0',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.textMuted)),
          ],
        ]),

        const SizedBox(height: 10),

        // ── Best streak + today status ──
        Row(children: [
          if (bestStreak > 0)
            _pill('best $bestStreak', AuraTheme.accent.withOpacity(0.12),
                AuraTheme.accent),
          const SizedBox(width: 6),
          if (sentToday && receivedToday)
            _pill('✓ both sent today', const Color(0xFF00B894).withOpacity(0.12),
                const Color(0xFF00875A))
          else if (sentToday)
            _pill('you sent · waiting for them',
                Colors.orangeAccent.withOpacity(0.1), Colors.orangeAccent)
          else if (never)
            _pill('no clips yet', AuraTheme.surface, AuraTheme.textMuted)
          else
            _pill('send to keep going!',
                AuraTheme.accent.withOpacity(0.08), AuraTheme.accent),
        ]),

        const SizedBox(height: 12),

        // ── 14-day calendar grid ──
        if (!never) ...[
          const Text('last 14 days',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AuraTheme.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _calendarGrid(mutual, data),
          const SizedBox(height: 8),
          _legend(),
        ],

        // ── Restart / send first clip CTA ──
        if (broken || never) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final sent = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SongClipScreen(
                    toUsername: handle,
                    toDisplayName: name,
                  ),
                ),
              );
              if (sent == true && mounted) setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                  color: AuraTheme.accent,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  broken
                      ? 'restart — send $name a clip'
                      : 'start a streak — send a clip',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _calendarGrid(List<String> mutual, Map<String, dynamic>? data) {
    final today = _todayStr();
    final sentToday = data?['lastSentDate'] == today;
    final days = List.generate(14, (i) {
      final d = DateTime.now().subtract(Duration(days: 13 - i));
      return _dateStr(d);
    });

    return Row(
      children: days.map((day) {
        final isMutual = mutual.contains(day);
        final isToday = day == today;
        final isSentOnly =
            !isMutual && isToday && sentToday;

        Color fill;
        Border? border;
        Widget? child;

        if (isMutual) {
          fill = AuraTheme.accent;
        } else if (isSentOnly) {
          fill = AuraTheme.accentLight.withOpacity(0.4);
          border = Border.all(color: AuraTheme.accent, width: 1.5);
        } else if (isToday) {
          fill = AuraTheme.surface;
          border = Border.all(
              color: AuraTheme.accent.withOpacity(0.6),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside);
        } else {
          fill = AuraTheme.surface;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 2),
            height: 22,
            decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: border),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  Widget _legend() {
    return Row(children: [
      _legendDot(AuraTheme.accent, 'both sent'),
      const SizedBox(width: 10),
      _legendDot(AuraTheme.accentLight.withOpacity(0.5), 'only you'),
      const SizedBox(width: 10),
      _legendDot(AuraTheme.surface,
          'today', border: Border.all(color: AuraTheme.accent, width: 1.2)),
    ]);
  }

  Widget _legendDot(Color color, String label, {Border? border}) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: border)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 10, color: AuraTheme.textMuted)),
    ]);
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🔥', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('no clip streaks yet',
            style: TextStyle(
                color: AuraTheme.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('send a clip to a friend from a DM',
            style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
      ]),
    );
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _todayStr() => _dateStr(DateTime.now());
}
