import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Battle Mode
// ─────────────────────────────────────────────────────────────────────────────

enum BattleMode {
  vote('🥊', 'Vote Battle',
      'Community votes decide the winner', Duration(hours: 11)),
  speed('⚡', 'Speed Round',
      '30 seconds — quick fire vote!', Duration(seconds: 30)),
  genre('🎸', 'Genre Battle',
      'Only songs from the same genre', Duration(hours: 3)),
  vibe('❤️', 'Vibe Match',
      'Match the energy — listeners decide', Duration(hours: 6));

  final String icon;
  final String label;
  final String desc;
  final Duration duration;
  const BattleMode(this.icon, this.label, this.desc, this.duration);
}

// ─────────────────────────────────────────────────────────────────────────────
// SongBattleScreen — mode picker first, then battle
// ─────────────────────────────────────────────────────────────────────────────

class SongBattleScreen extends StatefulWidget {
  const SongBattleScreen({super.key});
  @override
  State<SongBattleScreen> createState() => _SongBattleScreenState();
}

class _SongBattleScreenState extends State<SongBattleScreen> {
  BattleMode? _mode;

  @override
  Widget build(BuildContext context) {
    if (_mode == null) return _ModePickerView(onPick: (m) => setState(() => _mode = m));
    return _BattleView(mode: _mode!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModePickerView
// ─────────────────────────────────────────────────────────────────────────────

class _ModePickerView extends StatelessWidget {
  final ValueChanged<BattleMode> onPick;
  const _ModePickerView({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.themeBg,
      appBar: AppBar(
        backgroundColor: AuraTheme.themeBg,
        title: Text('song battle 🥊',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AuraTheme.themeTextPrimary)),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AuraTheme.themeTextPrimary),
            onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose battle mode',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.themeTextPrimary)),
            const SizedBox(height: 6),
            Text('How do you want to settle this?',
                style: TextStyle(
                    fontSize: 14, color: AuraTheme.themeTextMuted)),
            const SizedBox(height: 24),
            ...BattleMode.values.map((m) => _ModeCard(mode: m, onTap: () => onPick(m))),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final BattleMode mode;
  final VoidCallback onTap;
  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Color per mode
    final colors = {
      BattleMode.vote: [const Color(0xFFFF8C42), const Color(0xFFFFAD75)],
      BattleMode.speed: [const Color(0xFFFC6076), const Color(0xFFFF9A44)],
      BattleMode.genre: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      BattleMode.vibe: [const Color(0xFFA18CD1), const Color(0xFFFBC2EB)],
    };
    final grad = colors[mode]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AuraTheme.themeCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: grad.first.withOpacity(0.25), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: grad.first.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
                child: Text(mode.icon,
                    style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(mode.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AuraTheme.themeTextPrimary)),
              const SizedBox(height: 3),
              Text(mode.desc,
                  style: TextStyle(
                      fontSize: 12,
                      color: AuraTheme.themeTextSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: grad.first.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_fmtDuration(mode.duration),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: grad.first)),
              ),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AuraTheme.themeTextMuted, size: 20),
        ]),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s round';
    if (d.inMinutes < 60) return '${d.inMinutes}m round';
    return '${d.inHours}h round';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BattleView — the actual battle UI (with mode context)
// ─────────────────────────────────────────────────────────────────────────────

class _BattleView extends StatefulWidget {
  final BattleMode mode;
  const _BattleView({required this.mode});
  @override
  State<_BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<_BattleView> {
  int _votesA = 64;
  int _votesB = 36;
  int? _myVote; // 0=A 1=B
  late Duration _remaining;
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
    _remaining = widget.mode.duration;
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
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _votesA + _votesB;
    final pA = _votesA / total;
    final pB = _votesB / total;
    final voted = _myVote != null;
    final expired = _remaining.inSeconds == 0;

    return Scaffold(
      backgroundColor: AuraTheme.themeBg,
      appBar: AppBar(
        backgroundColor: AuraTheme.themeBg,
        title: Row(children: [
          Text(widget.mode.icon,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('${widget.mode.label}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AuraTheme.themeTextPrimary)),
        ]),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AuraTheme.themeTextPrimary),
            onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Mode + Timer chip row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Text(widget.mode.desc,
                  style: const TextStyle(
                      color: AuraTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: expired
                    ? Colors.redAccent.withOpacity(0.12)
                    : AuraTheme.themeCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    expired
                        ? Icons.timer_off_rounded
                        : Icons.timer_outlined,
                    size: 13,
                    color: expired
                        ? Colors.redAccent
                        : AuraTheme.themeTextMuted),
                const SizedBox(width: 5),
                Text(
                    expired
                        ? 'Battle ended'
                        : 'ends in ${_fmtTime(_remaining)}',
                    style: TextStyle(
                        color: expired
                            ? Colors.redAccent
                            : AuraTheme.themeTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
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
                      color: AuraTheme.themeTextMuted.withOpacity(0.6))),
            ),
            Expanded(child: _card(_songB, 1, voted && _votesB > _votesA)),
          ]),
          const SizedBox(height: 28),

          // Vote bar
          if (voted) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('votes',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AuraTheme.themeTextPrimary)),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 34,
                child: Stack(children: [
                  Container(
                      color: AuraTheme.themeSurface, height: 34),
                  AnimatedFractionallySizedBox(
                    widthFactor: pA,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: Container(color: AuraTheme.accent),
                  ),
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
                                    ? AuraTheme.themeTextPrimary
                                    : AuraTheme.themeTextMuted,
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
                style: TextStyle(
                    color: AuraTheme.themeTextMuted,
                    fontSize: 12)),
          ],

          const Spacer(),
          if (!voted && !expired)
            Text('tap a song to cast your vote',
                style: TextStyle(
                    color: AuraTheme.themeTextMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          if (expired)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: AuraTheme.themeCard,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏆 ', style: TextStyle(fontSize: 20)),
                Text(
                    _votesA > _votesB
                        ? '${_songA['title']} wins!'
                        : '${_songB['title']} wins!',
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ]),
            ),
          if (voted && !expired && _myVote == 0)
            Text('you voted for ${_songA['title']}',
                style: const TextStyle(
                    color: AuraTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          if (voted && !expired && _myVote == 1)
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
                  : AuraTheme.themeCard,
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
                  color: picked
                      ? Colors.white
                      : AuraTheme.themeTextPrimary)),
          const SizedBox(height: 4),
          Text(song['artist']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: picked
                      ? Colors.white.withOpacity(0.75)
                      : AuraTheme.themeTextMuted)),
          if (winning) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: picked
                    ? Colors.white.withOpacity(0.25)
                    : AuraTheme.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('leading 🔥',
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
