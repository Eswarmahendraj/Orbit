import 'package:flutter/material.dart';
import '../../main.dart' show themeNotifier;
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../home/vibe_picker_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = OrbitState();

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AuraTheme.accent)),
      );

  Widget _tile({
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) =>
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: titleColor ?? AuraTheme.textPrimary)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AuraTheme.textMuted))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: AuraTheme.textMuted, size: 20),
        onTap: onTap,
      );

  Widget _switch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AuraTheme.textMuted))
            : null,
        trailing: Switch.adaptive(
          value: value,
          onChanged: (v) {
            onChanged(v);
            setState(() {});
            _s.save();
          },
          activeColor: AuraTheme.accent,
        ),
      );

  // ── Vibe section ─────────────────────────────────────────────────────────

  Widget _vibeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('vibes'),
          // Today's vibe row
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            title: const Text("Today's vibe",
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              '${_s.moodEmoji} ${_s.mood} · resets at midnight',
              style:
                  const TextStyle(fontSize: 12, color: AuraTheme.textMuted),
            ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('change',
                  style: const TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            onTap: () async {
              await showVibePicker(context, todayMode: true);
              setState(() {});
            },
          ),
          // Always vibes row
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            title: const Text('Always vibes',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: _s.alwaysVibes.isEmpty
                ? const Text('No permanent vibes set',
                    style: TextStyle(
                        fontSize: 12, color: AuraTheme.textMuted))
                : Wrap(
                    spacing: 6,
                    children: _s.alwaysVibes
                        .map((v) => Chip(
                              label: Text(
                                  '${v['emoji']} ${v['label']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AuraTheme.accent)),
                              backgroundColor:
                                  AuraTheme.accent.withOpacity(0.08),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('edit',
                  style: const TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            onTap: () async {
              await showVibePicker(context, todayMode: false);
              setState(() {});
            },
          ),
          // Identity tags
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            title: const Text('Identity tags',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              _s.identityTags.isEmpty
                  ? 'Optional · private by default'
                  : '${_s.identityTags.length} tag${_s.identityTags.length == 1 ? '' : 's'} · ${_s.identityTagsPublic ? 'visible on profile' : 'private'}',
              style:
                  const TextStyle(fontSize: 12, color: AuraTheme.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AuraTheme.textMuted, size: 20),
            onTap: () => _showIdentityTagsSheet(),
          ),
        ],
      );

  // ── Identity tags sheet ───────────────────────────────────────────────────

  void _showIdentityTagsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IdentityTagsSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }

  // ── Privacy section ───────────────────────────────────────────────────────

  Widget _privacySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('privacy'),
          _switch(
            title: 'Ghost mode',
            subtitle: 'Hide your activity from everyone',
            value: _s.ghostMode,
            onChanged: (v) => _s.ghostMode = v,
          ),
          _switch(
            title: 'Stealth view',
            subtitle: 'View stories without them knowing',
            value: _s.stealthView,
            onChanged: (v) => _s.stealthView = v,
          ),
          _tile(
            title: 'Last seen',
            subtitle: _s.lastSeenMode == 'friends'
                ? 'Visible to synced friends'
                : _s.lastSeenMode == 'nobody'
                    ? 'Hidden from everyone'
                    : 'Visible to everyone',
            onTap: () => _showLastSeenSheet(),
          ),
          _switch(
            title: 'Screenshot block',
            subtitle: 'Prevent screenshots inside the app',
            value: _s.screenshotBlock,
            onChanged: (v) => _s.screenshotBlock = v,
          ),
          _switch(
            title: 'App disguise',
            subtitle: 'App icon + splash appear as Calculator',
            value: _s.appDisguiseEnabled,
            onChanged: (v) => _s.appDisguiseEnabled = v,
          ),
        ],
      );

  void _showLastSeenSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Last seen visibility',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          for (final opt in [
            ('everyone', 'Visible to everyone'),
            ('friends', 'Visible to synced friends only'),
            ('nobody', 'Hidden from everyone'),
          ])
            ListTile(
              title: Text(opt.$2),
              trailing: _s.lastSeenMode == opt.$1
                  ? const Icon(Icons.check_circle_rounded,
                      color: AuraTheme.accent)
                  : null,
              onTap: () {
                _s.lastSeenMode = opt.$1;
                _s.save();
                setState(() {});
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Notifications section ─────────────────────────────────────────────────

  String get _notifModeLabel {
    switch (_s.notifMode) {
      case 'sound':
        return 'Sound only';
      case 'off':
        return 'Off';
      default:
        return 'Push + Sound';
    }
  }

  Widget _notifSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('notifications'),
          _tile(
            title: 'Notification style',
            subtitle: _notifModeLabel,
            onTap: () => _showNotifModeSheet(),
          ),
        ],
      );

  void _showNotifModeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Notification style',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Choose how you want to be alerted when something happens.',
            style: TextStyle(fontSize: 12, color: AuraTheme.textMuted),
          ),
          const SizedBox(height: 16),
          for (final opt in [
            ('push', '🔔  Push + Sound', 'Banner notification with sound'),
            ('sound', '🎵  Sound only', 'Plays a chime — no banner'),
            ('off', '🔕  Off', 'No notification at all'),
          ])
            ListTile(
              title: Text(opt.$2,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(opt.$3,
                  style: const TextStyle(
                      fontSize: 12, color: AuraTheme.textMuted)),
              trailing: _s.notifMode == opt.$1
                  ? const Icon(Icons.check_circle_rounded,
                      color: AuraTheme.accent)
                  : null,
              onTap: () {
                _s.notifMode = opt.$1;
                _s.save();
                setState(() {});
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Appearance section ────────────────────────────────────────────────────

  Widget _appearanceSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('appearance'),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AuraTheme.isDark
                    ? const Color(0xFF1C1C1E)
                    : AuraTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AuraTheme.isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AuraTheme.accent,
                size: 20,
              ),
            ),
            title: const Text('Dark mode',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: Text(
              AuraTheme.isDark
                  ? 'Night owl mode — dark theme'
                  : 'Morning person — light theme',
              style: const TextStyle(
                  fontSize: 12, color: AuraTheme.textMuted),
            ),
            trailing: Switch.adaptive(
              value: _s.darkMode,
              onChanged: (v) {
                setState(() {
                  _s.darkMode = v;
                  AuraTheme.isDark = v;
                  themeNotifier.value =
                      v ? ThemeMode.dark : ThemeMode.light;
                  _s.save();
                });
              },
              activeColor: AuraTheme.accent,
            ),
          ),
          _tile(
            title: 'Language',
            subtitle: 'English',
            onTap: () => _showLanguageSheet(),
          ),
        ],
      );

  void _showLanguageSheet() {
    const langs = [
      ('English', 'English', '🇺🇸'),
      ('Hindi', 'हिंदी', '🇮🇳'),
      ('Telugu', 'తెలుగు', '🇮🇳'),
      ('Tamil', 'தமிழ்', '🇮🇳'),
      ('Spanish', 'Español', '🇪🇸'),
      ('French', 'Français', '🇫🇷'),
      ('Japanese', '日本語', '🇯🇵'),
      ('Korean', '한국어', '🇰🇷'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, c) => ListView(
          controller: c,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Language',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            for (final l in langs)
              ListTile(
                leading: Text(l.$3,
                    style: const TextStyle(fontSize: 22)),
                title: Text(l.$1),
                subtitle: Text(l.$2),
                trailing: l.$1 == 'English'
                    ? const Icon(Icons.check_circle_rounded,
                        color: AuraTheme.accent)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${l.$1} coming soon!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AuraTheme.accent,
                  ));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Support section ───────────────────────────────────────────────────────

  Widget _supportSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('support'),
          _tile(
            title: 'Help & FAQ',
            subtitle: 'Answers to common questions',
            trailing: const Icon(Icons.help_outline_rounded,
                color: AuraTheme.textMuted, size: 20),
            onTap: () => _showFAQ(),
          ),
          _tile(
            title: 'Send feedback',
            subtitle: 'Tell us what you love or what to fix',
            trailing: const Icon(Icons.chat_bubble_outline_rounded,
                color: AuraTheme.textMuted, size: 20),
            onTap: () => _showFeedbackSheet(),
          ),
          _tile(
            title: 'Chat with support',
            subtitle: 'AI-first · escalate to human anytime',
            trailing: const Icon(Icons.support_agent_rounded,
                color: AuraTheme.accent, size: 20),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _SupportChatScreen())),
          ),
          _tile(
            title: 'Email support',
            subtitle: 'support.theorbit@gmail.com',
            trailing: const Icon(Icons.mail_outline_rounded,
                color: AuraTheme.textMuted, size: 20),
            onTap: () => _showContactEmailSheet(),
          ),
        ],
      );

  void _showFAQ() {
    const faqs = [
      ('What is a clip streak?',
          'A clip streak is the number of consecutive days you and a friend have both sent each other a music clip. It resets if either of you misses a day.'),
      ('How does the daily vibe work?',
          "Your today's vibe is visible on your profile and resets every midnight. You can change it anytime from the home screen or Settings → Vibes."),
      ('Are identity tags public?',
          'No — identity tags are private by default. You can make them visible on your profile in Settings → Vibes → Identity tags.'),
      ('What is Ghost mode?',
          'Ghost mode hides your activity status so friends won\'t see when you\'re online or when you last opened the app.'),
      ('How do always vibes work?',
          'Always vibes are up to 3 permanent mood tags that never expire. They show on your profile below your daily vibe.'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        expand: false,
        builder: (_, c) => ListView(
          controller: c,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Help & FAQ',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            for (final faq in faqs) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: AuraTheme.surface,
                    borderRadius: BorderRadius.circular(14)),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(faq.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(faq.$2,
                          style: const TextStyle(
                              color: AuraTheme.textSecondary,
                              fontSize: 13,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Send feedback',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText:
                    'What\'s on your mind? Bug, idea, anything goes...',
                filled: true,
                fillColor: AuraTheme.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Thanks for your feedback! 🙌'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Text('Send',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _showContactEmailSheet() {
    const email = 'support.theorbit@gmail.com';
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.mail_rounded, size: 36, color: AuraTheme.accent),
          const SizedBox(height: 12),
          const Text('Contact Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Email us and we\'ll get back to you within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AuraTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(children: [
              Expanded(
                child: Text(email,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy email address',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: email));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Email copied to clipboard ✉️'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Account section ───────────────────────────────────────────────────────

  Widget _accountSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('account'),
          _tile(
            title: _s.displayName,
            subtitle: _s.username,
            trailing: const Icon(Icons.edit_outlined,
                color: AuraTheme.textMuted, size: 18),
            onTap: () {},
          ),
          _tile(
            title: 'Clear my data',
            subtitle: 'Remove all local posts, DMs, and settings',
            titleColor: Colors.redAccent,
            trailing: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onTap: () => _confirmClearData(),
          ),
          _tile(
            title: 'Sign out',
            titleColor: Colors.redAccent,
            trailing: const Icon(Icons.logout_rounded,
                color: Colors.redAccent, size: 20),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('orbit v1.0.0',
                style: TextStyle(
                    fontSize: 11,
                    color: AuraTheme.textMuted.withOpacity(0.6))),
          ),
          const SizedBox(height: 32),
        ],
      );

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will delete your posts, DMs, and settings stored on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final s = OrbitState();
              s.myPosts.clear();
              s.dmThreads.clear();
              s.clipStreaks.clear();
              s.alwaysVibes.clear();
              s.identityTags.clear();
              s.save();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Data cleared'),
                behavior: SnackBarBehavior.floating,
              ));
              setState(() {});
            },
            child: const Text('Clear',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.themeBg,
      appBar: AppBar(
        title: const Text('settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: AuraTheme.themeBg,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _vibeSection(),
          const Divider(indent: 20, endIndent: 20),
          _privacySection(),
          const Divider(indent: 20, endIndent: 20),
          _notifSection(),
          const Divider(indent: 20, endIndent: 20),
          _appearanceSection(),
          const Divider(indent: 20, endIndent: 20),
          _supportSection(),
          const Divider(indent: 20, endIndent: 20),
          _accountSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Identity Tags Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _IdentityTagsSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _IdentityTagsSheet({required this.onChanged});

  @override
  State<_IdentityTagsSheet> createState() => _IdentityTagsSheetState();
}

class _IdentityTagsSheetState extends State<_IdentityTagsSheet> {
  static const _tags = [
    ('🏳️‍🌈', 'pride'),
    ('🌈', 'queer joy'),
    ('💜', 'sapphic'),
    ('🤍', 'ace vibes'),
    ('🏳️‍⚧️', 'trans joy'),
    ('✨', 'camp'),
    ('💛', 'nonbinary'),
    ('🩷', 'bi vibes'),
    ('🖤', 'questioning'),
    ('💚', 'ally'),
  ];

  final _s = OrbitState();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (_, c) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: c,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Identity tags',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'These are optional and private by default. Only you can see them unless you choose to share.',
              style: TextStyle(fontSize: 12, color: AuraTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((t) {
                final sel = _s.identityTags.contains(t.$2);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (sel) {
                        _s.identityTags.remove(t.$2);
                      } else {
                        _s.identityTags.add(t.$2);
                      }
                      _s.save();
                    });
                    widget.onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AuraTheme.accent
                          : AuraTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AuraTheme.accent
                            : Colors.transparent,
                      ),
                    ),
                    child: Text('${t.$1}  ${t.$2}',
                        style: TextStyle(
                            color: sel
                                ? Colors.white
                                : AuraTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show on profile',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text(
                'When on, your identity tags are visible on your public profile',
                style:
                    TextStyle(fontSize: 12, color: AuraTheme.textMuted),
              ),
              value: _s.identityTagsPublic,
              activeColor: AuraTheme.accent,
              onChanged: (v) {
                setState(() => _s.identityTagsPublic = v);
                _s.save();
                widget.onChanged();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support Chat Screen
// ─────────────────────────────────────────────────────────────────────────────

class _SupportChatScreen extends StatefulWidget {
  const _SupportChatScreen();

  @override
  State<_SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<_SupportChatScreen> {
  final _ctrl = TextEditingController();
  bool _humanMode = false;

  final _messages = <Map<String, dynamic>>[
    {
      'text': 'Hey! 👋 I\'m the orbit support bot. What can I help you with today?',
      'isMe': false,
      'isAI': true,
    },
    {
      'text': 'Common topics:',
      'isMe': false,
      'isAI': true,
      'chips': ['Clip streaks', 'Privacy settings', 'Account help', 'Bug report'],
    },
  ];

  static const _aiReplies = <String, String>{
    'Clip streaks':
        '🔥 A clip streak counts how many days in a row you and a friend have both sent each other a music clip. Miss a day and it resets to 0!',
    'Privacy settings':
        '🔒 You can control Ghost mode, Stealth view, Screenshot block and more in Settings → Privacy. Your identity tags are always private by default.',
    'Account help':
        '👤 For account issues like password reset or deleting your account, tap \'Talk to a human\' below and our team will assist you within 24 hours.',
    'Bug report':
        '🐛 Please describe the bug and what you were doing when it happened. Screenshots help a lot!',
  };

  void _send([String? override]) {
    final text = (override ?? _ctrl.text.trim());
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isMe': true});
      _ctrl.clear();
    });

    final reply = _humanMode
        ? '🧑 A human agent will get back to you within 24 hours. Your message has been sent!'
        : (_aiReplies[text] ??
            'Got it! I\'m looking into that for you. If I can\'t help, tap "Talk to a human" below and our team will take over. 🙌');

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _messages.add({
              'text': reply,
              'isMe': false,
              'isAI': !_humanMode,
            }));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('support chat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(
            _humanMode ? '🧑 Human agent' : '🤖 AI assistant',
            style: const TextStyle(
                fontSize: 11, color: AuraTheme.textMuted),
          ),
        ]),
        backgroundColor: AuraTheme.background,
        elevation: 0,
        actions: [
          if (!_humanMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _humanMode = true;
                  _messages.add({
                    'text':
                        '✅ Connecting you to a human agent. Expected response time: under 24 hours.',
                    'isMe': false,
                    'isAI': false,
                  });
                });
              },
              child: const Text('Talk to human',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final isMe = m['isMe'] == true;
              final chips =
                  (m['chips'] as List<String>?) ?? [];
              return Align(
                alignment: isMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 4, left: 2),
                        child: Text(
                          m['isAI'] == true
                              ? '🤖 orbit bot'
                              : '🧑 support team',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AuraTheme.textMuted,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AuraTheme.accent
                            : AuraTheme.card,
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomRight: isMe
                              ? const Radius.circular(4)
                              : null,
                          bottomLeft: !isMe
                              ? const Radius.circular(4)
                              : null,
                        ),
                      ),
                      child: Text(m['text'] as String,
                          style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : AuraTheme.textPrimary,
                              fontSize: 14,
                              height: 1.4)),
                    ),
                    if (chips.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: chips
                            .map((c) => GestureDetector(
                                  onTap: () => _send(c),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 8),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AuraTheme.surface,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AuraTheme.accent
                                              .withOpacity(0.3)),
                                    ),
                                    child: Text(c,
                                        style: const TextStyle(
                                            color: AuraTheme.accent,
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600)),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // Input bar
        Container(
          color: AuraTheme.card,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AuraTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _send(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AuraTheme.accent, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
