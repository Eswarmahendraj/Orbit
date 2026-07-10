import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';

class SongBattleScreen extends StatefulWidget {
  const SongBattleScreen({super.key});
  @override
  State<SongBattleScreen> createState() => _SongBattleScreenState();
}

class _SongBattleScreenState extends State<SongBattleScreen> {
  int _votesA = 64;
  int _votesB = 36;
  int? _myVote; // 0=A 1=B
  Duration _remaining = const Duration(hours: 11, minutes: 42, seconds: 18);
  Timer? _timer;

  static const _songA = {
    'title': 'Espresso',
    'artist': 'Sabrina Carpenter',
    'emoji': '☕',
  };
  static const _songB = {
    'title': 'Die With A Smile',
    'artist': 'Lady Gaga & Bruno Mars',
    'emoji': '💀',
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds > 0) {
        setState(() => _remaining -= const Duration(seconds: 1));
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _vote(int choice) {
    if (_myVote != null) return;
    setState(() {
      _myVote = choice;
      if (choice == 0) _votesA += 3;
      else _votesB += 3;
    });
  }

  String _fmtTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _votesA + _votesB;
    final pA = _votesA / total;
    final pB = _votesB / total;
    final voted = _myVote != null;

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('song battle 🥊',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Timer chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined,
                  size: 14, color: AuraTheme.textMuted),
              const SizedBox(width: 6),
              Text('ends in ${_fmtTime(_remaining)}',
                  style: const TextStyle(
                      color: AuraTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 28),

          // Song cards
          Row(children: [
            Expanded(child: _card(_songA, 0, voted && _votesA > _votesB)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('VS',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AuraTheme.textMuted.withOpacity(0.6))),
            ),
            Expanded(child: _card(_songB, 1, voted && _votesB > _votesA)),
          ]),
          const SizedBox(height: 28),

          // Vote bar
          if (voted) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('votes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 34,
                child: Stack(children: [
                  // Full background
                  Container(color: AuraTheme.surface, height: 34),
                  // Orange fill
                  AnimatedFractionallySizedBox(
                    widthFactor: pA,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: Container(color: AuraTheme.accent),
                  ),
                  // Labels overlay
                  Row(children: [
                    Expanded(
                      child: Center(
                        child: Text('${(pA * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('${(pB * 100).round()}%',
                            style: TextStyle(
                                color: pB > pA
                                    ? AuraTheme.textPrimary
                                    : AuraTheme.textMuted,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Text('$total total votes',
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 12)),
          ],

          const Spacer(),
          if (!voted)
            const Text('tap a song to cast your vote',
                style: TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          if (voted && _myVote == 0)
            Text('you voted for ${_songA['title']}',
                style: const TextStyle(
                    color: AuraTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          if (voted && _myVote == 1)
            Text('you voted for ${_songB['title']}',
                style: const TextStyle(
                    color: AuraTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _card(Map<String, String> song, int idx, bool winning) {
    final picked = _myVote == idx;
    return GestureDetector(
      onTap: () => _vote(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: picked
              ? AuraTheme.accent
              : winning
                  ? AuraTheme.accent.withOpacity(0.07)
                  : AuraTheme.card,
          borderRadius: BorderRadius.circular(22),
          border: winning && !picked
              ? Border.all(color: AuraTheme.accent.withOpacity(0.3))
              : null,
          boxShadow: picked
              ? [
                  BoxShadow(
                      color: AuraTheme.accent.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Column(children: [
          Text(song['emoji']!,
              style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(song['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color:
                      picked ? Colors.white : AuraTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(song['artist']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: picked
                      ? Colors.white.withOpacity(0.75)
                      : AuraTheme.textMuted)),
          if (winning) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: picked
                    ? Colors.white.withOpacity(0.25)
                    : AuraTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('leading 🔥',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}
