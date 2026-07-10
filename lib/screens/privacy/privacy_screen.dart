import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _s = OrbitState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('privacy & stealth',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header('👻 stealth'),
          _toggle(
            icon: Icons.visibility_off_rounded,
            title: 'Ghost Mode',
            subtitle: 'Invisible to everyone. No active status, no seen receipts.',
            value: _s.ghostMode,
            onChanged: (v) => setState(() => _s.ghostMode = v),
            highlight: true,
          ),
          _toggle(
            icon: Icons.remove_red_eye_outlined,
            title: 'Stealth View',
            subtitle: 'View profiles & vybes without leaving a trace.',
            value: _s.stealthView,
            onChanged: (v) => setState(() => _s.stealthView = v),
          ),
          _toggle(
            icon: Icons.screenshot_monitor_rounded,
            title: 'Screenshot Block',
            subtitle: 'Blocks screenshots of your profile and vybes.',
            value: _s.screenshotBlock,
            onChanged: (v) => setState(() => _s.screenshotBlock = v),
          ),
          const SizedBox(height: 20),
          _header('🛡️ discoverability'),
          _toggle(
            icon: Icons.search_off_rounded,
            title: 'Anti-Creep Shield',
            subtitle: 'Only people with your exact @handle can find you.',
            value: _s.antiCreepShield,
            onChanged: (v) => setState(() => _s.antiCreepShield = v),
            highlight: true,
          ),
          _lastSeenCard(),
          const SizedBox(height: 20),
          _header('🔐 app security'),
          _toggle(
            icon: Icons.calculate_outlined,
            title: 'App Disguise',
            subtitle: 'Orbit shows as a calculator to anyone else. Long-press "=" × 3s to unlock.',
            value: _s.appDisguiseEnabled,
            onChanged: (v) {
              setState(() => _s.appDisguiseEnabled = v);
              if (v) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Long-press "=" for 3 seconds to unlock Orbit'),
                  backgroundColor: AuraTheme.accent,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
          _actionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Passcode DMs',
            subtitle: _s.dmPasscode == null
                ? 'Set a 4-digit PIN to lock campfire chats'
                : 'PIN is set — tap to change or remove',
            onTap: _showPasscodeSheet,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AuraTheme.textSecondary,
                letterSpacing: 0.3)),
      );

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool highlight = false,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: highlight && value
              ? Border.all(color: AuraTheme.accent.withOpacity(0.35))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (highlight && value ? AuraTheme.accent : AuraTheme.textMuted)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20,
                  color: highlight && value ? AuraTheme.accent : AuraTheme.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AuraTheme.accent,
            ),
          ],
        ),
      );

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AuraTheme.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AuraTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AuraTheme.textMuted),
            ],
          ),
        ),
      );

  Widget _lastSeenCard() => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_rounded,
                    size: 20, color: AuraTheme.textMuted),
              ),
              const SizedBox(width: 14),
              const Text('Last Seen',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 14),
            ...['everyone', 'friends', 'hidden'].map((mode) {
              final labels = {
                'everyone': 'Everyone can see',
                'friends': 'Synced friends only',
                'hidden': 'Hidden from all',
              };
              final selected = _s.lastSeenMode == mode;
              return GestureDetector(
                onTap: () => setState(() => _s.lastSeenMode = mode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color:
                          selected ? AuraTheme.accent : AuraTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(labels[mode]!,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? AuraTheme.textPrimary
                                : AuraTheme.textMuted)),
                  ]),
                ),
              );
            }),
          ],
        ),
      );

  void _showPasscodeSheet() {
    String pin = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AuraTheme.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('DM Passcode',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('4-digit PIN to lock your campfire chats',
                  style:
                      TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    4,
                    (i) => Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < pin.length
                                ? AuraTheme.accent
                                : AuraTheme.surface,
                            border: Border.all(
                                color: AuraTheme.accent.withOpacity(0.4)),
                          ),
                        )),
              ),
              const SizedBox(height: 24),
              _pinPad((digit) {
                setS(() {
                  if (digit == '⌫') {
                    if (pin.isNotEmpty) pin = pin.substring(0, pin.length - 1);
                  } else if (pin.length < 4) {
                    pin += digit;
                    if (pin.length == 4) {
                      setState(() => _s.dmPasscode = pin);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Passcode set!'),
                        backgroundColor: AuraTheme.accent,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                });
              }),
              if (_s.dmPasscode != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _s.dmPasscode = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('remove passcode',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinPad(void Function(String) onTap) {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return GestureDetector(
          onTap: () => onTap(k),
          child: Center(
            child: Text(k,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}
