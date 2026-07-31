import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'campfire_chat_screen.dart';
import 'collab_playlist_screen.dart';
import 'song_battle_screen.dart';
import 'create_campfire_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class CampfireGroup {
  final String id;
  final String name;
  final String emoji;
  final String lastMessage;
  final String lastSender;
  final String timeAgo;
  final int unreadCount;
  final bool isLive;
  final bool isSecret;
  final Color bgColor;
  final bool isOwn;
  final String? pin;

  const CampfireGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lastMessage,
    required this.lastSender,
    required this.timeAgo,
    this.unreadCount = 0,
    this.isLive = false,
    this.isSecret = false,
    required this.bgColor,
    this.isOwn = false,
    this.pin,
  });
}

// ── Ember particle model ──────────────────────────────────────────────────────

class _Ember {
  final double x;      // 0..1 normalized
  final double y0;     // start y (0..1, bottom biased)
  final double size;
  final double speed;
  final double drift;  // x oscillation amplitude
  final double phase;  // oscillation phase offset
  final Color color;

  const _Ember({
    required this.x, required this.y0, required this.size,
    required this.speed, required this.drift, required this.phase,
    required this.color,
  });
}

List<_Ember> _buildEmbers(int count) {
  final rng = math.Random(42);
  const colors = [
    Color(0xFFFF6B00), Color(0xFFFF8C42), Color(0xFFFFB347),
    Color(0xFFFF4500), Color(0xFFFF3300), Color(0xFFFFCC44),
  ];
  return List.generate(count, (_) => _Ember(
    x: rng.nextDouble(),
    y0: 0.5 + rng.nextDouble() * 0.5,
    size: 1.2 + rng.nextDouble() * 2.8,
    speed: 0.06 + rng.nextDouble() * 0.14,
    drift: 0.008 + rng.nextDouble() * 0.018,
    phase: rng.nextDouble() * math.pi * 2,
    color: colors[rng.nextInt(colors.length)],
  ));
}

// ── Fire particle painter ─────────────────────────────────────────────────────

class _FireParticlePainter extends CustomPainter {
  final double t;
  final List<_Ember> embers;
  _FireParticlePainter({required this.t, required this.embers});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in embers) {
      // y: drift upward from y0, loop when it reaches top
      final progress = (t * e.speed + e.y0) % 1.0;
      final y = size.height * (1.0 - progress);
      final x = size.width * (e.x + e.drift * math.sin(t * 2 * math.pi + e.phase));
      // Fade: bright near bottom, dim near top
      final fade = progress < 0.2
          ? progress / 0.2
          : progress > 0.75
              ? (1.0 - progress) / 0.25
              : 1.0;
      final paint = Paint()
        ..color = e.color.withOpacity(0.55 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), e.size * fade, paint);
    }
  }

  @override
  bool shouldRepaint(_FireParticlePainter old) => old.t != t;
}

// ── Pulsing glow ring painter (for LIVE tiles) ────────────────────────────────

