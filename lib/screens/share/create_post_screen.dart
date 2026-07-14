import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/aura_theme.dart';
import '../../models/message_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _selectedType = 'story';
  PostVisibility _visibility = PostVisibility.closeCircle;
  final _textCtrl = TextEditingController();
  bool _posting = false;

  final _types = [
    ('story',  '📖', 'Story'),
    ('song',   '🎵', 'Song'),
    ('video',  '🎬', 'Video'),
    ('reel',   '▶️',  'Reel'),
  ];

  final _visOptions = [
    (PostVisibility.public,      '🌍', 'Public',       'Everyone on Orbit'),
    (PostVisibility.closeCircle, '🔒', 'Close Circle', 'Your trusted people'),
    (PostVisibility.private,     '👁️', 'Only Me',      'Saved privately'),
  ];

  Future<void> _post() async {
    if (_textCtrl.text.trim().isEmpty &&
        _selectedType != 'video' && _selectedType != 'reel') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some content first')));
      return;
    }
    setState(() => _posting = true);
    // TODO: upload to Firestore + Storage
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posted ✓'),
          backgroundColor: AuraColors.accent,
        ),
      );
    }
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('New Post'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: _posting ? null : _post,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(70, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16)),
            child: _posting
                ? const SizedBox(height: 16, width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Post'),
          ),
        ),
      ],
    ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          const Text('WHAT ARE YOU SHARING',
              style: TextStyle(color: AuraColors.textSecondary,
                  fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: _types.map((t) {
              final selected = _selectedType == t.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AuraColors.accent.withOpacity(0.2)
                          : AuraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AuraColors.accent : AuraColors.divider,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(t.$2, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(t.$3,
                            style: TextStyle(
                              color: selected
                                  ? AuraColors.accent : AuraColors.textSecondary,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 28),

          // Content input
          if (_selectedType == 'story') ...[
            const Text('CAPTION',
                style: TextStyle(color: AuraColors.textSecondary,
                    fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              maxLength: 280,
              decoration: const InputDecoration(
                hintText: 'What\'s the vibe right now?',
                alignLabelWithHint: true,
              ),
            ).animate().fadeIn(delay: 150.ms),
          ] else if (_selectedType == 'song') ...[
            const Text('SONG',
                style: TextStyle(color: AuraColors.textSecondary,
                    fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                hintText: 'Song name — Artist',
                prefixIcon: Icon(Icons.music_note_outlined,
                    color: AuraColors.textSecondary),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Connect Spotify'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuraColors.accent,
                side: const BorderSide(color: AuraColors.accent),
              ),
            ),
          ] else ...[
            // Video / Reel
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                await picker.pickVideo(source: ImageSource.gallery);
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AuraColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AuraColors.divider, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_outlined,
                        color: AuraColors.textSecondary, size: 40),
                    const SizedBox(height: 10),
                    const Text('Tap to pick a video',
                        style: TextStyle(color: AuraColors.textSecondary)),
                    if (_selectedType == 'reel')
                      const Text('Max 60 seconds',
                          style: TextStyle(
                              color: AuraColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(hintText: 'Add a caption...'),
            ),
          ],

          const SizedBox(height: 28),

          // Visibility
          const Text('WHO CAN SEE THIS',
              style: TextStyle(color: AuraColors.textSecondary,
                  fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ..._visOptions.map((opt) {
            final selected = _visibility == opt.$1;
            return GestureDetector(
              onTap: () => setState(() => _visibility = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? AuraColors.accent.withOpacity(0.12)
                      : AuraColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AuraColors.accent : AuraColors.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt.$2, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.$3,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AuraColors.accent : AuraColors.textPrimary,
                              )),
                          Text(opt.$4,
                              style: const TextStyle(
                                  color: AuraColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AuraColors.accent, size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: AuraColors.textSecondary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Posts disappear after 24 hours. No likes or views shown to you unless you turn them on in Settings.',
                    style: TextStyle(
                        color: AuraColors.textSecondary, fontSize: 12,
                        height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
