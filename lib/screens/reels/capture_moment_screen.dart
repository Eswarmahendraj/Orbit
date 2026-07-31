import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/music_moment_model.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Capture Moment Screen
// Record a 10s clip (or take a photo) to attach to a song
// ─────────────────────────────────────────────────────────────────────────────

const _moods = [
  ('😭', 'emotional'),
  ('🔥', 'hype'),
  ('🌙', 'melancholy'),
  ('💚', 'peaceful'),
  ('😤', 'unmatched'),
  ('🥹', 'wholesome'),
  ('💀', 'dead'),
  ('✨', 'iconic'),
];

class CaptureMomentScreen extends StatefulWidget {
  final String song;
  final String artist;
  final String? previewUrl;
  final String? artUrl;

  const CaptureMomentScreen({
    super.key,
    required this.song,
    required this.artist,
    this.previewUrl,
    this.artUrl,
  });

  @override
  State<CaptureMomentScreen> createState() => _CaptureMomentScreenState();
}

class _CaptureMomentScreenState extends State<CaptureMomentScreen> {
  final _picker = ImagePicker();
  final _captionCtrl = TextEditingController();
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  File? _mediaFile;
  bool _isPhoto = false;
  VideoPlayerController? _videoCtrl;
  int _selectedMood = 0;
  bool _posting = false;
  bool _loadingVideo = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  Future<void> _recordClip() async {
    HapticFeedback.mediumImpact();
    final result = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 10),
    );
    if (result == null) return;
    setState(() { _isPhoto = false; _loadingVideo = true; _mediaFile = File(result.path); });
    await _initVideo(File(result.path));
  }

  Future<void> _pickFromGallery() async {
    HapticFeedback.lightImpact();
    final result = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 10),
    );
    if (result == null) return;
    setState(() { _isPhoto = false; _loadingVideo = true; _mediaFile = File(result.path); });
    await _initVideo(File(result.path));
  }

  Future<void> _takePhoto() async {
    HapticFeedback.lightImpact();
    final result = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (result == null) return;
    setState(() { _isPhoto = true; _loadingVideo = false; _mediaFile = File(result.path); });
    _videoCtrl?.dispose();
    _videoCtrl = null;
  }

  Future<void> _initVideo(File file) async {
    _videoCtrl?.dispose();
    final ctrl = VideoPlayerController.file(file);
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.play();
    if (!mounted) return;
    setState(() { _videoCtrl = ctrl; _loadingVideo = false; });
  }

  Future<void> _post() async {
    if (_mediaFile == null || _posting) return;
    final uid = _uid;
    if (uid == null) return;
    setState(() => _posting = true);
    HapticFeedback.mediumImpact();

    try {
      // Upload media to Firebase Storage
      final ext = _isPhoto ? 'jpg' : 'mp4';
      final path = 'moments/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putFile(
        _mediaFile!,
        SettableMetadata(contentType: _isPhoto ? 'image/jpeg' : 'video/mp4'),
      );
      final clipUrl = await ref.getDownloadURL();

      final (moodEmoji, mood) = _moods[_selectedMood];
      final songKey = MusicMoment.makeSongKey(widget.song, widget.artist);

      final moment = MusicMoment(
        id: '',
        uid: uid,
        username: '@${_state.username.isNotEmpty ? _state.username : 'you'}',
        displayName: _state.displayName.isNotEmpty ? _state.displayName : 'You',
        avatarEmoji: _state.avatarEmoji.isNotEmpty ? _state.avatarEmoji : '🎵',
        song: widget.song,
        artist: widget.artist,
        previewUrl: widget.previewUrl,
        artUrl: widget.artUrl,
        clipUrl: clipUrl,
        isPhoto: _isPhoto,
        mood: mood,
        moodEmoji: moodEmoji,
        caption: _captionCtrl.text.trim(),
        fires: 0,
        songKey: songKey,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('music_moments')
          .add(moment.toMap());

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true); // true = posted
      }
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post. Try again.')),
        );
      }
    }
  }

  void _reset() {
    _videoCtrl?.dispose();
    _videoCtrl = null;
    setState(() { _mediaFile = null; _isPhoto = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: SafeArea(
        child: _mediaFile == null ? _buildCapturePicker() : _buildPreview(),
      ),
    );
  }

  // ── Step 1: Choose capture mode ──────────────────────────────────────────

  Widget _buildCapturePicker() {
    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AuraTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('music moment',
              style: TextStyle(color: AuraTheme.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      const SizedBox(height: 24),

      // Song info pill
      _SongPill(song: widget.song, artist: widget.artist, artUrl: widget.artUrl),
      const SizedBox(height: 32),

      // Instruction
      const Text('capture your reaction',
          style: TextStyle(color: AuraTheme.textPrimary, fontSize: 22,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('10 seconds. no edits. just the vibe.',
          style: TextStyle(color: AuraTheme.textSecondary, fontSize: 14)),
      const SizedBox(height: 40),

      // Action buttons
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(children: [
          _CaptureButton(
            icon: Icons.videocam_rounded,
            label: 'record 10s clip',
            sublabel: 'camera',
            color: AuraTheme.accent,
            onTap: _recordClip,
          ),
          const SizedBox(height: 12),
          _CaptureButton(
            icon: Icons.photo_library_rounded,
            label: 'pick from gallery',
            sublabel: 'up to 10s',
            color: const Color(0xFF7C83FD),
            onTap: _pickFromGallery,
          ),
          const SizedBox(height: 12),
          _CaptureButton(
            icon: Icons.camera_alt_rounded,
            label: 'take a photo instead',
            sublabel: 'for the camera shy',
            color: const Color(0xFF4ECDC4),
            onTap: _takePhoto,
          ),
        ]),
      ),

      const Spacer(),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text('your moment + song = echo chain entry',
            style: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.6),
                fontSize: 12)),
      ),
    ]);
  }

  // ── Step 2: Preview + caption + post ────────────────────────────────────

  Widget _buildPreview() {
    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          GestureDetector(
            onTap: _reset,
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AuraTheme.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('preview',
              style: TextStyle(color: AuraTheme.textPrimary, fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: _post,
            child: _posting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AuraTheme.accent))
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AuraTheme.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('post',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Media preview
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(fit: StackFit.expand, children: [
              if (_isPhoto)
                Image.file(_mediaFile!, fit: BoxFit.cover)
              else if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
                FittedBox(fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoCtrl!.value.size.width,
                      height: _videoCtrl!.value.size.height,
                      child: VideoPlayer(_videoCtrl!),
                    ))
              else
                Container(color: AuraTheme.card,
                    child: const Center(child: CircularProgressIndicator(
                        color: AuraTheme.accent))),
              // Song pill overlay
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: _SongPill(song: widget.song, artist: widget.artist,
                    artUrl: widget.artUrl, dark: true),
              ),
              // Photo badge
              if (_isPhoto)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('📸 photo',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Mood selector
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('mood', style: TextStyle(color: AuraTheme.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (emoji, label) = _moods[i];
                final selected = _selectedMood == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMood = i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AuraTheme.accent.withOpacity(0.15)
                          : AuraTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AuraTheme.accent
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text('$emoji $label',
                        style: TextStyle(
                          color: selected ? AuraTheme.accent : AuraTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Caption
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _captionCtrl,
          style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 14),
          maxLength: 100,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'say something about this song…',
            hintStyle: TextStyle(color: AuraTheme.textSecondary.withOpacity(0.5),
                fontSize: 14),
            filled: true,
            fillColor: AuraTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            counterStyle: const TextStyle(color: AuraTheme.textSecondary,
                fontSize: 11),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _SongPill extends StatelessWidget {
  final String song;
  final String artist;
  final String? artUrl;
  final bool dark;
  const _SongPill({required this.song, required this.artist,
      this.artUrl, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.7) : AuraTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: artUrl != null
              ? CachedNetworkImage(imageUrl: artUrl!,
                  width: 32, height: 32, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _artFallback())
              : _artFallback(),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(song, style: const TextStyle(color: AuraTheme.textPrimary,
                fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(artist, style: const TextStyle(
                color: AuraTheme.textSecondary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        const Icon(Icons.music_note_rounded, color: AuraTheme.accent, size: 16),
      ]),
    );
  }

  Widget _artFallback() => Container(
    width: 32, height: 32, color: AuraTheme.accent.withOpacity(0.2),
    child: const Icon(Icons.music_note_rounded, color: AuraTheme.accent, size: 16),
  );
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _CaptureButton({required this.icon, required this.label,
      required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color,
                fontSize: 15, fontWeight: FontWeight.w700)),
            Text(sublabel, style: TextStyle(
                color: color.withOpacity(0.6), fontSize: 12)),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
  }
}