class _PulseRingPainter extends CustomPainter {
  final double pulse; // 0..1
  _PulseRingPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // Outer glow pulse
    final outerPaint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.12 + 0.18 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r + 8 * pulse, outerPaint);
    // Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.4 + 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, r + 2, ringPaint);
  }

  @override
  bool shouldRepaint(_PulseRingPainter old) => old.pulse != old.pulse;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class CampfireScreen extends StatefulWidget {
  const CampfireScreen({super.key});

  @override
  State<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends State<CampfireScreen>
    with TickerProviderStateMixin {
  late final AnimationController _emberCtrl;
  late final AnimationController _pulseCtrl;
  final _embers = _buildEmbers(28);

  static const _defaultGroups = [
    CampfireGroup(
      id: '1', name: 'late night sessions', emoji: '🌙',
      lastMessage: 'this song is sending me rn', lastSender: 'maya',
      timeAgo: '2m', unreadCount: 5, isLive: true,
      bgColor: Color(0xFF6C63FF),
    ),
    CampfireGroup(
      id: '2', name: 'sunday chill squad', emoji: '☀️',
      lastMessage: "dropped a playlist for y'all", lastSender: 'zoe',
      timeAgo: '14m', unreadCount: 2, bgColor: Color(0xFFFF7A50),
    ),
    CampfireGroup(
      id: '3', name: 'deep focus 🎧', emoji: '🎧',
      lastMessage: 'lofi + lo-key vibing', lastSender: 'alex',
      timeAgo: '1h', bgColor: Color(0xFF00BCD4),
    ),
    CampfireGroup(
      id: '4', name: 'college crew', emoji: '🎓',
      lastMessage: 'anyone on for tonight?', lastSender: 'sam',
      timeAgo: '3h', unreadCount: 12, bgColor: Color(0xFF4CAF50),
    ),
    CampfireGroup(
      id: '5', name: 'hype house', emoji: '⚡',
      lastMessage: 'NEW DROP 🔥🔥🔥', lastSender: 'leo',
      timeAgo: '5h', bgColor: Color(0xFFFF8C42),
    ),
    CampfireGroup(
      id: '6', name: 'no one can find this 🔒', emoji: '🤫',
      lastMessage: 'invite only — shhh', lastSender: 'maya',
      timeAgo: '10m', unreadCount: 3, isSecret: true,
      bgColor: Color(0xFF2D3436),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _emberCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emberCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<CampfireGroup> _allGroups() {
    final userCampfires = OrbitState().myCampfires.map((c) => CampfireGroup(
      id: c['id'] ?? '',
      name: c['name'] ?? 'untitled',
      emoji: c['emoji'] ?? '🔥',
      lastMessage: 'you created this campfire',
      lastSender: 'you',
      timeAgo: 'just now',
      isLive: c['isLive'] == true,
      isSecret: c['pin'] != null,
      bgColor: AuraTheme.accent,
      isOwn: true,
      pin: c['pin'] as String?,
    )).toList();
    return [...userCampfires, ..._defaultGroups];
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const CreateCampfireScreen()));
    if (created == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final groups = _allGroups();
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(
        children: [
          // ── Plasma wave background ─────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _emberCtrl,
              builder: (_, __) => CustomPaint(
                painter: _PlasmaWavePainter(_emberCtrl.value),
              ),
            ),
          ),

          // ── Ambient fire particles ──────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _emberCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FireParticlePainter(
                    t: _emberCtrl.value, embers: _embers),
              ),
            ),
          ),

          // ── Scanline overlay ───────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),

          // ── Content ────────────────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                backgroundColor: AuraTheme.background.withOpacity(0.92),
                elevation: 0,
                title: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF4500), Color(0xFFFFB347)],
                  ).createShader(b),
                  child: const Text(
                    'CAMPFIRE',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                      ).createShader(b),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white),
                    ),
                    tooltip: 'Song Battle',
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SongBattleScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: AuraTheme.textSecondary),
                    onPressed: () {},
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0xFFFF6B00), Color(0xFFFF4500), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),

              // ── Live now strip ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildLiveStrip(groups),
              ),

              // ── Group list ──────────────────────────────────────────────
              groups.isEmpty
                  ? SliverFillRemaining(child: _buildEmpty())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _EmberTile(
                          group: groups[i],
                          pulseCtrl: _pulseCtrl,
                          onDeleted: groups[i].isOwn
                              ? () => setState(() {
                                    OrbitState().myCampfires.removeWhere(
                                        (c) => c['id'] == groups[i].id);
                                    OrbitState().save();
                                  })
                              : null,
                        ),
                        childCount: groups.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButton: GestureDetector(
        onTap: _openCreate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B00), Color(0xFFFF4500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'NEW_CAMPFIRE',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLiveStrip(List<CampfireGroup> groups) {
    final live = groups.where((g) => g.isLive).toList();
    if (live.isEmpty) return const SizedBox(height: 8);
    return Container(
      height: 88,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: live.length,
        itemBuilder: (_, i) => _LiveChip(
          group: live[i], pulseCtrl: _pulseCtrl,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
          ).createShader(b),
          child: const Text('🔥', style: TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: 14),
        const Text(
          'NO_CAMPFIRES_YET',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: AuraTheme.textMuted,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
      ]),
    );
  }
}

