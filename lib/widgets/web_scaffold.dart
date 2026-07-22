import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/aura_theme.dart';
import '../models/orbit_state.dart';
import '../screens/home/home_screen.dart';
import '../screens/campfire/campfire_screen.dart';
import '../screens/find/find_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/home/vibe_picker_sheet.dart';
import '../screens/reels/pulse_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level responsive wrapper
// ─────────────────────────────────────────────────────────────────────────────

class ResponsiveRoot extends StatelessWidget {
  const ResponsiveRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth > 800) return const WebShell();
        return const MobileNav();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile nav — premium dark bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class MobileNav extends StatefulWidget {
  const MobileNav({super.key});
  @override
  State<MobileNav> createState() => _MobileNavState();
}

class _MobileNavState extends State<MobileNav> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: IndexedStack(index: _tab, children: const [
        HomeScreen(),
        CampfireScreen(),
        PulseScreen(),
        FindScreen(),
        ProfileScreen(),
      ]),
      bottomNavigationBar: _PremiumBottomNav(
        selectedIndex: _tab,
        onTap: (i) {
          HapticFeedback.lightImpact();
          setState(() => _tab = i);
        },
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _PremiumBottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.graphic_eq_rounded,         'home'),
    (Icons.local_fire_department_rounded, 'campfire'),
    (Icons.play_circle_rounded,          'pulse'),
    (Icons.auto_awesome_rounded,         'find'),
    (Icons.person_rounded,               'self'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A18),
        border: const Border(top: BorderSide(color: Color(0xFF1A1A2E), width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 42,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? AuraTheme.accent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _items[i].$1,
                        size: 22,
                        color: selected ? AuraTheme.accent : AuraTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _items[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AuraTheme.accent : AuraTheme.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Shell
// ─────────────────────────────────────────────────────────────────────────────

class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _tab = 0;

  static const _navItems = [
    _NavItem(Icons.graphic_eq_rounded,            'Home'),
    _NavItem(Icons.local_fire_department_rounded, 'Campfire'),
    _NavItem(Icons.play_circle_rounded,           'Pulse'),
    _NavItem(Icons.auto_awesome_rounded,          'Find'),
    _NavItem(Icons.chat_bubble_rounded,           'Messages'),
    _NavItem(Icons.person_rounded,                'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final initial = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'Y';

    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Row(
        children: [
          // ── Left sidebar ────────────────────────────────────────────
          _Sidebar(
            tab: _tab,
            items: _navItems,
            initial: initial,
            pfpFile: state.pfpFile,
            onTabChange: (i) => setState(() => _tab = i),
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: Container(
              color: AuraTheme.background,
              child: IndexedStack(index: _tab, children: const [
                HomeScreen(),
                CampfireScreen(),
                PulseScreen(),
                FindScreen(),
                MessagesScreen(),
                ProfileScreen(),
              ]),
            ),
          ),

          // ── Right panel ─────────────────────────────────────────────
          _RightPanel(onVibeChange: () => setState(() {})),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _Sidebar extends StatelessWidget {
  final int tab;
  final List<_NavItem> items;
  final String initial;
  final dynamic pfpFile;
  final ValueChanged<int> onTabChange;
  final VoidCallback onSettings;

  const _Sidebar({
    required this.tab,
    required this.items,
    required this.initial,
    required this.pfpFile,
    required this.onTabChange,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C0C1A), Color(0xFF080810)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(right: BorderSide(color: Color(0xFF14142A), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          // Orbit logo
          const _OrbitLogo(),
          const SizedBox(height: 22),
          // Nav items
          for (int i = 0; i < items.length; i++)
            _SidebarBtn(
              item: items[i],
              selected: tab == i,
              onTap: () => onTabChange(i),
            ),
          const Spacer(),
          // Settings
          _SidebarBtn(
            item: const _NavItem(Icons.settings_outlined, 'Settings'),
            selected: false,
            onTap: onSettings,
          ),
          const SizedBox(height: 10),
          // Avatar
          GestureDetector(
            onTap: () => onTabChange(5),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AuraTheme.accent, AuraTheme.accentLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AuraTheme.accent.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
                image: pfpFile != null
                    ? DecorationImage(
                        image: FileImage(pfpFile as dynamic),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: pfpFile == null
                  ? Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBtn extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarBtn({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: AuraTheme.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? AuraTheme.accent.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AuraTheme.accent.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Stack(
            children: [
              // Left glow bar for selected
              if (selected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AuraTheme.accent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AuraTheme.accent.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              // Icon centered
              Center(
                child: Icon(
                  item.icon,
                  size: 22,
                  color: selected ? AuraTheme.accent : AuraTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orbit logo mark
// ─────────────────────────────────────────────────────────────────────────────

class _OrbitLogo extends StatelessWidget {
  const _OrbitLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 40),
      painter: _OrbitLogoPainter(),
    );
  }
}

class _OrbitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Background rounded square with gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E1040), Color(0xFF0F0830)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(11),
      ),
      bgPaint,
    );

    // Outer orbit ring
    final outerOrbit = Paint()
      ..color = AuraTheme.accent.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.4, outerOrbit);

    // Inner orbit ring (tilted ellipse)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-0.5);
    final ellipseOrbit = Paint()
      ..color = AuraTheme.purple.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.72,
        height: size.height * 0.28,
      ),
      ellipseOrbit,
    );
    canvas.restore();

    // Center sun dot (glowing)
    final sunGlow = Paint()
      ..color = AuraTheme.accent.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx, cy), 8, sunGlow);

    final sun = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD080), AuraTheme.accent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 5));
    canvas.drawCircle(Offset(cx, cy), 4.5, sun);

    // Orbiting dot
    const angle = -math.pi / 5;
    final orbitDotX = cx + math.cos(angle) * size.width * 0.4;
    final orbitDotY = cy + math.sin(angle) * size.width * 0.4;

    final dotGlow = Paint()
      ..color = AuraTheme.cyan.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(orbitDotX, orbitDotY), 4, dotGlow);

    final dot = Paint()..color = AuraTheme.cyan;
    canvas.drawCircle(Offset(orbitDotX, orbitDotY), 2.5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Right panel
// ─────────────────────────────────────────────────────────────────────────────

class _RightPanel extends StatefulWidget {
  final VoidCallback onVibeChange;
  const _RightPanel({required this.onVibeChange});

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  final _s = OrbitState();

  static const _trending = [
    ('🌙', '2am feels',      '4.2k'),
    ('🔥', 'hypehouse',      '3.8k'),
    ('✨', 'euphoric',       '2.1k'),
    ('🎬', 'main character', '1.9k'),
    ('🎧', 'in the zone',   '1.4k'),
  ];

  static const _suggestions = [
    ('Karan M', '🌙 2am feels',        Color(0xFFE74C3C)),
    ('Dev S',   '🎧 in the zone',      Color(0xFF3498DB)),
    ('Ananya T','✨ euphoric',          Color(0xFFFF69B4)),
  ];

  final Set<String> _synced = {};

  String _vibeCountdown() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A16),
        border: Border(left: BorderSide(color: Color(0xFF14142A), width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        children: [
          // ── Vibe card ─────────────────────────────────────────────
          _sectionLabel('YOUR VIBE TODAY'),
          GestureDetector(
            onTap: () async {
              await showVibePicker(context, todayMode: true);
              setState(() {});
              widget.onVibeChange();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF4500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AuraTheme.accent.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_s.moodEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    _s.mood,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'resets in ${_vibeCountdown()}',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'change vibe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Streak ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161220),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AuraTheme.accent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '12-day streak',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AuraTheme.accent,
                        ),
                      ),
                      const Text(
                        'send a clip to keep it going',
                        style: TextStyle(fontSize: 9, color: AuraTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Trending ─────────────────────────────────────────────
          _sectionLabel('TRENDING VIBES'),
          const SizedBox(height: 4),
          for (int i = 0; i < _trending.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: i == 0
                            ? AuraTheme.accent
                            : i == 1
                                ? AuraTheme.accentLight
                                : AuraTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _trending[i].$1,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _trending[i].$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AuraTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _trending[i].$3,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AuraTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),
          Container(height: 0.5, color: const Color(0xFF1E1E30)),
          const SizedBox(height: 12),

          // ── Sync suggestions ──────────────────────────────────────
          _sectionLabel('SYNC WITH'),
          const SizedBox(height: 4),
          for (final sug in _suggestions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [sug.$3, sug.$3.withOpacity(0.6)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        sug.$1[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sug.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AuraTheme.textPrimary,
                          ),
                        ),
                        Text(
                          sug.$2,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AuraTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        if (_synced.contains(sug.$1)) {
                          _synced.remove(sug.$1);
                        } else {
                          _synced.add(sug.$1);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _synced.contains(sug.$1)
                            ? const Color(0xFF1E1E30)
                            : AuraTheme.accent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _synced.contains(sug.$1)
                            ? []
                            : [
                                BoxShadow(
                                  color: AuraTheme.accent.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Text(
                        _synced.contains(sug.$1) ? '✓' : '+ sync',
                        style: TextStyle(
                          color: _synced.contains(sug.$1)
                              ? AuraTheme.textMuted
                              : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AuraTheme.textMuted,
          ),
        ),
      );
}
