import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ── Challenge model ───────────────────────────────────────────────────────────
class _Challenge {
  final String id;
  final String emoji;
  final String title;
  final String prompt;
  final Color color;
  final int participants;
  final String endsIn;
  final List<_Reaction> topReactions;
  const _Challenge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.prompt,
    required this.color,
    required this.participants,
    required this.endsIn,
    required this.topReactions,
  });
}

class _Reaction {
  final String handle;
  final String emoji;
  final String track;
  final String artist;
  final Color color;
  const _Reaction(this.handle, this.emoji, this.track, this.artist, this.color);
}

class MusicChallengesScreen extends StatefulWidget {
  const MusicChallengesScreen({super.key});

  @override
  State<MusicChallengesScreen> createState() => _MusicChallengesScreenState();
}

class _MusicChallengesScreenState extends State<MusicChallengesScreen>
    with TickerProviderStateMixin {
  late AnimationController _glow;
  late AnimationController _ticker;
  int _active = 0;
  bool _participated = false;
  final _state = OrbitState();

  static const _challenges = [
    _Challenge(
      id: 'c1',
      emoji: '💔',
      title: 'Heartbreak Banger',
      prompt: 'Drop the song you blast after a situationship ends',
      color: Color(0xFFFF6B6B),
      participants: 2847,
      endsIn: '18h left',
      topReactions: [
        _Reaction('@maya.k', '🌸', 'drivers license', 'Olivia Rodrigo', Color(0xFFFF6B6B)),
        _Reaction('@zara.w', '🌙', 'Liability', 'Lorde', Color(0xFF7C83FD)),
        _Reaction('@dev.s', '🔥', 'Frank Ocean', 'Ivy', Color(0xFF43E97B)),
        _Reaction('@rina.p', '✨', 'Motion Sickness', 'Phoebe Bridgers', Color(0xFFFAD961)),
      ],
    ),
    _Challenge(
      id: 'c2',
      emoji: '🌙',
      title: '3AM Playlist',
      prompt: 'The song you listen to when you should 100% be asleep',
      color: Color(0xFF7C83FD),
      participants: 1923,
      endsIn: '2d left',
      topReactions: [
        _Reaction('@jay.r', '☀️', 'Blinding Lights', 'The Weeknd', Color(0xFF11998E)),
        _Reaction('@sam.w', '🎸', 'Pink + White', 'Frank Ocean', Color(0xFFFC6076)),
        _Reaction('@leo.k', '💜', 'Self Control', 'Frank Ocean', Color(0xFFA18CD1)),
      ],
    ),
    _Challenge(
      id: 'c3',
      emoji: '🧠',
      title: 'Main Character Moment',
      prompt: 'The song playing in your head when you\'re walking like the protagonist',
      color: Color(0xFFFF9A3C),
      participants: 4210,
      endsIn: '5d left',
      topReactions: [
        _Reaction('@ari.c', '🌊', 'good 4 u', 'Olivia Rodrigo', Color(0xFF4FACFE)),
        _Reaction('@mia.t', '🌸', 'Running Up That Hill', 'Kate Bush', Color(0xFFF77062)),
        _Reaction('@kai.r', '⚡', 'Kill Bill', 'SZA', Color(0xFF667EEA)),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _ticker = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _glow.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _participate(String challengeId) {
    HapticFeedback.mediumImpact();
    setState(() => _participated = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('🔥 Your track is in the mix!'),
      backgroundColor: _challenges[_active].color.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = _challenges[_active];
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(children: [
        // Animated bg
        AnimatedBuilder(
          animation: _glow,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ChallengeBgPainter(c.color, _glow.value),
          ),
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
                const Text('music challenges',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                // Live indicator
                AnimatedBuilder(
                  animation: _ticker,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(
                                0.6 + _ticker.value * 0.4),
                          )),
                      const SizedBox(width: 5),
                      const Text('LIVE',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Challenge tabs ────────────────────────────────────
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _challenges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _active == i;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _active = i;
                      _participated = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? _challenges[i].color.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? _challenges[i].color.withOpacity(0.6)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        '${_challenges[i].emoji} ${_challenges[i].title}',
                        style: TextStyle(
                          color: sel
                              ? _challenges[i].color
                              : Colors.white38,
                          fontWeight: sel
                              ? FontWeight.w800
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Active challenge card ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: c.color.withOpacity(0.35),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: c.color.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(c.emoji,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.title,
                                        style: TextStyle(
                                            color: c.color,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18)),
                                    Text(c.endsIn,
                                        style: TextStyle(
                                            color: c.color
                                                .withOpacity(0.6),
                                            fontSize: 11)),
                                  ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: c.color.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(c.participants / 1000).toStringAsFixed(1)}k',
                                style: TextStyle(
                                    color: c.color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          Text(c.prompt,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 18),
                          // Participate button
                          GestureDetector(
                            onTap: _participated
                                ? null
                                : () => _participate(c.id),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _participated
                                    ? null
                                    : LinearGradient(
                                        colors: [
                                          c.color,
                                          c.color.withOpacity(0.7)
                                        ]),
                                color: _participated
                                    ? Colors.white.withOpacity(0.07)
                                    : null,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      _participated
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      color: _participated
                                          ? Colors.white54
                                          : Colors.white,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _participated
                                        ? 'you\'re in ✦'
                                        : 'drop your track',
                                    style: TextStyle(
                                      color: _participated
                                          ? Colors.white38
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Community reactions ───────────────────────
                    Row(children: [
                      Text('community picks ✦',
                          style: TextStyle(
                              color: c.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.3)),
                      const Spacer(),
                      Text('${c.participants} vibing',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                    ]),
                    const SizedBox(height: 12),
                    ...c.topReactions.asMap().entries.map((e) =>
                      _ReactionTile(
                          reaction: e.value,
                          rank: e.key + 1,
                          accentColor: c.color)),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ReactionTile extends StatelessWidget {
  final _Reaction reaction;
  final int rank;
  final Color accentColor;
  const _ReactionTile(
      {required this.reaction,
      required this.rank,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: reaction.color.withOpacity(0.15)),
      ),
      child: Row(children: [
        // Rank
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.12),
          ),
          child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12))),
        ),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reaction.color.withOpacity(0.2),
            border: Border.all(
                color: reaction.color.withOpacity(0.4)),
          ),
          child: Center(
              child: Text(reaction.emoji,
                  style: const TextStyle(fontSize: 17))),
        ),
        const SizedBox(width: 10),
        // Track info
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reaction.handle,
                    style: TextStyle(
                        color: reaction.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
                const SizedBox(height: 2),
                Text(reaction.track,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(reaction.artist,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11)),
              ]),
        ),
        Icon(Icons.play_circle_outline_rounded,
            color: reaction.color.withOpacity(0.6), size: 22),
      ]),
    );
  }
}

class _ChallengeBgPainter extends CustomPainter {
  final Color color;
  final double t;
  const _ChallengeBgPainter(this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AuraTheme.background);
    final r = size.width * (0.6 + math.sin(t * 2 * math.pi) * 0.06);
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withOpacity(0.12),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.85, size.height * 0.12),
            radius: r)),
    );
  }

  @override
  bool shouldRepaint(_ChallengeBgPainter old) =>
      old.t != t || old.color != color;
}