// ── Live strip chip ───────────────────────────────────────────────────────────

class _LiveChip extends StatelessWidget {
  final CampfireGroup group;
  final AnimationController pulseCtrl;
  const _LiveChip({required this.group, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CampfireChatScreen(group: group))),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 64,
        child: Column(children: [
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) => CustomPaint(
              painter: _PulseRingPainter(pulseCtrl.value),
              child: child,
            ),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: group.bgColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6B00).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(group.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4500).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFF4500).withOpacity(0.5)),
            ),
            child: const Text(
              '● LIVE',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF6B00),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            group.name,
            style: const TextStyle(fontSize: 9, color: AuraTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

// ── Ember tile ────────────────────────────────────────────────────────────────

class _EmberTile extends StatelessWidget {
  final CampfireGroup group;
  final AnimationController pulseCtrl;
  final VoidCallback? onDeleted;
  const _EmberTile({
    required this.group,
    required this.pulseCtrl,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CampfireChatScreen(group: group))),
      onLongPress: onDeleted != null
          ? () => showModalBottomSheet(
                context: context,
                backgroundColor: AuraTheme.card,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: Text('Delete "${group.name}"'),
                      onTap: () {
                        Navigator.pop(ctx);
                        onDeleted!();
                      },
                    ),
                  ]),
                ),
              )
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.card.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: group.isOwn
                ? const Color(0xFFFF6B00).withOpacity(0.4)
                : group.isSecret
                    ? AuraTheme.textMuted.withOpacity(0.15)
                    : group.bgColor.withOpacity(0.2),
            width: group.isOwn ? 1.5 : 1,
          ),
          boxShadow: group.isLive
              ? [BoxShadow(
                  color: const Color(0xFFFF6B00).withOpacity(0.12),
                  blurRadius: 16, spreadRadius: 0,
                )]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar with optional pulse ring
            SizedBox(
              width: 56,
              height: 56,
              child: group.isLive
                  ? AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (_, child) => CustomPaint(
                        painter: _PulseRingPainter(pulseCtrl.value),
                        child: child,
                      ),
                      child: _hexAvatar(),
                    )
                  : _hexAvatar(),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (group.isOwn)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                        ).createShader(b),
                        child: const Icon(Icons.star_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  if (group.isSecret && !group.isOwn)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_rounded, size: 12, color: AuraTheme.textMuted),
                    ),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (group.isLive)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4500).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFF4500).withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        '● LIVE',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: Color(0xFFFF6B00),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ]),
                const SizedBox(height: 3),
                Text(
                  '${group.lastSender}: ${group.lastMessage}',
                  style: TextStyle(
                    color: group.unreadCount > 0 ? AuraTheme.textPrimary : AuraTheme.textMuted,
                    fontSize: 12,
                    fontWeight: group.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),

            // Time + badge
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                group.timeAgo,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: AuraTheme.textMuted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 5),
              if (group.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF4500)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ]),
          ]),

          // ── HUD data row ──────────────────────────────────────────
          const SizedBox(height: 10),
          Row(children: [
            _HudTag('MBR', '4'),
            const SizedBox(width: 10),
            _HudTag('TEMP', group.isLive ? '🔥🔥🔥' : '🔥'),
            const Spacer(),
            _ActivityBars(isLive: group.isLive),
          ]),

          // Collab playlist strip
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                group.bgColor.withOpacity(0.3),
                Colors.transparent,
              ]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CollabPlaylistScreen(group: group))),
            child: Row(children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                ).createShader(b),
                child: const Icon(Icons.queue_music_rounded, size: 13, color: Colors.white),
              ),
              const SizedBox(width: 5),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                ).createShader(b),
                child: const Text(
                  'COLLAB_PLAYLIST',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 14, color: AuraTheme.textMuted),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _avatarContent() {
    return CustomPaint(
      painter: _HexBorderPainter(
        fillColor: group.bgColor.withOpacity(0.18),
        borderColor: group.isLive
            ? const Color(0xFFFF6B00).withOpacity(0.65)
            : group.bgColor.withOpacity(0.45),
        glowColor: group.isLive
            ? const Color(0xFFFF6B00).withOpacity(0.18)
            : Colors.transparent,
      ),
      child: const SizedBox(
        width: 56, height: 56,
        child: Center(child: Text('', style: TextStyle(fontSize: 22))),
      ),
    );
  }

  // Separate helper so the emoji is always visible
  Widget _hexAvatar() {
    return SizedBox(
      width: 56, height: 56,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          painter: _HexBorderPainter(
            fillColor: group.bgColor.withOpacity(0.18),
            borderColor: group.isLive
                ? const Color(0xFFFF6B00).withOpacity(0.65)
                : group.bgColor.withOpacity(0.45),
            glowColor: group.isLive
                ? const Color(0xFFFF6B00).withOpacity(0.18)
                : Colors.transparent,
          ),
          child: const SizedBox(width: 56, height: 56),
        ),
        Text(group.emoji, style: const TextStyle(fontSize: 22)),
      ]),
    );
  }
}

