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
// Called from main.dart instead of MainNav when on the web
// ─────────────────────────────────────────────────────────────────────────────

class ResponsiveRoot extends StatelessWidget {
  const ResponsiveRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth > 800) {
          return const WebShell();
        }
        return const MobileNav();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile nav (unchanged bottom nav bar layout)
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
      body: IndexedStack(index: _tab, children: const [
        HomeScreen(),
        CampfireScreen(),
        PulseScreen(),
        FindScreen(),
        ProfileScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          HapticFeedback.lightImpact();
          setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.graphic_eq),
              selectedIcon:
                  Icon(Icons.graphic_eq, color: AuraTheme.accent),
              label: 'home'),
          NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              selectedIcon: Icon(Icons.local_fire_department_rounded,
                  color: AuraTheme.accent),
              label: 'campfire'),
          NavigationDestination(
              icon: Icon(Icons.play_circle_outline_rounded),
              selectedIcon:
                  Icon(Icons.play_circle_rounded, color: AuraTheme.accent),
              label: 'pulse'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon:
                  Icon(Icons.auto_awesome, color: AuraTheme.accent),
              label: 'find'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon:
                  Icon(Icons.person, color: AuraTheme.accent),
              label: 'self'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Shell: dark 64px sidebar + main content + right panel
// ─────────────────────────────────────────────────────────────────────────────

class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _tab = 0;

  static const _navItems = [
    _NavItem(Icons.graphic_eq_rounded, Icons.graphic_eq_rounded, 'Home'),
    _NavItem(Icons.local_fire_department_outlined,
        Icons.local_fire_department_rounded, 'Campfire'),
    _NavItem(Icons.play_circle_outline_rounded,
        Icons.play_circle_rounded, 'Pulse'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Find'),
    _NavItem(Icons.chat_bubble_outline_rounded,
        Icons.chat_bubble_rounded, 'Messages'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final initial = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'Y';

    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Row(children: [
        // ── Left sidebar ────────────────────────────────────────────────
        Container(
          width: 64,
          color: const Color(0xFF1A1A1A),
          child: Column(children: [
            const SizedBox(height: 16),
            // Logo
            _OrbitLogoMini(),
            const SizedBox(height: 20),
            // Nav icons
            for (int i = 0; i < _navItems.length; i++)
              _SidebarIcon(
                item: _navItems[i],
                selected: _tab == i,
                onTap: () => setState(() => _tab = i),
              ),
            const Spacer(),
            // Settings
            _SidebarIcon(
              item: const _NavItem(
                  Icons.settings_outlined, Icons.settings, 'Settings'),
              selected: false,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 8),
            // Avatar
            GestureDetector(
              onTap: () => setState(() => _tab = 5),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraTheme.accent,
                  image: state.pfpFile != null
                      ? DecorationImage(
                          image: FileImage(state.pfpFile!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: state.pfpFile == null
                    ? Center(
                        child: Text(initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)))
                    : null,
              ),
            ),
          ]),
        ),

        // ── Main content area ───────────────────────────────────────────
        Expanded(
          child: IndexedStack(index: _tab, children: const [
            HomeScreen(),
            CampfireScreen(),
            PulseScreen(),
            FindScreen(),
            MessagesScreen(),
            ProfileScreen(),
          ]),
        ),

        // ── Right panel ────────────────────────────────────────────────
        Container(
          width: 200,
          decoration: const BoxDecoration(
            border: Border(
                left: BorderSide(color: Color(0xFFEEE9DE), width: 0.5)),
          ),
          child: _RightPanel(
            onVibeChange: () => setState(() {}),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar icon button
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _SidebarIcon extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarIcon(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: item.label,
        preferBelow: false,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 3),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected
                  ? AuraTheme.accent
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              selected ? item.selectedIcon : item.icon,
              color: selected ? Colors.white : Colors.white54,
              size: 22,
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Orbit logo mini for sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _OrbitLogoMini extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(34, 34),
      painter: _OrbitLogoPainter(),
    );
  }
}

class _OrbitLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AuraTheme.accent;
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    final circlePaint = Paint()
      ..color = const Color(0xFFF4F0E8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.37, circlePaint);

    final linePaint = Paint()
      ..color = AuraTheme.accent.withOpacity(0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.37;
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), linePaint);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Right panel — vibe + streak + trending + sync suggestions
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
    ('🌙 2am feels', '4.2k'),
    ('🔥 hypehouse', '3.8k'),
    ('✨ euphoric', '2.1k'),
    ('🎬 main character', '1.9k'),
    ('🎧 in the zone', '1.4k'),
  ];

  static const _suggestions = [
    ('Karan M', '🌙 2am feels', Color(0xFFE74C3C)),
    ('Dev S', '🎧 in the zone', Color(0xFF3498DB)),
    ('Ananya T', '✨ euphoric', Color(0xFFFF69B4)),
  ];

  final Set<String> _synced = {};

  String _vibeCountdown() {
    final now = DateTime.now();
    final midnight =
        DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Today's vibe ──────────────────────────────────────────
        _label('your vibe today'),
        GestureDetector(
          onTap: () async {
            await showVibePicker(context, todayMode: true);
            setState(() {});
            widget.onVibeChange();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AuraTheme.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(_s.moodEmoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(_s.mood,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              Text('resets in ${_vibeCountdown()}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('change vibe',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),

        // ── Streak banner ─────────────────────────────────────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('12-day clip streak',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: AuraTheme.accent)),
                const Text('send a clip to keep it going',
                    style: TextStyle(
                        fontSize: 9, color: AuraTheme.textMuted)),
              ]),
            ),
          ]),
        ),

        // ── Trending vibes ────────────────────────────────────────
        _label('trending vibes'),
        for (int i = 0; i < _trending.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text('${i + 1}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AuraTheme.accent)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_trending[i].$1,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              Text(_trending[i].$2,
                  style: const TextStyle(
                      fontSize: 10, color: AuraTheme.textMuted)),
            ]),
          ),

        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 8),

        // ── People to sync with ───────────────────────────────────
        _label('people to sync with'),
        for (final sug in _suggestions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: sug.$3.withOpacity(0.2),
                child: Text(sug.$1[0],
                    style: TextStyle(
                        color: sug.$3,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(sug.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                  Text(sug.$2,
                      style: const TextStyle(
                          fontSize: 9, color: AuraTheme.textMuted)),
                ]),
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
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _synced.contains(sug.$1)
                        ? AuraTheme.surface
                        : AuraTheme.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _synced.contains(sug.$1) ? '✓ synced' : '+ sync',
                    style: TextStyle(
                        color: _synced.contains(sug.$1)
                            ? AuraTheme.textMuted
                            : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AuraTheme.textMuted),
        ),
      );
}
