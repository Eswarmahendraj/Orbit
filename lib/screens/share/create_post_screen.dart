import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/aura_theme.dart';
import '../../models/message_model.dart';
import '../../models/orbit_state.dart';
import '../stories/snap_filters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreatePostScreen — unified post creator
// Photo type: picker + filters + song + @tags + vibe tag → reel-style feed card
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _selectedType = 'photo';
  PostVisibility _visibility = PostVisibility.closeCircle;
  final _captionCtrl = TextEditingController();
  bool _posting = false;

  // ── Photo state ───────────────────────────────────────────────────────────
  File? _photo;
  SnapFilter? _filter;
  _SongEntry? _song;
  String? _vibeTag;
  String? _vibeEmoji;
  final Set<String> _taggedFriends = {};

  // ── Other types ───────────────────────────────────────────────────────────
  final _textCtrl = TextEditingController();

  // ── Poll state (for Moment type) ─────────────────────────────────────────
  bool _pollEnabled = false;
  final _pollOpt1Ctrl = TextEditingController();
  final _pollOpt2Ctrl = TextEditingController();

  static const _types = [
    ('photo',  '📸', 'Photo'),
    ('moment', '✨', 'Moment'),
    ('song',   '🎵', 'Song'),
    ('video',  '🎬', 'Video'),
    ('reel',   '▶️',  'Reel'),
  ];

  static const _visOptions = [
    (PostVisibility.public,      '🌍', 'Public',       'Everyone on Orbit'),
    (PostVisibility.closeCircle, '🔒', 'Close Circle', 'Your trusted people'),
    (PostVisibility.private,     '👁️', 'Only Me',      'Saved privately'),
  ];

  static const _vibes = [
    ('✨', 'ethereal'), ('🌙', 'moody'),  ('🔥', 'lit'),
    ('💫', 'dreamy'),  ('🌊', 'chill'),  ('⚡', 'electric'),
    ('🌸', 'soft'),    ('🖤', 'dark'),   ('😤', 'unhinged'),
    ('🎯', 'focused'), ('🫦', 'flirty'), ('🤍', 'pure'),
  ];

  static const _songs = [
    _SongEntry('Blinding Lights',    'The Weeknd',    '3:20', '🌙'),
    _SongEntry('Golden Hour',        'JVKE',          '2:37', '☀️'),
    _SongEntry('Espresso',           'Sabrina Carpenter', '2:55', '☕'),
    _SongEntry('Cruel Summer',       'Taylor Swift',  '2:58', '🌞'),
    _SongEntry('Levitating',         'Dua Lipa',      '3:23', '🚀'),
    _SongEntry('As It Was',          'Harry Styles',  '2:37', '🌿'),
    _SongEntry('Die For You',        'The Weeknd',    '4:20', '🥀'),
    _SongEntry('Starboy',            'The Weeknd',    '3:50', '⭐'),
    _SongEntry('good 4 u',           'Olivia Rodrigo','2:58', '🎸'),
    _SongEntry('Heat Waves',         'Glass Animals', '3:59', '🌊'),
    _SongEntry('Montero',            'Lil Nas X',     '2:17', '🐍'),
    _SongEntry('Peaches',            'Justin Bieber', '3:18', '🍑'),
  ];

  static const _orbitFriends = [
    ('Dev S',    '🎧', Color(0xFF3498DB)),
    ('Karan M',  '🌙', Color(0xFFE74C3C)),
    ('Ananya T', '✨', Color(0xFFFF69B4)),
    ('Rohan K',  '🔥', Color(0xFFFF9800)),
    ('Priya V',  '💫', Color(0xFF9B59B6)),
    ('Arjun R',  '⚡', Color(0xFF00BCD4)),
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    _textCtrl.dispose();
    _pollOpt1Ctrl.dispose();
    _pollOpt2Ctrl.dispose();
    super.dispose();
  }

  // ── Photo picker ──────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource src) async {
    final xf = await ImagePicker().pickImage(
        source: src, imageQuality: 90, maxWidth: 1080);
    if (xf != null && mounted) setState(() => _photo = File(xf.path));
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(backgroundColor: AuraTheme.accent.withOpacity(0.15),
                child: const Icon(Icons.camera_alt_rounded, color: AuraTheme.accent)),
            title: Text('Camera', style: TextStyle(fontWeight: FontWeight.w600,
                color: AuraTheme.themeTextPrimary)),
            onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: AuraTheme.accent.withOpacity(0.15),
                child: const Icon(Icons.photo_library_rounded, color: AuraTheme.accent)),
            title: Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600,
                color: AuraTheme.themeTextPrimary)),
            onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  // ── Song picker ───────────────────────────────────────────────────────────

  void _showSongPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(children: [
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Pick a song', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, color: AuraTheme.themeTextPrimary)),
              const SizedBox(height: 4),
              Text('Added to your photo as background audio',
                  style: TextStyle(fontSize: 12, color: AuraTheme.themeTextMuted)),
              const SizedBox(height: 12),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _songs.length,
              itemBuilder: (_, i) {
                final s = _songs[i];
                final sel = _song?.title == s.title;
                return ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AuraTheme.accent, AuraTheme.accent.withOpacity(0.6)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(s.emoji,
                        style: const TextStyle(fontSize: 20))),
                  ),
                  title: Text(s.title, style: TextStyle(fontWeight: FontWeight.w600,
                      color: sel ? AuraTheme.accent : AuraTheme.themeTextPrimary)),
                  subtitle: Text('${s.artist} · ${s.duration}',
                      style: TextStyle(fontSize: 12, color: AuraTheme.themeTextMuted)),
                  trailing: sel
                      ? const Icon(Icons.check_circle_rounded, color: AuraTheme.accent)
                      : const Icon(Icons.add_circle_outline_rounded,
                          color: AuraTheme.accent, size: 22),
                  onTap: () { setState(() => _song = s); Navigator.pop(context); },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Vibe tag picker ───────────────────────────────────────────────────────

  void _showVibePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Set the vibe', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: AuraTheme.themeTextPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _vibes.map((v) {
                final sel = _vibeTag == v.$2;
                return GestureDetector(
                  onTap: () {
                    setState(() { _vibeTag = v.$2; _vibeEmoji = v.$1; });
                    setInner(() {});
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AuraTheme.accent.withOpacity(0.15) : AuraTheme.themeSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: sel ? AuraTheme.accent : AuraTheme.themeSurface,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text('${v.$1}  ${v.$2}',
                        style: TextStyle(
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? AuraTheme.accent : AuraTheme.themeTextPrimary,
                            fontSize: 14)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Tag friends ───────────────────────────────────────────────────────────

  void _showTagFriends() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Tag your people', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: AuraTheme.themeTextPrimary)),
            const SizedBox(height: 12),
            ..._orbitFriends.map((f) {
              final tagged = _taggedFriends.contains(f.$1);
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: f.$3.withOpacity(0.18),
                  child: Text(f.$2, style: const TextStyle(fontSize: 18)),
                ),
                title: Text(f.$1, style: TextStyle(fontWeight: FontWeight.w600,
                    color: AuraTheme.themeTextPrimary)),
                trailing: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (tagged) _taggedFriends.remove(f.$1);
                      else _taggedFriends.add(f.$1);
                    });
                    setInner(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: tagged ? AuraTheme.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AuraTheme.accent),
                    ),
                    child: Text(tagged ? '✓ tagged' : '+ tag',
                        style: TextStyle(
                            color: tagged ? Colors.white : AuraTheme.accent,
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              );
            }),
          ]),
        ),
      ),
    );
  }

  // ── Post ──────────────────────────────────────────────────────────────────

  Future<void> _post() async {
    if (_selectedType == 'photo') {
      if (_photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pick a photo first')));
        return;
      }
      if (_song == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add a song — it\'s what makes it ✨')));
        return;
      }
    } else if (_textCtrl.text.trim().isEmpty &&
        _selectedType != 'video' && _selectedType != 'reel') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add some content first')));
      return;
    }

    setState(() => _posting = true);

    final state = OrbitState();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ts = DateTime.now().toIso8601String();

    if (_selectedType == 'photo') {
      state.addPost({
        'id': id,
        'type': 'photo',
        'photoPath': _photo!.path,
        'song': _song!.title,
        'artist': _song!.artist,
        'songEmoji': _song!.emoji,
        'filterId': _filter?.id ?? '',
        'vibeTag': _vibeTag ?? '',
        'vibeEmoji': _vibeEmoji ?? '',
        'taggedFriends': _taggedFriends.toList(),
        'caption': _captionCtrl.text,
        'visibility': _visibility.name,
        'timestamp': ts,
      });
    } else if (_selectedType == 'moment') {
      final momentData = {
        'id': id,
        'type': 'moment',
        'text': _textCtrl.text,
        'visibility': _visibility.name,
        'timestamp': ts,
      };
      if (_pollEnabled &&
          _pollOpt1Ctrl.text.trim().isNotEmpty &&
          _pollOpt2Ctrl.text.trim().isNotEmpty) {
        momentData['pollOption1'] = _pollOpt1Ctrl.text.trim();
        momentData['pollOption2'] = _pollOpt2Ctrl.text.trim();
        momentData['pollVote1'] = '0';
        momentData['pollVote2'] = '0';
        momentData['pollVotedOption'] = '';
      }
      state.addMoment(momentData);
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_selectedType == 'photo'
            ? '📸 Photo posted — song plays while people view it!'
            : _selectedType == 'moment'
                ? '✨ Moment posted! Streak: ${state.momentStreak} 🔥'
                : 'Posted ✓'),
        backgroundColor: AuraTheme.accent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: Text('New Post', style: TextStyle(
            fontWeight: FontWeight.w800, color: AuraTheme.themeTextPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _posting ? null : _post,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _posting ? null : const LinearGradient(
                      colors: [Color(0xFFFF8C42), Color(0xFFFFAD75)]),
                  color: _posting ? Colors.grey.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _posting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AuraTheme.accent))
                    : const Text('Post', style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Type selector ──────────────────────────────────────────────────
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              itemBuilder: (_, i) {
                final t = _types[i];
                final sel = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    width: 72,
                    decoration: BoxDecoration(
                      color: sel ? AuraTheme.accent.withOpacity(0.12) : AuraTheme.themeSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? AuraTheme.accent : Colors.transparent,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(t.$2, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(t.$3, style: TextStyle(
                          color: sel ? AuraTheme.accent : AuraTheme.themeTextMuted,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                    ]),
                  ),
                );
              },
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),

          // ── Photo type ─────────────────────────────────────────────────────
          if (_selectedType == 'photo') ...[

            // Photo preview / picker
            GestureDetector(
              onTap: _photo == null ? _showPhotoPicker : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: _photo == null
                      ? _PhotoPickerPlaceholder(onCamera: () => _pickPhoto(ImageSource.camera),
                          onGallery: () => _pickPhoto(ImageSource.gallery))
                      : Stack(fit: StackFit.expand, children: [
                          // Filtered photo
                          ColorFiltered(
                            colorFilter: ColorFilter.matrix(
                                _filter?.matrix ?? _kIdentity),
                            child: Image.file(_photo!, fit: BoxFit.cover),
                          ),
                          // Filter animated overlay
                          if (_filter != null)
                            IgnorePointer(child: SnapFilterOverlay(filterId: _filter!.id)),
                          // Song badge (bottom-left)
                          if (_song != null)
                            Positioned(
                              bottom: 12, left: 12,
                              child: _SongBadge(song: _song!),
                            ),
                          // Vibe tag badge
                          if (_vibeTag != null)
                            Positioned(
                              top: 12, left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('$_vibeEmoji  $_vibeTag',
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          // Tagged friends
                          if (_taggedFriends.isNotEmpty)
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('👥 ${_taggedFriends.length}',
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          // Change photo button
                          Positioned(
                            bottom: 12, right: 12,
                            child: GestureDetector(
                              onTap: _showPhotoPicker,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ]),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            // Filter strip (only when photo selected)
            if (_photo != null) ...[
              const SizedBox(height: 12),
              SnapFilterPicker(
                selected: _filter,
                onSelect: (f) => setState(() => _filter = f),
              ),
            ],

            const SizedBox(height: 20),

            // ── Song (mandatory) ──────────────────────────────────────────
            _sectionLabel('song  •  required'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showSongPicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _song != null
                      ? AuraTheme.accent.withOpacity(0.1)
                      : AuraTheme.themeSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _song != null ? AuraTheme.accent : Colors.transparent,
                    width: _song != null ? 1.5 : 1,
                  ),
                ),
                child: _song == null
                    ? Row(children: [
                        const Icon(Icons.music_note_rounded,
                            color: AuraTheme.accent, size: 22),
                        const SizedBox(width: 12),
                        Text('Pick a song',
                            style: TextStyle(fontWeight: FontWeight.w600,
                                color: AuraTheme.themeTextPrimary)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AuraTheme.accent),
                      ])
                    : Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFF8C42), Color(0xFFFFAD75)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(_song!.emoji,
                              style: const TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_song!.title, style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AuraTheme.themeTextPrimary)),
                            Text(_song!.artist, style: TextStyle(
                                fontSize: 12, color: AuraTheme.themeTextMuted)),
                          ],
                        )),
                        GestureDetector(
                          onTap: _showSongPicker,
                          child: Text('change', style: TextStyle(
                              color: AuraTheme.accent, fontSize: 12,
                              fontWeight: FontWeight.w600)),
                        ),
                      ]),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // ── Caption ───────────────────────────────────────────────────
            _sectionLabel('caption'),
            const SizedBox(height: 8),
            TextField(
              controller: _captionCtrl,
              maxLines: 3,
              maxLength: 200,
              style: TextStyle(color: AuraTheme.themeTextPrimary),
              decoration: InputDecoration(
                hintText: 'say something or let the song do the talking...',
                hintStyle: TextStyle(color: AuraTheme.themeTextMuted),
              ),
            ).animate().fadeIn(delay: 180.ms),

            const SizedBox(height: 16),

            // ── Vibe tag + Tag friends ────────────────────────────────────
            Row(children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.tag_rounded,
                  label: _vibeTag != null
                      ? '$_vibeEmoji  $_vibeTag'
                      : 'set vibe',
                  active: _vibeTag != null,
                  onTap: _showVibePicker,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  icon: Icons.person_add_alt_1_rounded,
                  label: _taggedFriends.isEmpty
                      ? 'tag friends'
                      : '${_taggedFriends.length} tagged',
                  active: _taggedFriends.isNotEmpty,
                  onTap: _showTagFriends,
                ),
              ),
            ]).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // ── Reel preview note ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.play_circle_outline_rounded,
                    color: AuraTheme.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Shows as a full-screen card in the Pulse feed with the song playing. Swipe up to scroll.',
                  style: TextStyle(color: AuraTheme.accent,
                      fontSize: 12, height: 1.5),
                )),
              ]),
            ).animate().fadeIn(delay: 220.ms),

            const SizedBox(height: 24),
          ],

          // ── Moment type ─────────────────────────────────────────────────
          if (_selectedType == 'moment') ...[
            _sectionLabel('what\'s happening in your world?'),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              maxLength: 280,
              decoration: const InputDecoration(
                  hintText: 'say something real... post a moment a day to keep the streak alive 🔥'),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Post at least one Moment per day to build your streak. Miss a day and it resets.',
                    style: TextStyle(
                        fontSize: 11, color: AuraTheme.accent, height: 1.4),
                  ),
                ),
              ]),
            ).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 12),

            // Poll toggle
            GestureDetector(
              onTap: () => setState(() => _pollEnabled = !_pollEnabled),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _pollEnabled
                      ? AuraTheme.accent.withOpacity(0.1)
                      : AuraTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pollEnabled
                        ? AuraTheme.accent.withOpacity(0.4)
                        : AuraTheme.textMuted.withOpacity(0.15),
                  ),
                ),
                child: Row(children: [
                  Icon(
                    Icons.poll_outlined,
                    color: _pollEnabled ? AuraTheme.accent : AuraTheme.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pollEnabled ? 'poll added ✓' : 'add a poll',
                      style: TextStyle(
                          color: _pollEnabled
                              ? AuraTheme.accent
                              : AuraTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  Switch(
                    value: _pollEnabled,
                    onChanged: (v) => setState(() => _pollEnabled = v),
                    activeColor: AuraTheme.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ]),
              ),
            ).animate().fadeIn(delay: 140.ms),

            if (_pollEnabled) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _pollOpt1Ctrl,
                decoration: InputDecoration(
                  hintText: 'Option A',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AuraTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('A',
                        style: TextStyle(
                            color: AuraTheme.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              TextField(
                controller: _pollOpt2Ctrl,
                decoration: InputDecoration(
                  hintText: 'Option B',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('B',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ),
              ).animate().fadeIn(delay: 60.ms),
            ],
            const SizedBox(height: 24),
          ],

          // ── Song type ─────────────────────────────────────────────────
          if (_selectedType == 'song') ...[
            _sectionLabel('song'),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(
                hintText: 'Song name — Artist',
                prefixIcon: Icon(Icons.music_note_outlined, color: AuraTheme.accent),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Connect Spotify'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuraTheme.accent,
                side: const BorderSide(color: AuraTheme.accent),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Video / Reel type ─────────────────────────────────────────
          if (_selectedType == 'video' || _selectedType == 'reel') ...[
            GestureDetector(
              onTap: () async {
                await ImagePicker().pickVideo(source: ImageSource.gallery,
                    maxDuration: Duration(seconds: _selectedType == 'reel' ? 60 : 300));
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AuraTheme.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuraTheme.themeSurface),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.videocam_outlined,
                      color: AuraTheme.themeTextMuted, size: 40),
                  const SizedBox(height: 10),
                  Text('Tap to pick a video',
                      style: TextStyle(color: AuraTheme.themeTextMuted)),
                  if (_selectedType == 'reel')
                    Text('Max 60 seconds',
                        style: TextStyle(color: AuraTheme.themeTextMuted, fontSize: 12)),
                ]),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              decoration: const InputDecoration(hintText: 'Add a caption...'),
            ),
            const SizedBox(height: 24),
          ],

          // ── Visibility (all types) ────────────────────────────────────
          _sectionLabel('who can see this'),
          const SizedBox(height: 10),
          ..._visOptions.map((opt) {
            final sel = _visibility == opt.$1;
            return GestureDetector(
              onTap: () => setState(() => _visibility = opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel
                      ? AuraTheme.accent.withOpacity(0.1) : AuraTheme.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AuraTheme.accent : Colors.transparent,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Text(opt.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.$3, style: TextStyle(fontWeight: FontWeight.w600,
                          color: sel ? AuraTheme.accent : AuraTheme.themeTextPrimary)),
                      Text(opt.$4, style: TextStyle(
                          color: AuraTheme.themeTextMuted, fontSize: 12)),
                    ],
                  )),
                  if (sel) const Icon(Icons.check_circle_rounded,
                      color: AuraTheme.accent, size: 20),
                ]),
              ),
            );
          }),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.themeSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AuraTheme.themeTextMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _selectedType == 'photo'
                    ? 'Photo posts live in your Pulse feed forever unless you delete them. Song plays on loop while viewed.'
                    : 'Posts disappear after 24 hours. No likes or views shown unless you turn them on in Settings.',
                style: TextStyle(color: AuraTheme.themeTextMuted,
                    fontSize: 12, height: 1.5),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(color: AuraTheme.themeTextMuted,
        fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w600),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Song model
