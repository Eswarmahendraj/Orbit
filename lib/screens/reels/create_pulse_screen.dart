import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Create Pulse Screen
// Pick video or photo + add song + caption + audience + post
// ─────────────────────────────────────────────────────────────────────────────

enum _PulseAudience { everyone, orbit, closeFriends }

class CreatePulseScreen extends StatefulWidget {
  const CreatePulseScreen({super.key});
  @override
  State<CreatePulseScreen> createState() => _CreatePulseScreenState();
}

class _CreatePulseScreenState extends State<CreatePulseScreen> {
  File? _videoFile;
  File? _thumbFile;
  String? _songName;
  String? _songArtist;
  final _captionCtrl = TextEditingController();
  _PulseAudience _audience = _PulseAudience.everyone;
  bool _posting = false;

  static const _audienceOptions = [
    (_PulseAudience.everyone, '🌍', 'Everyone'),
    (_PulseAudience.orbit, '🪐', 'Your Orbit'),
    (_PulseAudience.closeFriends, '⭐', 'Close Friends'),
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final result = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (result == null) return;
    setState(() => _videoFile = File(result.path));
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final result = await picker.pickVideo(source: ImageSource.gallery);
    if (result == null) return;
    setState(() => _videoFile = File(result.path));
  }

  void _showSongPicker() {
    final songs = [
      ('Espresso', 'Sabrina Carpenter'),
      ('APT.', 'ROSÉ & Bruno Mars'),
      ('luther', 'Kendrick Lamar & SZA'),
      ('Golden Hour', 'JVKE'),
      ('Die With A Smile', 'Lady Gaga & Bruno Mars'),
      ('Levitating', 'Dua Lipa'),
      ('Blinding Lights', 'The Weeknd'),
      ('As It Was', 'Harry Styles'),
      ('STAY', 'The Kid LAROI & Justin Bieber'),
      ('Peaches', 'Justin Bieber ft. Daniel Caesar'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: AuraTheme.themeSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.themeDivider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              style: TextStyle(color: AuraTheme.themeTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search songs...',
                hintStyle: TextStyle(color: AuraTheme.themeTextMuted),
                filled: true,
                fillColor: AuraTheme.themeCard,
                prefixIcon: Icon(Icons.search_rounded,
                    color: AuraTheme.themeTextMuted),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final s = songs[i];
                return ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AuraTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.music_note_rounded,
                        color: AuraTheme.accent, size: 20),
                  ),
                  title: Text(s.$1,
                      style: TextStyle(
                          color: AuraTheme.themeTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: Text(s.$2,
                      style: TextStyle(
                          color: AuraTheme.themeTextSecondary,
                          fontSize: 12)),
                  onTap: () {
                    setState(() {
                      _songName = s.$1;
                      _songArtist = s.$2;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _post() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a video first')),
      );
      return;
    }
    setState(() => _posting = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate upload
    if (!mounted) return;
    setState(() => _posting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🔥 Pulse posted to your orbit!'),
        backgroundColor: AuraTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.themeBg,
      appBar: AppBar(
        backgroundColor: AuraTheme.themeBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AuraTheme.themeTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Pulse',
            style: TextStyle(
                color: AuraTheme.themeTextPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        actions: [
          _posting
              ? const Padding(
                  padding: EdgeInsets.only(right: 16, top: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AuraTheme.accent, strokeWidth: 2.5),
                  ),
                )
              : TextButton(
                  onPressed: _post,
                  child: const Text('Post',
                      style: TextStyle(
                          color: AuraTheme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Video preview / pick ────────────────────────────────────────
          GestureDetector(
            onTap: _videoFile == null ? null : () {},
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AuraTheme.themeCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AuraTheme.themeDivider),
              ),
              child: _videoFile != null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.play_circle_fill_rounded,
                                  color: Colors.white70, size: 56),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _videoFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_camera_back_outlined,
                            color: AuraTheme.themeTextMuted, size: 48),
                        const SizedBox(height: 12),
                        Text('Add a video',
                            style: TextStyle(
                                color: AuraTheme.themeTextSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PickBtn(
                              icon: Icons.videocam_rounded,
                              label: 'Record',
                              onTap: _pickVideo,
                            ),
                            const SizedBox(width: 12),
                            _PickBtn(
                              icon: Icons.photo_library_outlined,
                              label: 'Gallery',
                              onTap: _pickFromGallery,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Caption ─────────────────────────────────────────────────────
          _SectionLabel('caption'),
          Container(
            decoration: BoxDecoration(
              color: AuraTheme.themeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AuraTheme.themeDivider),
            ),
            child: TextField(
              controller: _captionCtrl,
              maxLines: 3,
              maxLength: 150,
              style: TextStyle(color: AuraTheme.themeTextPrimary),
              decoration: InputDecoration(
                hintText: 'What\'s the vibe? ✨',
                hintStyle: TextStyle(color: AuraTheme.themeTextMuted),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: TextStyle(color: AuraTheme.themeTextMuted),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Add song ────────────────────────────────────────────────────
          _SectionLabel('add a song'),
          GestureDetector(
            onTap: _showSongPicker,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuraTheme.themeCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraTheme.themeDivider),
              ),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _songName != null
                        ? AuraTheme.accent.withOpacity(0.15)
                        : AuraTheme.themeSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _songName != null
                        ? Icons.music_note_rounded
                        : Icons.add_rounded,
                    color: _songName != null
                        ? AuraTheme.accent
                        : AuraTheme.themeTextMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _songName != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(_songName!,
                              style: TextStyle(
                                  color: AuraTheme.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(_songArtist ?? '',
                              style: TextStyle(
                                  color: AuraTheme.themeTextSecondary,
                                  fontSize: 12)),
                        ])
                      : Text('Choose a song',
                          style: TextStyle(
                              color: AuraTheme.themeTextMuted,
                              fontSize: 14)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AuraTheme.themeTextMuted),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── Audience ────────────────────────────────────────────────────
          _SectionLabel('who can see this'),
          Row(
            children: _audienceOptions.map((opt) {
              final selected = _audience == opt.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _audience = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(
                        right: opt.$1 != _PulseAudience.closeFriends ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AuraTheme.accent
                          : AuraTheme.themeCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? AuraTheme.accent
                              : AuraTheme.themeDivider),
                    ),
                    child: Column(children: [
                      Text(opt.$2, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        opt.$3,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AuraTheme.themeTextSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // ── Post button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _posting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _posting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('🔥 Post Pulse',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
            ),
          ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AuraTheme.themeTextMuted),
      ),
    );
  }
}

class _PickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AuraTheme.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    );
  }
}
