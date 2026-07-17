import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ── Seed confessions ─────────────────────────────────────────────

final _seedConfessions = [
  {
    'feeling': 'can\'t stop crying',
    'emoji': '😭',
    'song': 'The Night Will Always Win',
    'artist': 'Manchester Orchestra',
    'timeAgo': '2m ago',
    'hearts': 34,
  },
  {
    'feeling': 'completely lost',
    'emoji': '🌫️',
    'song': 'Numb',
    'artist': 'Linkin Park',
    'timeAgo': '7m ago',
    'hearts': 51,
  },
  {
    'feeling': 'finally okay again',
    'emoji': '🌸',
    'song': 'Ribs',
    'artist': 'Lorde',
    'timeAgo': '14m ago',
    'hearts': 89,
  },
  {
    'feeling': 'falling for someone I shouldn\'t',
    'emoji': '💘',
    'song': 'Lover',
    'artist': 'Taylor Swift',
    'timeAgo': '21m ago',
    'hearts': 142,
  },
  {
    'feeling': 'so overwhelmed',
    'emoji': '💥',
    'song': 'Heavy',
    'artist': 'Benson Boone',
    'timeAgo': '33m ago',
    'hearts': 28,
  },
  {
    'feeling': 'nostalgic for no reason',
    'emoji': '🌙',
    'song': 'Clair de Lune',
    'artist': 'Debussy',
    'timeAgo': '42m ago',
    'hearts': 67,
  },
  {
    'feeling': 'like nobody gets me',
    'emoji': '🫧',
    'song': 'Motion Sickness',
    'artist': 'Phoebe Bridgers',
    'timeAgo': '1h ago',
    'hearts': 93,
  },
  {
    'feeling': 'genuinely happy today',
    'emoji': '✨',
    'song': 'Good 4 U',
    'artist': 'Olivia Rodrigo',
    'timeAgo': '1h ago',
    'hearts': 117,
  },
  {
    'feeling': 'low-key heartbroken',
    'emoji': '💔',
    'song': 'Liability',
    'artist': 'Lorde',
    'timeAgo': '2h ago',
    'hearts': 204,
  },
];

// ── Screen ────────────────────────────────────────────────────────

class ConfessionsScreen extends StatefulWidget {
  const ConfessionsScreen({super.key});

  @override
  State<ConfessionsScreen> createState() => _ConfessionsScreenState();
}

class _ConfessionsScreenState extends State<ConfessionsScreen> {
  // Track which cards have been heart-tapped by the user this session
  final Set<int> _hearted = {};

  List<Map<String, dynamic>> _allConfessions() {
    final user = OrbitState().orbitConfessions
        .map((c) => {...c, '_isOwn': true})
        .toList()
        .reversed
        .toList();
    return [...user, ..._seedConfessions];
  }

  void _heartToggle(int index) {
    setState(() {
      if (_hearted.contains(index)) {
        _hearted.remove(index);
      } else {
        _hearted.add(index);
      }
    });
  }

