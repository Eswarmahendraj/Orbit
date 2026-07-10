import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../../models/message_model.dart';
import 'create_post_screen.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});
  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<_PostData> _feed = [
    _PostData('Silver Tide', 'story', 'Midnight walk. No thoughts. Just the city.',
        PostVisibility.closeCircle, '🌿', AuraColors.moodCalm, 12, 84),
    _PostData('Amber Wisp', 'song', 'Redbone — Childish Gambino',
        PostVisibility.public, '🌸', AuraColors.moodHappy, 0, 231),
    _PostData('Velvet Storm', 'reel', null,
        PostVisibility.closeCircle, '🌟', AuraColors.moodEnergy, 34, 120),
    _PostData('Cosmic Shore', 'momentCard', '🔥 On Fire · 31 days together',
        PostVisibility.public, '🔥', AuraColors.moodFocus, 56, 302),
    _PostData('Pale Ember', 'story', 'rainy day energy ✦',
        PostVisibility.closeCircle, '💫', AuraColors.moodSad, 8, 44),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Share'),
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AuraColors.accent,
        labelColor: AuraColors.accent,
        unselectedLabelColor: AuraColors.textSecondary,
        tabs: const [Tab(text: 'Feed'), Tab(text: 'My Posts')],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const CreatePostScreen())),
          tooltip: 'Create post',
        ),
      ],
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        // Feed
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _feed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _PostCard(data: _feed[i])
              .animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.06),
        ),

        // My Posts placeholder
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 48))
                  .animate().fadeIn().scale(),
              const SizedBox(height: 16),
              const Text('Your posts appear here',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Share a story, song, or moment.',
                  style: TextStyle(color: AuraColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CreatePostScreen())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Post'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 44)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PostData {
  final String authorName, type;
  final String? content;
  final PostVisibility visibility;
  final String emoji;
  final Color color;
  final int pulses, views;
  const _PostData(this.authorName, this.type, this.content,
      this.visibility, this.emoji, this.color, this.pulses, this.views);
}

class _PostCard extends StatefulWidget {
  final _PostData data;
  const _PostCard({required this.data});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _pulsed = false;

  static const _typeIcons = {
    'story':      Icons.auto_stories_outlined,
    'song':       Icons.music_note_outlined,
    'video':      Icons.videocam_outlined,
    'reel':       Icons.play_circle_outline,
    'momentCard': Icons.favorite_outline,
  };

  static const _typeLabels = {
    'story': 'Story', 'song': 'Song', 'video': 'Video',
    'reel': 'Reel', 'momentCard': 'Moment',
  };

  static const _visLabels = {
    PostVisibility.public: '🌍 Public',
    PostVisibility.closeCircle: '🔒 Circle',
    PostVisibility.private: '👁️ Only me',
  };

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      decoration: BoxDecoration(
        color: AuraColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: d.color.withOpacity(0.2),
                  child: Text(d.emoji,
                      style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.authorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Row(children: [
                        Icon(_typeIcons[d.type] ?? Icons.circle_outlined,
                            size: 11, color: AuraColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_typeLabels[d.type] ?? d.type,
                            style: const TextStyle(
                                color: AuraColors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 8),
                        Text(_visLabels[d.visibility] ?? '',
                            style: const TextStyle(
                                color: AuraColors.textSecondary, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                // No timestamp shown
              ],
            ),
          ),

          // Content
          if (d.type == 'reel' || d.type == 'video')
            Container(
              height: 160,
              color: d.color.withOpacity(0.12),
              child: Center(
                child: Icon(Icons.play_circle_fill,
                    color: d.color, size: 48),
              ),
            )
          else if (d.content != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: d.type == 'song'
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: d.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.music_note,
                              color: d.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(d.content!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    )
                  : d.type == 'momentCard'
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                d.color.withOpacity(0.3),
                                AuraColors.accent.withOpacity(0.3)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(d.content!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                              textAlign: TextAlign.center),
                        )
                      : Text(d.content!,
                          style: const TextStyle(fontSize: 14, height: 1.5)),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _pulsed = !_pulsed),
                  child: Row(children: [
                    Text(_pulsed ? '⚡' : '⚡',
                        style: TextStyle(
                            fontSize: 18,
                            color: _pulsed ? AuraColors.accent : null)),
                    const SizedBox(width: 4),
                    Text(
                      // Show count only if user prefers (simplified: always show here)
                      '${d.pulses + (_pulsed ? 1 : 0)}',
                      style: TextStyle(
                          color: _pulsed
                              ? AuraColors.accent : AuraColors.textSecondary,
                          fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(width: 20),
                Icon(Icons.visibility_outlined,
                    color: AuraColors.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text('${d.views}',
                    style: const TextStyle(
                        color: AuraColors.textSecondary, fontSize: 12)),
                const Spacer(),
                // No timestamp shown — by design
              ],
            ),
          ),
        ],
      ),
    );
  }
}
