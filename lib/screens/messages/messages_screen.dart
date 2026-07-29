// ORBIT_MSG_v2 — futuristic chat hub
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/aura_theme.dart';
import '../home/dm_screen.dart';
import '../pocket/pocket_screen.dart';
import '../../widgets/orb_empty_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  late TabController _tab;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  // ── Demo data ──────────────────────────────────────────────────────
  final _dms = const [
    _DMData('Silver Tide',  '🌿', Color(0xFF22D3EE), 'CALM',   '3', true,  '11:42p'),
    _DMData('Amber Wisp',   '🌸', Color(0xFFE879F9), 'HAPPY',  '1', true,  '9:18p'),
    _DMData('Velvet Storm', '🌟', Color(0xFF7C3AED), 'ENERGY', '0', false, 'Mon'),
    _DMData('Cosmic Shore', '🔥', Color(0xFFFF6B00), 'FOCUS',  '0', true,  'Sun'),
    _DMData('Pale Ember',   '💫', Color(0xFF34D399), 'VIBE',   '5', false, 'Fri'),
  ];

  final _circles = const [
    _CircleData('Late Night Crew',  ['S', 'A', 'V'], Color(0xFF7C3AED), 3, 'Blinding Lights',   true),
    _CircleData('Study Buddies',    ['C', 'P', 'G'], Color(0xFF22D3EE), 5, 'lo-fi beats 2 study', false),
    _CircleData('Sunset Sessions',  ['J', 'M', 'R'], Color(0xFFEC4899), 4, 'Golden Hour',        true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildTabSelector(),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _DMsView(dms: _dms),
              _CirclesView(circles: _circles),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader() => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'ORBIT // CHAT',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              letterSpacing: 2.5,
              color: AuraTheme.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AuraTheme.purple, AuraTheme.cyan],
            ).createShader(b),
            child: const Text(
              'Messages',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ]),
        const Spacer(),
        // Pocket button
        Tooltip(
          message: 'The Pocket — private spaces',
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PocketScreen())),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AuraTheme.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuraTheme.cyan.withOpacity(0.25)),
              ),
              child: const Icon(Icons.bubble_chart_rounded,
                  color: AuraTheme.cyan, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Compose button
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AuraTheme.purple, AuraTheme.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: AuraTheme.glowShadow(color: AuraTheme.purple, radius: 10),
          ),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
        ),
      ]),
    ),
  );

  // ── Search bar ────────────────────────────────────────────────────

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Container(
      height: 42,
      decoration: BoxDecoration(
        color: AuraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuraTheme.purple.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _search,
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 12,
          color: AuraTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'SEARCH_ORBIT...',
          hintStyle: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 12,
            color: AuraTheme.textMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AuraTheme.textMuted, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  // ── Tab selector ──────────────────────────────────────────────────

  Widget _buildTabSelector() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: AuraTheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        _TabPill(label: 'DIRECT',  index: 0, tab: _tab),
        _TabPill(label: 'CIRCLES', index: 1, tab: _tab),
      ]),
    ),
  );
}

// ── Tab pill ────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final int index;
  final TabController tab;
  const _TabPill({required this.label, required this.index, required this.tab});

  @override
  Widget build(BuildContext context) {
    final active = tab.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => tab.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AuraTheme.purple, Color(0xFF2563EB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [BoxShadow(color: AuraTheme.purple.withOpacity(0.3), blurRadius: 8)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: active ? Colors.white : AuraTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ── DMs View ─────────────────────────────────────────────────────────

class _DMsView extends StatelessWidget {
  final List<_DMData> dms;
  const _DMsView({required this.dms});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _ActiveOrbitStrip(dms: dms)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'RECENT_TRANSMISSIONS',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                letterSpacing: 2,
                color: AuraTheme.textMuted,
              ),
            ),
          ),
        ),
        if (uid != null)
          _FirestoreDMSliver(uid: uid, localDms: dms)
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ConvTile(
                data: dms[i],
                onTap: () => _openDM(ctx, dms[i]),
              ).animate(delay: (i * 55).ms).fadeIn().slideX(begin: 0.05),
              childCount: dms.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _openDM(BuildContext context, _DMData d) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DMScreen(
        username: '@${d.name.toLowerCase().replaceAll(' ', '.')}',
        displayName: d.name,
      ),
    ),
  );
}

// ── Active orbit strip ───────────────────────────────────────────────

class _ActiveOrbitStrip extends StatefulWidget {
  final List<_DMData> dms;
  const _ActiveOrbitStrip({required this.dms});

  @override
  State<_ActiveOrbitStrip> createState() => _ActiveOrbitStripState();
}

class _ActiveOrbitStripState extends State<_ActiveOrbitStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.dms.where((d) => d.isOnline).toList();
    if (online.isEmpty) return const SizedBox(height: 12);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(children: [
          Text(
            'IN_ORBIT',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              letterSpacing: 2,
              color: AuraTheme.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AuraTheme.cyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${online.length} active',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 8,
                color: AuraTheme.cyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
      SizedBox(
        height: 78,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: online.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => _OrbitalAvatar(data: online[i], ring: _ring),
        ),
      ),
    ]);
  }
}

