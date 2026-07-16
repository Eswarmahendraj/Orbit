import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vibe data
// ─────────────────────────────────────────────────────────────────────────────

class VibeEntry {
  final String emoji;
  final String label;
  const VibeEntry(this.emoji, this.label);
}

const _vibeCategories = <String, List<VibeEntry>>{
  'chill': [
    VibeEntry('☀️', 'chill'),
    VibeEntry('🫶', 'cozy'),
    VibeEntry('🌿', 'calm'),
    VibeEntry('🍵', 'homebody'),
    VibeEntry('🌸', 'soft hours'),
    VibeEntry('🌊', 'at peace'),
    VibeEntry('😴', 'sleepy'),
    VibeEntry('🌤', 'gentle'),
  ],
  'hype': [
    VibeEntry('🔥', 'hype'),
    VibeEntry('⚡', 'unhinged'),
    VibeEntry('🎉', 'party mode'),
    VibeEntry('🏃', 'main character'),
    VibeEntry('💫', 'lit'),
    VibeEntry('🎮', 'gamer mode'),
    VibeEntry('🕺', 'dancing'),
    VibeEntry('🤸', 'energy'),
  ],
  'emotional': [
    VibeEntry('💔', 'heartbreak'),
    VibeEntry('🌧️', '2am feels'),
    VibeEntry('😭', 'crying it out'),
    VibeEntry('🥺', 'delicate'),
    VibeEntry('🫠', 'overwhelmed'),
    VibeEntry('🌑', 'dark hours'),
    VibeEntry('💭', 'overthinking'),
    VibeEntry('🤍', 'healing'),
  ],
  'aesthetic': [
    VibeEntry('🌙', 'dark academia'),
    VibeEntry('🎞️', 'nostalgia'),
    VibeEntry('🎨', 'creative'),
    VibeEntry('🌹', 'romantic'),
    VibeEntry('☁️', 'dreamy'),
    VibeEntry('🌃', 'late night'),
    VibeEntry('📚', 'studycore'),
    VibeEntry('🕯️', 'cottage core'),
  ],
  'chaotic': [
    VibeEntry('🤡', 'clown mode'),
    VibeEntry('😤', 'lowkey mad'),
    VibeEntry('🌪️', 'chaotic'),
    VibeEntry('💀', 'dead inside'),
    VibeEntry('🥴', 'delirious'),
    VibeEntry('😈', 'mischievous'),
    VibeEntry('🤯', 'mind blown'),
    VibeEntry('🫣', 'embarrassed'),
  ],
  'identity': [
    VibeEntry('🏳️‍🌈', 'pride'),
    VibeEntry('🌈', 'queer joy'),
    VibeEntry('💜', 'sapphic'),
    VibeEntry('🤍', 'ace vibes'),
    VibeEntry('🏳️‍⚧️', 'trans joy'),
    VibeEntry('✨', 'camp'),
    VibeEntry('💛', 'nonbinary'),
    VibeEntry('🩷', 'bi vibes'),
  ],
};

const _categoryIcons = <String, String>{
  'chill': '☀️',
  'hype': '🔥',
  'emotional': '💔',
  'aesthetic': '🌙',
  'chaotic': '🤡',
  'identity': '🏳️‍🌈',
};

// ─────────────────────────────────────────────────────────────────────────────
// Public helper — opens the sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showVibePicker(BuildContext context,
    {required bool todayMode}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VibePickerSheet(todayMode: todayMode),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _VibePickerSheet extends StatefulWidget {
  final bool todayMode;
  const _VibePickerSheet({required this.todayMode});

  @override
  State<_VibePickerSheet> createState() => _VibePickerSheetState();
}

class _VibePickerSheetState extends State<_VibePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _categories = _vibeCategories.keys.toList();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isAlwaysSelected(VibeEntry v) =>
      OrbitState().alwaysVibes.any((e) => e['label'] == v.label);

  void _pickToday(VibeEntry v) {
    final s = OrbitState();
    s.mood = v.label;
    s.moodEmoji = v.emoji;
    s.save();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${v.emoji} ${v.label} set as today\'s vibe — resets at midnight'),
      backgroundColor: AuraTheme.accent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _toggleAlways(VibeEntry v) {
    final s = OrbitState();
    final existing = s.alwaysVibes.indexWhere((e) => e['label'] == v.label);
    if (existing != -1) {
      s.alwaysVibes.removeAt(existing);
    } else {
      if (s.alwaysVibes.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Max 3 always vibes — remove one first'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      s.alwaysVibes.add({'emoji': v.emoji, 'label': v.label});
    }
    s.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final todayMode = widget.todayMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  todayMode ? 'today\'s vibe' : 'always vibes',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                Text(
                  todayMode
                      ? 'resets at midnight · visible on your profile'
                      : '${state.alwaysVibes.length}/3 selected · permanent tags',
                  style: const TextStyle(
                      fontSize: 12, color: AuraTheme.textMuted),
                ),
              ]),
              const Spacer(),
              if (!todayMode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${state.alwaysVibes.length}/3',
                      style: const TextStyle(
                          color: AuraTheme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
            ]),
          ),

          // Category tabs
          TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: AuraTheme.accent,
            labelColor: AuraTheme.accent,
            unselectedLabelColor: AuraTheme.textMuted,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12),
            tabs: _categories
                .map((c) => Tab(
                    text:
                        '${_categoryIcons[c] ?? ''} $c'))
                .toList(),
          ),

          const Divider(height: 1),

          // Vibe grid
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _categories.map((cat) {
                final vibes = _vibeCategories[cat]!;
                final isIdentity = cat == 'identity';
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isIdentity)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AuraTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(children: [
                          Text('🔒', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Identity tags are private by default. Manage visibility in Settings → Privacy.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AuraTheme.textSecondary),
                            ),
                          ),
                        ]),
                      ),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.4,
                      children: vibes.map((v) {
                        final isTodayActive =
                            todayMode && state.mood == v.label;
                        final isAlways = _isAlwaysSelected(v);
                        final active = todayMode ? isTodayActive : isAlways;

                        return GestureDetector(
                          onTap: () => todayMode
                              ? _pickToday(v)
                              : _toggleAlways(v),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: active
                                  ? AuraTheme.accent
                                  : AuraTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? AuraTheme.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(v.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    v.label,
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : AuraTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!todayMode && isAlways) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 14),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Bottom action
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: !todayMode
                  ? SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AuraTheme.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                            'Save ${state.alwaysVibes.length} always vibe${state.alwaysVibes.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ]),
      ),
    );
  }
}
