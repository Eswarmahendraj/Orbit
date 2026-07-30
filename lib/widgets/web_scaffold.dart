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
import '../screens/pocket/pocket_screen.dart';
import '../screens/ai/voice_playlist_screen.dart';

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
      body: IndexedStack(index: _tab, children: [
        const HomeScreen(),
        const CampfireScreen(),
        PulseScreen(isActive: _tab == 2),
        const FindScreen(),
        const MessagesScreen(),
        const ProfileScreen(),
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
    (Icons.graphic_eq_rounded,            'home'),
    (Icons.local_fire_department_rounded, 'campfire'),
    (Icons.play_circle_rounded,           'pulse'),
    (Icons.auto_awesome_rounded,          'find'),
    (Icons.chat_bubble_rounded,           'messages'),
    (Icons.person_rounded,                'self'),
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
  bool _showPalette = false;
  final _focusNode = FocusNode();

  static const _navItems = [
    _NavItem(Icons.graphic_eq_rounded,            'Home',     '/'),
    _NavItem(Icons.local_fire_department_rounded, 'Campfire', 'C'),
    _NavItem(Icons.play_circle_rounded,           'Pulse',    'P'),
    _NavItem(Icons.auto_awesome_rounded,          'Find',     'F'),
    _NavItem(Icons.chat_bubble_rounded,           'Messages', 'M'),
    _NavItem(Icons.person_rounded,                'Profile',  'U'),
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    final key  = event.logicalKey;

    // ⌘K / Ctrl+K → command palette
    if ((ctrl || meta) && key == LogicalKeyboardKey.keyK) {
      setState(() => _showPalette = !_showPalette);
      return KeyEventResult.handled;
    }
    // Escape → close palette
    if (key == LogicalKeyboardKey.escape && _showPalette) {
      setState(() => _showPalette = false);
      return KeyEventResult.handled;
    }
    // J/K navigation (when palette closed)
    if (!_showPalette) {
      if (key == LogicalKeyboardKey.keyJ) {
        setState(() => _tab = (_tab + 1) % _navItems.length);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyK) {
        setState(() => _tab = (_tab - 1 + _navItems.length) % _navItems.length);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final initial = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'Y';

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(children: [
        Scaffold(
          backgroundColor: AuraTheme.background,
          body: Row(children: [
            // ── Left sidebar ──────────────────────────────────────────
            _Sidebar(
              tab: _tab,
              items: _navItems,
              initial: initial,
              pfpFile: state.pfpFile,
              onTabChange: (i) => setState(() { _tab = i; _focusNode.requestFocus(); }),
              onSettings: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              onCommandPalette: () => setState(() => _showPalette = !_showPalette),
            ),

            // ── Main content ──────────────────────────────────────────
            Expanded(
              child: Container(
                color: AuraTheme.background,
                child: IndexedStack(index: _tab, children: [
                  const HomeScreen(),
                  const CampfireScreen(),
                  PulseScreen(isActive: _tab == 2),
                  const FindScreen(),
                  const MessagesScreen(),
                  const ProfileScreen(),
                ]),
              ),
            ),

            // ── Right panel ───────────────────────────────────────────
            _RightPanel(onVibeChange: () => setState(() {})),
          ]),
        ),

        // ── Command palette overlay ───────────────────────────────────
        if (_showPalette)
          _CommandPalette(
            items: _navItems,
            currentTab: _tab,
            onSelect: (i) => setState(() { _tab = i; _showPalette = false; _focusNode.requestFocus(); }),
            onDismiss: () => setState(() { _showPalette = false; _focusNode.requestFocus(); }),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final String shortcut;
  const _NavItem(this.icon, this.label, [this.shortcut = '']);
}

class _Sidebar extends StatelessWidget {
  final int tab;
  final List<_NavItem> items;
  final String initial;
  final dynamic pfpFile;
  final ValueChanged<int> onTabChange;
  final VoidCallback onSettings;
  final VoidCallback onCommandPalette;

  const _Sidebar({
    required this.tab,
    required this.items,
    required this.initial,
    required this.pfpFile,
    required this.onTabChange,
    required this.onSettings,
    required this.onCommandPalette,
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
          // The Pocket
          Tooltip(
            message: 'The Pocket — private spaces',
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PocketScreen())),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                width: 56,
                height: 38,
                decoration: BoxDecoration(
                  color: AuraTheme.cyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AuraTheme.cyan.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.bubble_chart_rounded,
                      color: AuraTheme.cyan, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Voice Playlist
          Tooltip(
            message: 'Voice Playlist — AI picks your vibe',
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VoicePlaylistScreen())),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                width: 56,
                height: 38,
                decoration: BoxDecoration(
                  color: AuraTheme.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AuraTheme.purple.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.mic_rounded,
                      color: AuraTheme.purple, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ⌘K command palette button
          Tooltip(
            message: '⌘K / Ctrl+K  Command palette',
            child: GestureDetector(
              onTap: onCommandPalette,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: AuraTheme.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AuraTheme.purple.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Text(
                    '⌘K',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AuraTheme.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Command Palette (⌘K)
// ─────────────────────────────────────────────────────────────────────────────

class _CommandPalette extends StatefulWidget {
  final List<_NavItem> items;
  final int currentTab;
  final ValueChanged<int> onSelect;
  final VoidCallback onDismiss;
  const _CommandPalette({
    required this.items,
    required this.currentTab,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  final _search = TextEditingController();
  List<(int, _NavItem)> _results = [];

  // Quick actions built in build() so they have context + callbacks

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
      ..forward();
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _results = widget.items.asMap().entries
        .map((e) => (e.key, e.value)).toList();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _anim.dispose();
    _search.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _results = widget.items.asMap().entries
          .where((e) => e.value.label.toLowerCase().contains(q))
          .map((e) => (e.key, e.value))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: () {}, // prevent dismiss when tapping inside
              child: Container(
                width: 520,
                constraints: const BoxConstraints(maxHeight: 480),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AuraTheme.purple.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AuraTheme.purple.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AuraTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AuraTheme.purple.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: Icon(Icons.search_rounded,
                                color: AuraTheme.purple, size: 18),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              autofocus: true,
                              style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 13,
                                color: AuraTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Navigate or search...',
                                hintStyle: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 13,
                                  color: AuraTheme.textMuted,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AuraTheme.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AuraTheme.textMuted.withOpacity(0.2)),
                              ),
                              child: const Text('ESC',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 9,
                                    color: AuraTheme.textMuted,
                                  )),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nav items
                    if (_results.isNotEmpty)
                      _PaletteSection(
                        label: 'NAVIGATE',
                        children: _results.map((r) {
                          final active = r.$1 == widget.currentTab;
                          return _PaletteRow(
                            icon: r.$2.icon,
                            label: r.$2.label,
                            shortcut: r.$2.shortcut,
                            active: active,
                            onTap: () => widget.onSelect(r.$1),
                          );
                        }).toList(),
                      ),

                    // Quick actions
                    if (_search.text.isEmpty)
                      _PaletteSection(
                        label: 'ACTIONS',
                        children: [
                          _PaletteRow(
                            icon: Icons.edit_rounded,
                            label: 'New Post',
                            shortcut: 'N',
                            active: false,
                            onTap: () => widget.onSelect(2), // Pulse tab
                          ),
                          _PaletteRow(
                            icon: Icons.search_rounded,
                            label: 'Find People',
                            shortcut: '/',
                            active: false,
                            onTap: () => widget.onSelect(3), // Find tab
                          ),
                          _PaletteRow(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Messages',
                            shortcut: 'M',
                            active: false,
                            onTap: () => widget.onSelect(4), // Messages tab
                          ),
                          _PaletteRow(
                            icon: Icons.person_rounded,
                            label: 'My Profile',
                            shortcut: 'U',
                            active: false,
                            onTap: () => widget.onSelect(5), // Profile tab
                          ),
                          _PaletteRow(
                            icon: Icons.bubble_chart_rounded,
                            label: 'The Pocket',
                            shortcut: 'O',
                            active: false,
                            onTap: () {
                              widget.onDismiss();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const PocketScreen()));
                            },
                          ),
                          _PaletteRow(
                            icon: Icons.mic_rounded,
                            label: 'Voice Playlist',
                            shortcut: 'V',
                            active: false,
                            onTap: () {
                              widget.onDismiss();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const VoicePlaylistScreen()));
                            },
                          ),
                        ],
                      ),

                    // Footer hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color: AuraTheme.textMuted.withOpacity(0.1))),
                      ),
                      child: Row(children: const [
                        _KbdHint('↵', 'select'),
                        SizedBox(width: 14),
                        _KbdHint('↑↓', 'navigate'),
                        SizedBox(width: 14),
                        _KbdHint('ESC', 'close'),
                        Spacer(),
                        Text('J/K also navigates tabs',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 8,
                              color: AuraTheme.textMuted,
                            )),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _PaletteSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 8,
                letterSpacing: 2,
                color: AuraTheme.textMuted,
              )),
        ),
        ...children,
      ],
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final bool active;
  final VoidCallback onTap;
  const _PaletteRow({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AuraTheme.purple.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: AuraTheme.purple.withOpacity(0.25))
              : null,
        ),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: active ? AuraTheme.purple : AuraTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? AuraTheme.textPrimary : AuraTheme.textSecondary,
                )),
          ),
          if (shortcut.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AuraTheme.textMuted.withOpacity(0.15)),
              ),
              child: Text(shortcut,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AuraTheme.textMuted,
                  )),
            ),
        ]),
      ),
    );
  }
}

class _KbdHint extends StatelessWidget {
  final String key_;
  final String label;
  const _KbdHint(this.key_, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AuraTheme.textMuted.withOpacity(0.15)),
        ),
        child: Text(key_,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AuraTheme.textMuted,
            )),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: AuraTheme.textMuted,
          )),
    ]);
  }
}
