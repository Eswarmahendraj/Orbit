import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../home/home_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  final _categories = {
    '🎵 Music': ['lo-fi', 'pop', 'hip-hop', 'classical', 'indie', 'EDM', 'jazz', 'metal'],
    '🎮 Gaming': ['FPS', 'RPG', 'mobile games', 'esports', 'retro', 'strategy'],
    '📚 Study': ['engineering', 'medicine', 'arts', 'science', 'coding', 'design'],
    '🎨 Creative': ['art', 'photography', 'writing', 'filmmaking', 'fashion', 'DIY'],
    '🏃 Active': ['gym', 'yoga', 'cricket', 'football', 'cycling', 'running'],
    '🌙 Vibes': ['night owl', 'morning person', 'introvert', 'deep talks', 'movies', 'anime'],
  };

  Future<void> _save() async {
    if (_selected.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least 3 interests')));
      return;
    }
    setState(() => _saving = true);
    // TODO: save interests to backend
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What\'s your vibe?',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))
                            .animate().fadeIn().slideY(begin: -0.2),
                        const SizedBox(height: 8),
                        const Text('Pick at least 3 — Orbit uses these to find your Campfire rooms.',
                            style: TextStyle(color: AuraColors.textSecondary, fontSize: 14))
                            .animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 8),
                        Text('${_selected.length} selected',
                            style: TextStyle(
                              color: _selected.length >= 3
                                  ? AuraColors.accent : AuraColors.textSecondary,
                              fontWeight: FontWeight.w600, fontSize: 13))
                            .animate(target: _selected.length >= 3 ? 1 : 0)
                            .tint(color: AuraColors.accent),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                ..._categories.entries.map((entry) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: entry.value.map((tag) {
                            final sel = _selected.contains(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                sel ? _selected.remove(tag) : _selected.add(tag);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AuraColors.accent.withOpacity(0.2)
                                      : AuraColors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: sel ? AuraColors.accent : AuraColors.divider,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(tag,
                                    style: TextStyle(
                                      color: sel ? AuraColors.accent : AuraColors.textSecondary,
                                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 13,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // Bottom CTA
          Container(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: AuraColors.background,
              border: Border(top: BorderSide(color: AuraColors.divider)),
            ),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enter Orbit  →'),
            ),
          ),
        ],
      ),
    ),
  );
}
