import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../theme/aura_theme.dart';
import 'campfire_screen.dart';

class CollabPlaylistScreen extends StatefulWidget {
  final CampfireGroup group;
  const CollabPlaylistScreen({super.key, required this.group});
  @override
  State<CollabPlaylistScreen> createState() => _CollabPlaylistScreenState();
}

class _CollabPlaylistScreenState extends State<CollabPlaylistScreen> {
  final _player = AudioPlayer();
  int? _playingIdx;
  bool _showSearch = false;
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  final List<Map<String, dynamic>> _songs = [
    {'title': 'Golden Hour', 'artist': 'JVKE', 'by': '@maya.k', 'url': null},
    {'title': 'Espresso', 'artist': 'Sabrina Carpenter', 'by': '@zara.w', 'url': null},
    {'title': 'Die With A Smile', 'artist': 'Lady Gaga & Bruno Mars', 'by': '@you', 'url': null},
    {'title': 'Luther', 'artist': 'Kendrick Lamar & SZA', 'by': '@jay.r', 'url': null},
  ];

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&media=music&limit=8'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _results = (data['results'] as List).map((r) => {
              'title': r['trackName'] ?? '',
              'artist': r['artistName'] ?? '',
              'url': r['previewUrl'],
              'art': r['artworkUrl60'],
            }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _play(int idx, String? url) async {
    if (_playingIdx == idx) {
      await _player.pause();
      setState(() => _playingIdx = null);
      return;
    }
    setState(() => _playingIdx = idx);
    if (url != null) {
      try {
        await _player.setUrl(url);
        await _player.play();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.group.emoji} collab playlist',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
            Text(widget.group.name,
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 11)),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.add_rounded,
                color: AuraTheme.accent),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              _results = [];
              _ctrl.clear();
            }),
          ),
        ],
      ),
      body: Column(children: [
        if (_showSearch) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'search to add a song...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AuraTheme.textMuted),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  AuraTheme.accent)),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (_results.isNotEmpty)
            Container(
              height: 190,
              color: AuraTheme.card,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: r['art'] != null
                          ? Image.network(r['art'] as String,
                              width: 40, height: 40, fit: BoxFit.cover)
                          : Container(
                              width: 40,
                              height: 40,
                              color: AuraTheme.accent.withOpacity(0.15),
                              child: const Icon(Icons.music_note,
                                  color: AuraTheme.accent, size: 16)),
                    ),
                    title: Text(r['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(r['artist'] as String,
                        style:
                            const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: AuraTheme.accent, size: 22),
                      onPressed: () {
                        setState(() {
                          _songs.add({
                            'title': r['title'],
                            'artist': r['artist'],
                            'by': '@you',
                            'url': r['url'],
                          });
                          _showSearch = false;
                          _results = [];
                          _ctrl.clear();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _songs.length,
            itemBuilder: (_, i) {
              final s = _songs[i];
              final playing = _playingIdx == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: playing
                      ? Border.all(
                          color: AuraTheme.accent.withOpacity(0.35))
                      : null,
                ),
                child: Row(children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AuraTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(s['artist'] as String,
                            style: const TextStyle(
                                color: AuraTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('added by ${s['by']}',
                            style: const TextStyle(
                                color: AuraTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _play(i, s['url'] as String?),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: playing
                            ? AuraTheme.accent
                            : AuraTheme.accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        color:
                            playing ? Colors.white : AuraTheme.accent,
                        size: 18,
                      ),
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
