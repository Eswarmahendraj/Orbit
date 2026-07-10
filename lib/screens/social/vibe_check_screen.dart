import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class VibeCheckScreen extends StatefulWidget {
  const VibeCheckScreen({super.key});
  @override
  State<VibeCheckScreen> createState() => _VibeCheckScreenState();
}

class _VibeCheckScreenState extends State<VibeCheckScreen> {
  final _s = OrbitState();
  String? _selected;
  bool _done = false;

  static const _moods = [
    {'label': 'chill', 'emoji': '☀️'},
    {'label': 'hyped', 'emoji': '⚡'},
    {'label': 'nostalgic', 'emoji': '🌙'},
    {'label': 'focused', 'emoji': '🎧'},
    {'label': 'sad', 'emoji': '🌧️'},
    {'label': 'romantic', 'emoji': '💫'},
  ];

  static const _matches = <String, List<String>>{
    'chill': ['@maya.k ☀️', '@jay.r ☀️'],
    'hyped': ['@zara.w ⚡', '@dev.s ⚡', '@rina.p ⚡'],
    'nostalgic': ['@maya.k 🌙'],
    'focused': ['@leo.k 🎧', '@sam.w 🎧'],
    'sad': ['@zara.w 🌧️'],
    'romantic': ['@rina.p 💫', '@jay.r 💫'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: _done ? _resultView() : _pickView(),
      ),
    );
  }

  Widget _pickView() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('vibe check 🌡️',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('what\'s your energy right now?',
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 16)),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: _moods.map((m) {
                final sel = _selected == m['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = m['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? AuraTheme.accent : AuraTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: sel
                          ? [BoxShadow(
                              color: AuraTheme.accent.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m['emoji']!,
                            style: const TextStyle(fontSize: 34)),
                        const SizedBox(height: 8),
                        Text(m['label']!,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? Colors.white
                                    : AuraTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      _s.vibeCheckDoneToday = true;
                      setState(() => _done = true);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AuraTheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('check my orbit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );

  Widget _resultView() {
    final emoji =
        _moods.firstWhere((m) => m['label'] == _selected)['emoji']!;
    final matches = _matches[_selected] ?? [];
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text('you\'re vibing $_selected',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          matches.isEmpty
              ? 'no one in your orbit right now'
              : '${matches.length} friend${matches.length == 1 ? '' : 's'} feel the same',
          style: const TextStyle(color: AuraTheme.textMuted, fontSize: 15),
        ),
        const SizedBox(height: 32),
        if (matches.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('in your orbit now',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          ...matches.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AuraTheme.accent.withOpacity(0.15),
                    child: Text(
                        m.isNotEmpty ? m[1].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AuraTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Text(m,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              )),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