// ── Plasma wave background ─────────────────────────────────────────────────────

class _PlasmaWavePainter extends CustomPainter {
  final double t;
  _PlasmaWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int w = 0; w < 3; w++) {
      final amp = 22.0 + w * 12;
      final freq = 1.4 + w * 0.6;
      final phase = t * 2 * math.pi * (0.35 + w * 0.18);
      final yBase = size.height * (0.52 + w * 0.14);
      final opacity = 0.038 + w * 0.012;
      final paint = Paint()
        ..color = const Color(0xFFFF6B00).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 4) {
        final y = yBase +
            amp * math.sin(x / size.width * freq * math.pi * 2 + phase) +
            (amp * 0.4) * math.sin(x / size.width * (freq * 2.3) * math.pi * 2 + phase * 1.5);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PlasmaWavePainter old) => old.t != t;
}

// ── Scanline overlay ──────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.022)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Hex border painter ────────────────────────────────────────────────────────

class _HexBorderPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color glowColor;
  const _HexBorderPainter({
    required this.fillColor,
    required this.borderColor,
    required this.glowColor,
  });

  Path _hexPath(Size size, double inset) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width / 2) - inset;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Glow halo
    if (glowColor != Colors.transparent) {
      canvas.drawPath(
        _hexPath(size, -4),
        Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    // Border hex
    canvas.drawPath(_hexPath(size, 0), Paint()..color = borderColor);
    // Fill hex
    canvas.drawPath(_hexPath(size, 2.5), Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(_HexBorderPainter old) =>
      old.fillColor != fillColor || old.borderColor != borderColor;
}

// ── HUD tag ───────────────────────────────────────────────────────────────────

class _HudTag extends StatelessWidget {
  final String label;
  final String value;
  const _HudTag(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label:',
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 7,
          color: AuraTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(width: 3),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 7,
          color: Color(0xFFFF8C42),
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

// ── Activity bars ─────────────────────────────────────────────────────────────

class _ActivityBars extends StatelessWidget {
  final bool isLive;
  const _ActivityBars({required this.isLive});

  static const _liveH = [10.0, 14.0, 8.0, 13.0, 6.0, 12.0, 9.0, 14.0];
  static const _idleH = [4.0, 6.0, 4.0, 7.0, 4.0, 5.0, 4.0, 6.0];

  @override
  Widget build(BuildContext context) {
    final heights = isLive ? _liveH : _idleH;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(8, (i) => Container(
        width: 2.5,
        height: heights[i],
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: isLive
              ? const Color(0xFFFF6B00).withOpacity(0.28 + i * 0.06)
              : AuraTheme.textMuted.withOpacity(0.15 + (i % 3) * 0.04),
          borderRadius: BorderRadius.circular(1),
        ),
      )),
    );
  }
}