// ─────────────────────────────────────────────────────────────────────────────

class _SongEntry {
  final String title, artist, duration, emoji;
  const _SongEntry(this.title, this.artist, this.duration, this.emoji);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kIdentity = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

class _PhotoPickerPlaceholder extends StatelessWidget {
  final VoidCallback onCamera, onGallery;
  const _PhotoPickerPlaceholder({required this.onCamera, required this.onGallery}  const _PhotoPickerPlaceholder({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AuraTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraTheme.accent.withOpacity(0.2)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _PickerButton(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: onCamera,
          ),
          const SizedBox(width: 24),
          _PickerButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: onGallery,
          ),
        ]),
        const SizedBox(height: 12),
        const Text('tap to add a photo',
            style: TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
      ]),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AuraTheme.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AuraTheme.accent, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AuraTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

          Text(label, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _SongBadge extends StatelessWidget {
  final _SongEntry song;
  const _SongBadge({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(song.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
          Text(song.title, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          Text(song.artist, style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 10)),
        ]),
        const SizedBox(width: 8),
        const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
      ]),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AuraTheme.accent.withOpacity(0.1) : AuraTheme.themeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AuraTheme.accent : Colors.transparent,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? AuraTheme.accent : AuraTheme.themeTextMuted, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(
              color: active ? AuraTheme.accent : AuraTheme.themeTextMuted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