  void _showPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostConfessionSheet(
        onPosted: (confession) async {
          final state = OrbitState();
          state.orbitConfessions.add(confession);
          await state.save();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _allConfessions();
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('orbit confessions',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Text('your vibe, no name attached',
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostSheet,
        backgroundColor: AuraTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('confess',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: all.length,
        itemBuilder: (context, i) {
          final c = all[i];
          final isHearted = _hearted.contains(i);
          final hearts = (c['hearts'] as int? ?? 0) + (isHearted ? 1 : 0);
          final isOwn = c['_isOwn'] == true;

          return _ConfessionCard(
            feeling: c['feeling'] as String,
            emoji: c['emoji'] as String,
            song: c['song'] as String,
            artist: c['artist'] as String,
            timeAgo: c['timeAgo'] as String,
            hearts: hearts,
            isHearted: isHearted,
            isOwn: isOwn,
            onHeart: () => _heartToggle(i),
          );
        },
      ),
    );
  }
}

// ── Confession Card ───────────────────────────────────────────────

class _ConfessionCard extends StatelessWidget {
  final String feeling, emoji, song, artist, timeAgo;
  final int hearts;
  final bool isHearted;
  final bool isOwn;
  final VoidCallback onHeart;

  const _ConfessionCard({
    required this.feeling,
    required this.emoji,
    required this.song,
    required this.artist,
    required this.timeAgo,
    required this.hearts,
    required this.isHearted,
    required this.isOwn,
    required this.onHeart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: isOwn
            ? Border.all(color: AuraTheme.accent.withOpacity(0.35), width: 1.5)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🫧', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isOwn ? 'you (anonymous)' : 'someone in your orbit',
                style: const TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              Text(timeAgo,
                  style: const TextStyle(
                      color: AuraTheme.textMuted, fontSize: 10)),
            ]),
          ),
          if (isOwn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('you',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),

        // Feeling
        RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AuraTheme.textPrimary,
                fontSize: 15,
                height: 1.4),
            children: [
              TextSpan(
                text: 'is feeling ',
                style: const TextStyle(color: AuraTheme.textSecondary),
              ),
              TextSpan(
                text: '$emoji $feeling',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AuraTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Song
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AuraTheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.music_note_rounded,
                color: AuraTheme.accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(song,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AuraTheme.textPrimary)),
                Text(artist,
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 11)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // Heart
        Row(children: [
          GestureDetector(
            onTap: onHeart,
            child: AnimatedScale(
              scale: isHearted ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isHearted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isHearted ? Colors.pinkAccent : AuraTheme.textMuted,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text('$hearts',
              style: const TextStyle(
                  color: AuraTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ── Post Sheet ────────────────────────────────────────────────────

class _PostConfessionSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onPosted;
  const _PostConfessionSheet({required this.onPosted});

  @override
  State<_PostConfessionSheet> createState() => _PostConfessionSheetState();
}

class _PostConfessionSheetState extends State<_PostConfessionSheet> {
  final _feelingCtrl = TextEditingController();
  String _emoji = '🫧';
  String? _song, _artist;
  bool _searching = false;
  bool _posting = false;
  List<Map<String, dynamic>> _results = [];
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _emojiOptions = [
    '😭', '💔', '🌫️', '🌸', '💘', '💥', '🌙', '🫧', '✨', '😶',
    '💪', '🔥', '😏', '🤪', '👑', '🌿', '😌', '😤', '🥹', '💫',
  ];

  Future<void> _searchSongs(String q) async {
    if (q.length < 2) return;
    setState(() => _searching = true);
    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&entity=song&limit=6');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List).map<Map<String, dynamic>>(
          (r) => {
            'song': r['trackName'] as String,
            'artist': r['artistName'] as String,
          },
        ).toList();
        if (mounted) setState(() => _results = results);
      }
    } catch (_) {}
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _submit() async {
    final feeling = _feelingCtrl.text.trim();
    if (feeling.isEmpty || _song == null) return;
    setState(() => _posting = true);
    await widget.onPosted({
      'feeling': feeling,
      'emoji': _emoji,
      'song': _song!,
      'artist': _artist ?? '',
      'timeAgo': 'just now',
      'hearts': 0,
    });
    if (mounted) {
      setState(() => _posting = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _feelingCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: ListView(
        controller: _scrollCtrl,
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('confess anonymously',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AuraTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('no one will know it\'s you',
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 20),

          // Emoji picker row
          const Text('how does it feel?',
              style: TextStyle(
                  color: AuraTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emojiOptions.length,
              itemBuilder: (_, i) {
                final e = _emojiOptions[i];
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? AuraTheme.accent.withOpacity(0.15)
                          : AuraTheme.surface,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: AuraTheme.accent, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 18)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Feeling text field
          TextField(
            controller: _feelingCtrl,
            style: const TextStyle(color: AuraTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'I\'m feeling...',
              hintStyle:
                  const TextStyle(color: AuraTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: AuraTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Song search
          const Text('what song captures it?',
              style: TextStyle(
                  color: AuraTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 13),
            onChanged: (v) => _searchSongs(v),
            decoration: InputDecoration(
              hintText: 'search songs...',
              hintStyle:
                  const TextStyle(color: AuraTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AuraTheme.textMuted, size: 18),
              filled: true,
              fillColor: AuraTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          if (_searching) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AuraTheme.accent),
              ),
            ),
          ],
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._results.map((r) {
              final selected = _song == r['song'] && _artist == r['artist'];
              return GestureDetector(
                onTap: () => setState(() {
                  _song = r['song'] as String;
                  _artist = r['artist'] as String;
                  _results = [];
                  _searchCtrl.text = '${r['song']} — ${r['artist']}';
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AuraTheme.accent.withOpacity(0.1)
                        : AuraTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: AuraTheme.accent.withOpacity(0.5))
                        : null,
                  ),
                  child: Row(children: [
                    const Icon(Icons.music_note,
                        color: AuraTheme.accent, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          '${r['song']}  •  ${r['artist']}',
                          style: const TextStyle(
                              color: AuraTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AuraTheme.accent, size: 16),
                  ]),
                ),
              );
            }),
          ],
          if (_song != null && _results.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AuraTheme.accent.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    color: AuraTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_song  •  $_artist',
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_feelingCtrl.text.trim().isNotEmpty && _song != null && !_posting)
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                disabledBackgroundColor: AuraTheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _posting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('post anonymously',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
