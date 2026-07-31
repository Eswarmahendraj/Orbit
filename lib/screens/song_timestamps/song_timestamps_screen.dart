import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/audio_player_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class SongTimestamp {
  final String id;
  final String uid;
  final String songTitle;
  final String artist;
  final String? artUrl;
  final int timestampSeconds; // position in track
  final String note; // user's comment about this moment
  final DateTime savedAt;

  SongTimestamp({
    required this.id,
    required this.uid,
    required this.songTitle,
    required this.artist,
    this.artUrl,
    required this.timestampSeconds,
    required this.note,
    required this.savedAt,
  });

  String get formattedTime {
    final m = timestampSeconds ~/ 60;
    final s = timestampSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory SongTimestamp.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SongTimestamp(
      id: doc.id,
      uid: d['uid'] ?? '',
      songTitle: d['songTitle'] ?? '',
      artist: d['artist'] ?? '',
      artUrl: d['artUrl'],
      timestampSeconds: d['timestampSeconds'] ?? 0,
      note: d['note'] ?? '',
      savedAt: (d['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'songTitle': songTitle,
        'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        'timestampSeconds': timestampSeconds,
        'note': note,
        'savedAt': FieldValue.serverTimestamp(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class SongTimestampService {
  static final SongTimestampService _instance =
      SongTimestampService._internal();
  factory SongTimestampService() => _instance;
  SongTimestampService._internal();

  final _col =
      FirebaseFirestore.instance.collection('song_timestamps');

  Future<void> saveTimestamp(SongTimestamp ts) async {
    await _col.add(ts.toMap());
  }

  Future<void> deleteTimestamp(String id) async {
    await _col.doc(id).delete();
  }

  Stream<List<SongTimestamp>> myTimestampsStream(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => SongTimestamp.fromFirestore(d)).toList());
  }

  /// Timestamps for a specific song
  Stream<List<SongTimestamp>> songTimestampsStream(
      String uid, String songTitle) {
    return _col
        .where('uid', isEqualTo: uid)
        .where('songTitle', isEqualTo: songTitle)
        .orderBy('timestampSeconds')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => SongTimestamp.fromFirestore(d)).toList());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen — list of all bookmarks
// ─────────────────────────────────────────────────────────────────────────────
class SongTimestampsScreen extends StatelessWidget {
  const SongTimestampsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;
    final state = Provider.of<OrbitState>(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Song Timestamps',
          style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_add_rounded,
                color: theme.accent, size: 26),
            onPressed: () => _showAddSheet(context, state, theme),
            tooltip: 'Bookmark moment',
          ),
        ],
      ),
      body: StreamBuilder<List<SongTimestamp>>(
        stream: SongTimestampService().myTimestampsStream(state.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.accent));
          }

          final timestamps = snap.data ?? [];

          if (timestamps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⏱️', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark a moment in a song that hits',
                    style: TextStyle(
                        color: theme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Group by song
          final grouped = <String, List<SongTimestamp>>{};
          for (final ts in timestamps) {
            grouped
                .putIfAbsent('${ts.songTitle}||${ts.artist}', () => [])
                .add(ts);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final entry = grouped.entries.elementAt(i);
              final parts = entry.key.split('||');
              return _SongGroup(
                songTitle: parts[0],
                artist: parts.length > 1 ? parts[1] : '',
                timestamps: entry.value,
                theme: theme,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, state, theme),
        backgroundColor: theme.accent,
        icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
        label: const Text('Bookmark',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddSheet(
      BuildContext context, OrbitState state, AuraTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTimestampSheet(state: state, theme: theme),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Song Group (song header + its timestamps)
// ─────────────────────────────────────────────────────────────────────────────
class _SongGroup extends StatelessWidget {
  final String songTitle;
  final String artist;
  final List<SongTimestamp> timestamps;
  final AuraTheme theme;

  const _SongGroup({
    required this.songTitle,
    required this.artist,
    required this.timestamps,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final artUrl = timestamps.first.artUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (artUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      artUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _artPlaceholder(theme),
                    ),
                  )
                else
                  _artPlaceholder(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${timestamps.length} moment${timestamps.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: theme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: theme.divider, height: 1),

          // Timestamps list
          ...timestamps.map((ts) => _TimestampRow(
                ts: ts,
                theme: theme,
                onDelete: () =>
                    SongTimestampService().deleteTimestamp(ts.id),
              )),
        ],
      ),
    );
  }

  Widget _artPlaceholder(AuraTheme theme) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.music_note_rounded,
            color: theme.accent, size: 24),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Timestamp Row
// ─────────────────────────────────────────────────────────────────────────────
class _TimestampRow extends StatelessWidget {
  final SongTimestamp ts;
  final AuraTheme theme;
  final VoidCallback onDelete;

  const _TimestampRow({
    required this.ts,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(ts.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withOpacity(0.12),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            // Timestamp badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_rounded,
                      color: theme.accent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    ts.formattedTime,
                    style: TextStyle(
                        color: theme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Note
            Expanded(
              child: Text(
                ts.note.isEmpty ? 'No note' : ts.note,
                style: TextStyle(
                    color: ts.note.isEmpty
                        ? theme.textMuted
                        : theme.textPrimary,
                    fontSize: 14,
                    fontStyle: ts.note.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Swipe hint
            Icon(Icons.chevron_left_rounded,
                color: theme.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Timestamp Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddTimestampSheet extends StatefulWidget {
  final OrbitState state;
  final AuraTheme theme;

  const _AddTimestampSheet({required this.state, required this.theme});

  @override
  State<_AddTimestampSheet> createState() => _AddTimestampSheetState();
}

class _AddTimestampSheetState extends State<_AddTimestampSheet> {
  final _noteCtrl = TextEditingController();
  final _minuteCtrl = TextEditingController();
  final _secondCtrl = TextEditingController();
  bool _loading = false;
  bool _useNowPlaying = true;

  late final AudioPlayerService _player;
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _player = AudioPlayerService();
    if (_player.currentTitle.isNotEmpty) {
      _titleCtrl.text = _player.currentTitle;
      _artistCtrl.text = _player.currentArtist;
    } else {
      _useNowPlaying = false;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _minuteCtrl.dispose();
    _secondCtrl.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  int get _totalSeconds {
    final m = int.tryParse(_minuteCtrl.text) ?? 0;
    final s = int.tryParse(_secondCtrl.text) ?? 0;
    return (m * 60 + s).clamp(0, 9999);
  }

  Future<void> _save() async {
    final title = _useNowPlaying
        ? _player.currentTitle
        : _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _loading = true);
    try {
      final ts = SongTimestamp(
        id: '',
        uid: widget.state.uid,
        songTitle: title,
        artist: _useNowPlaying
            ? _player.currentArtist
            : _artistCtrl.text.trim(),
        artUrl: _useNowPlaying ? _player.currentArtUrl : null,
        timestampSeconds: _totalSeconds,
        note: _noteCtrl.text.trim(),
        savedAt: DateTime.now(),
      );
      await SongTimestampService().saveTimestamp(ts);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasNowPlaying = _player.currentTitle.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bookmark a Moment',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Now Playing toggle
            if (hasNowPlaying) ...[
              GestureDetector(
                onTap: () =>
                    setState(() => _useNowPlaying = !_useNowPlaying),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _useNowPlaying
                        ? theme.accent.withOpacity(0.12)
                        : theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useNowPlaying
                          ? theme.accent.withOpacity(0.4)
                          : theme.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          color: _useNowPlaying
                              ? theme.accent
                              : theme.textMuted,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Now Playing',
                              style: TextStyle(
                                  color: theme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _player.currentTitle,
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _useNowPlaying
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _useNowPlaying
                            ? theme.accent
                            : theme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (!_useNowPlaying) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Song title',
                    hintStyle: TextStyle(color: theme.textMuted),
                    filled: true,
                    fillColor: theme.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _artistCtrl,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Artist',
                    hintStyle: TextStyle(color: theme.textMuted),
                    filled: true,
                    fillColor: theme.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Timestamp input (MM:SS)
            Text(
              'Timestamp',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minuteCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '00',
                      hintStyle: TextStyle(
                          color: theme.textMuted,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: theme.cardBackground,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLength: 2,
                    buildCounter: (_, {required currentLength,
                            required isFocused, maxLength}) =>
                        null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    ':',
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _secondCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '00',
                      hintStyle: TextStyle(
                          color: theme.textMuted,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: theme.cardBackground,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLength: 2,
                    buildCounter: (_, {required currentLength,
                            required isFocused, maxLength}) =>
                        null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'e.g. 2:34 = "the drop at 2 minutes 34 seconds"',
              style: TextStyle(color: theme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // Note
            Text(
              'Note (optional)',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 120,
              style: TextStyle(color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'This is where the chorus drops...',
                hintStyle: TextStyle(color: theme.textMuted),
                filled: true,
                fillColor: theme.cardBackground,
                counterStyle:
                    TextStyle(color: theme.textMuted, fontSize: 11),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text(
                  'Save Bookmark',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