class _OrbitalAvatar extends StatelessWidget {
  final _DMData data;
  final Animation<double> ring;
  const _OrbitalAvatar({required this.data, required this.ring});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: 56,
        height: 56,
        child: AnimatedBuilder(
          animation: ring,
          builder: (_, child) => CustomPaint(
            painter: _RingPainter(progress: ring.value, color: data.color),
            child: child,
          ),
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  data.name[0],
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        data.name.split(' ')[0],
        style: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 8,
          color: AuraTheme.textSecondary,
        ),
      ),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2.5;
    canvas.drawCircle(c, r, Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      progress * math.pi * 2 - math.pi / 2,
      math.pi * 1.3,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [color.withOpacity(0.0), color],
          stops: const [0.65, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ── Conv tile ────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final _DMData data;
  final VoidCallback onTap;
  const _ConvTile({required this.data, required this.onTap});

  bool get _hasUnread => data.unread != '0' && data.unread.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasUnread
                ? data.color.withOpacity(0.3)
                : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(children: [
          // Avatar + online dot
          Stack(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withOpacity(0.14),
                border: Border.all(color: data.color.withOpacity(0.35), width: 1.5),
              ),
              child: Center(
                child: Text(
                  data.name[0],
                  style: TextStyle(
                    color: data.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            if (data.isOnline)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AuraTheme.cyan,
                    shape: BoxShape.circle,
                    border: Border.all(color: AuraTheme.card, width: 2),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 12),

          // Name + mood + preview
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(
                  data.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _hasUnread ? AuraTheme.textPrimary : AuraTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data.mood,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 7,
                      letterSpacing: 0.5,
                      color: data.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text(
                '${data.emoji}  listening now',
                style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),

          const SizedBox(width: 8),

          // Timestamp + badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              data.timestamp,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AuraTheme.textMuted,
              ),
            ),
            const SizedBox(height: 5),
            if (_hasUnread)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    data.unread,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
          ]),
        ]),
      ),
    );
  }
}

// ── Firestore DM sliver ──────────────────────────────────────────────

class _FirestoreDMSliver extends StatelessWidget {
  final String uid;
  final List<_DMData> localDms;
  const _FirestoreDMSliver({required this.uid, required this.localDms});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: AuraTheme.purple, strokeWidth: 2),
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        final allItems = <Widget>[];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final parts = List<String>.from(data['participants'] ?? []);
          final otherUid = parts.firstWhere((p) => p != uid, orElse: () => '');
          final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
          final otherName = names[otherUid]?.toString() ?? 'User';
          final lastMsg = data['lastMessage']?.toString() ?? '';
          final idx = allItems.length;

          allItems.add(
            GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => DMScreen(
                  username: '@${otherName.toLowerCase().replaceAll(' ', '.')}',
                  displayName: otherName,
                  targetUid: otherUid,
                ),
              )),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraTheme.purple.withOpacity(0.14),
                      border: Border.all(color: AuraTheme.purple.withOpacity(0.35), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AuraTheme.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(otherName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(lastMsg,
                        style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AuraTheme.textMuted, size: 16),
                ]),
              ),
            ).animate(delay: (idx * 55).ms).fadeIn().slideX(begin: 0.05),
          );
        }

        // Local demo DMs
        for (int i = 0; i < localDms.length; i++) {
          final d = localDms[i];
          allItems.add(
            _ConvTile(
              data: d,
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => DMScreen(
                  username: '@${d.name.toLowerCase().replaceAll(' ', '.')}',
                  displayName: d.name,
                ),
              )),
            ).animate(delay: ((docs.length + i) * 55).ms).fadeIn().slideX(begin: 0.05),
          );
        }

        if (allItems.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyDMsState(
              onFind: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => allItems[i],
            childCount: allItems.length,
          ),
        );
      },
    );
  }
}

// ── Circles View ─────────────────────────────────────────────────────

class _CirclesView extends StatelessWidget {
  final List<_CircleData> circles;
  const _CirclesView({required this.circles});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // Start new orbit button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AuraTheme.purple.withOpacity(0.12),
                  AuraTheme.cyan.withOpacity(0.12),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AuraTheme.purple.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                    color: AuraTheme.purple, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'START_NEW_ORBIT',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
                      letterSpacing: 1,
                      color: AuraTheme.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            'ACTIVE_CIRCLES',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              letterSpacing: 2,
              color: AuraTheme.textMuted,
            ),
          ),
        ),

        ...circles.asMap().entries.map((e) =>
          _CircleCard(data: e.value)
            .animate(delay: (e.key * 80).ms).fadeIn().slideY(begin: 0.05)),

        const SizedBox(height: 100),
      ],
    );
  }
}

class _CircleCard extends StatelessWidget {
  final _CircleData data;
  const _CircleCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Multi-avatar cluster
            SizedBox(
              width: 54,
              height: 30,
              child: Stack(
                children: data.previewInitials.take(3).toList().asMap().entries.map((e) =>
                  Positioned(
                    left: e.key * 15.0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: data.color.withOpacity(0.2),
                        border: Border.all(color: AuraTheme.card, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: data.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AuraTheme.textPrimary,
                    ),
                  ),
                  if (data.isLive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 7,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ]),
                Text(
                  '${data.memberCount} members',
                  style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AuraTheme.textMuted, size: 16),
          ]),

          const SizedBox(height: 10),

          // Now Playing strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: data.color.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.music_note_rounded, size: 11, color: data.color),
              const SizedBox(width: 5),
              Text(
                'NOW · ',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 8,
                  letterSpacing: 1,
                  color: data.color,
                ),
              ),
              Expanded(
                child: Text(
                  data.nowPlaying,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AuraTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────

class _DMData {
  final String name, emoji, mood, unread, timestamp;
  final Color color;
  final bool isOnline;
  const _DMData(this.name, this.emoji, this.color, this.mood, this.unread, this.isOnline, this.timestamp);
}

class _CircleData {
  final String name, nowPlaying;
  final List<String> previewInitials;
  final Color color;
  final int memberCount;
  final bool isLive;
  const _CircleData(this.name, this.previewInitials, this.color, this.memberCount, this.nowPlaying, this.isLive);
}
