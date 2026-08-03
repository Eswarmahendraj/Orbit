import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

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
    final state = Provider.of<OrbitState>(context);

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: Text(
          'Song Timestamps',
          style: TextStyle(
              color: AuraTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_add_rounded,
                color: AuraTheme.accent, size: 26),
            onPressed: () => _showAddSheet(context, state),
            tooltip: 'Bookmark moment',
          ),
        ],
      ),
      body: StreamBuilder<List<SongTimestamp>>(
        stream: SongTimestampService().myTimestampsStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AuraTheme.accent));
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
                        color: AuraTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark a moment in a song that hits',
                    style: TextStyle(
                        color: AuraTheme.textSecondary, fontSize: 14),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, state),
        backgroundColor: AuraTheme.accent,
        icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
        label: const Text('Bookmark',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddSheet(
      BuildContext context, OrbitState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTimestampSheet(state: state),
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

  const _SongGroup({
    required this.songTitle,
    required this.artist,
    required this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    final artUrl = timestamps.first.artUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E30)),
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
                          _artPlaceholder(),
                    ),
                  )
                else
                  _artPlaceholder(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        songTitle,
                        style: TextStyle(
                            color: AuraTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                            color: AuraTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${timestamps.length} moment${timestamps.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: const Color(0xFF1E1E30), height: 1),

          // Timestamps list
          ...timestamps.map((ts) => _TimestampRow(
                ts: ts,
                onDelete: () =>
                    SongTimestampService().deleteTimestamp(ts.id),
              )),
        ],
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.music_note_rounded,
            color: AuraTheme.accent, size: 24),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Timestamp Row
// ─────────────────────────────────────────────────────────────────────────────
class _TimestampRow extends StatelessWidget {
  final SongTimestamp ts;
  final VoidCallback onDelete;

  const _TimestampRow({
    required this.ts,
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
                color: AuraTheme.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AuraTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_rounded,
                      color: AuraTheme.accent, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    ts.formattedTime,
                    style: TextStyle(
                        color: AuraTheme.accent,
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
                        ? AuraTheme.textMuted
                        : AuraTheme.textPrimary,
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
                color: AuraTheme.textMuted, size: 14),
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

  const _AddTimestampSheet({required this.state});

  @override
  State<_AddTimestampSheet> createState() => _AddTimestampSheetState();
}

class _AddTimestampSheetState extends State<_AddTimestampSheet> {
  final _noteCtrl = TextEditingController();
  final _minuteCtrl = TextEditingController();
  final _secondCtrl = TextEditingController();
  bool _loading = false;
  bool _useNowPlaying = true;

  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.state.vibeSong.isNotEmpty) {
      _titleCtrl.text = widget.state.vibeSong;
      _artistCtrl.text = widget.state.vibeArtist;
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
        ? widget.state.vibeSong
        : _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _loading = true);
    try {
      final ts = SongTimestamp(
        id: '',
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        songTitle: title,
        artist: _useNowPlaying
            ? widget.state.vibeArtist
            : _artistCtrl.text.trim(),
        artUrl: _useNowPlaying ? widget.state.vibeArtUrl : null,
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
    final hasNowPlaying = widget.state.vibeSong.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: AuraTheme.background,
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
                    color: const Color(0xFF1E1E30),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bookmark a Moment',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
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
                        ? AuraTheme.accent.withOpacity(0.12)
                        : AuraTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useNowPlaying
                          ? AuraTheme.accent.withOpacity(0.4)
                          : const Color(0xFF1E1E30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          color: _useNowPlaying
                              ? AuraTheme.accent
                              : AuraTheme.textMuted,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Now Playing',
                              style: TextStyle(
                                  color: AuraTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              widget.state.vibeSong,
                              style: TextStyle(
                                  color: AuraTheme.textPrimary,
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
                            ? AuraTheme.accent
                            : AuraTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (!_useNowPlaying) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: AuraTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Song title',
                    hintStyle: TextStyle(color: AuraTheme.textMuted),
                    filled: true,
                    fillColor: AuraTheme.card,
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
                  style: TextStyle(color: AuraTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Artist',
                    hintStyle: TextStyle(color: AuraTheme.textMuted),
                    filled: true,
                    fillColor: AuraTheme.card,
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
                  color: AuraTheme.textSecondary,
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
                        color: AuraTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '00',
                      hintStyle: TextStyle(
                          color: AuraTheme.textMuted,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: AuraTheme.card,
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
                        color: AuraTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _secondCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: AuraTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '00',
                      hintStyle: TextStyle(
                          color: AuraTheme.textMuted,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                      filled: true,
                      fillColor: AuraTheme.card,
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
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // Note
            Text(
              'Note (optional)',
              style: TextStyle(
                  color: AuraTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 120,
              style: TextStyle(color: AuraTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'This is where the chorus drops...',
                hintStyle: TextStyle(color: AuraTheme.textMuted),
                filled: true,
                fillColor: AuraTheme.card,
                counterStyle:
                    TextStyle(color: AuraTheme.textMuted, fontSize: 11),
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
                  backgroundColor: AuraTheme.accent,
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
