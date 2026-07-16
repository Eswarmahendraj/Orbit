import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../../theme/aura_theme.dart';

// ── Song Search Result ─────────────────────────────────────────────────────────
class SongSearchResult {
  final String trackName;
  final String artistName;
  final String artworkUrl;
  final String? previewUrl;

  const SongSearchResult({
    required this.trackName,
    required this.artistName,
    required this.artworkUrl,
    this.previewUrl,
  });

  factory SongSearchResult.fromJson(Map<String, dynamic> j) {
    final raw = (j['artworkUrl100'] as String? ?? '');
    return SongSearchResult(
      trackName: j['trackName'] ?? 'Unknown Track',
      artistName: j['artistName'] ?? 'Unknown Artist',
      artworkUrl: raw.replaceAll('100x100', '300x300'),
      previewUrl: j['previewUrl'] as String?,
    );
  }
}

// ── Song Search Screen ─────────────────────────────────────────────────────────
class SongSearchScreen extends StatefulWidget {
  const SongSearchScreen({super.key});

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  final _ctrl = TextEditingController();
  final _player = AudioPlayer();
  final _focusNode = FocusNode();

  List<SongSearchResult> _results = [];
  bool _loading = false;
  String? _playingUrl;
  bool _isPlaying = false;
  String? _errorMsg;
  Timer? _debounce;

  // Suggested search chips shown before search
  static const _suggestions = [
    'Pop hits 2024', 'Drake', 'Taylor Swift', 'Lo-fi beats',
    'Hip hop', 'Billie Eilish', 'The Weeknd', 'Trending',
  ];

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (mounted) {
        setState(() => _isPlaying = s.playing);
        // Auto-clear playing state when track finishes
        if (s.processingState == ProcessingState.completed) {
          setState(() { _playingUrl = null; _isPlaying = false; });
        }
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _player.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() {}); // update clear button
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _errorMsg = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _results = []; _errorMsg = null; });
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=25',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['results'] as List)
            .map((e) => SongSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() { _results = list; _loading = false; });
      } else {
        setState(() { _loading = false; _errorMsg = 'Search failed. Try again.'; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorMsg = 'No connection. Check internet.'; });
    }
  }

  Future<void> _togglePreview(SongSearchResult song) async {
    if (song.previewUrl == null) return;
    if (_playingUrl == song.previewUrl) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } else {
      setState(() => _playingUrl = song.previewUrl);
      try {
        await _player.setUrl(song.previewUrl!);
        await _player.play();
      } catch (_) {
        setState(() => _playingUrl = null);
      }
    }
    if (mounted) setState(() {});
  }

  void _select(SongSearchResult song) {
    _player.stop();
    Navigator.pop(context, song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () { _player.stop(); Navigator.pop(context); },
        ),
        title: ShaderMask(
          shaderCallback: (b) => AuraColors.brandGradient.createShader(b),
          child: const Text(
            'Find Your Song',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AuraColors.accent.withOpacity(0.12),
                    AuraColors.pink.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AuraColors.accent.withOpacity(0.35)),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                autofocus: true,
                style: const TextStyle(color: AuraColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Song name, artist, or vibe...',
                  hintStyle: const TextStyle(color: AuraColors.textSecondary, fontSize: 14),
                  prefixIcon: ShaderMask(
                    shaderCallback: (b) => AuraColors.brandGradient.createShader(b),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                  ),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AuraColors.textSecondary, size: 18),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() { _results = []; _errorMsg = null; });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
                onChanged: _onChanged,
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const _LoadingView()
                : _errorMsg != null
                    ? _ErrorView(msg: _errorMsg!)
                    : _results.isEmpty
                        ? _EmptyView(
                            hasQuery: _ctrl.text.isNotEmpty,
                            suggestions: _suggestions,
                            onSuggest: (s) {
                              _ctrl.text = s;
                              setState(() {});
                              _search(s);
                            },
                          )
                        : _ResultsList(
                            results: _results,
                            playingUrl: _playingUrl,
                            isPlaying: _isPlaying,
                            onPreview: _togglePreview,
                            onSelect: _select,
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AuraColors.accent),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Searching...', style: TextStyle(color: AuraColors.textSecondary, fontSize: 14)),
      ],
    ),
  );
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String msg;
  const _ErrorView({required this.msg});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(msg, style: const TextStyle(color: AuraColors.textSecondary, fontSize: 14)),
      ],
    ),
  );
}

// ── Empty View (with suggestion chips) ───────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final bool hasQuery;
  final List<String> suggestions;
  final ValueChanged<String> onSuggest;
  const _EmptyView({required this.hasQuery, required this.suggestions, required this.onSuggest});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (b) => AuraColors.brandGradient.createShader(b),
            child: const Text('🎵', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No results found' : 'Find the perfect song',
            style: const TextStyle(
              color: AuraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery ? 'Try a different search' : 'Powered by iTunes — 30-sec previews included',
            style: const TextStyle(color: AuraColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try these',
                style: TextStyle(
                  color: AuraColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) => GestureDetector(
                onTap: () => onSuggest(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AuraColors.accent.withOpacity(0.15), AuraColors.pink.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AuraColors.accent.withOpacity(0.3)),
                  ),
                  child: Text(s, style: const TextStyle(color: AuraColors.textPrimary, fontSize: 13)),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    ),
  );
}

// ── Results List ──────────────────────────────────────────────────────────────
class _ResultsList extends StatelessWidget {
  final List<SongSearchResult> results;
  final String? playingUrl;
  final bool isPlaying;
  final ValueChanged<SongSearchResult> onPreview;
  final ValueChanged<SongSearchResult> onSelect;

  const _ResultsList({
    required this.results,
    required this.playingUrl,
    required this.isPlaying,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
    itemCount: results.length,
    itemBuilder: (_, i) {
      final song = results[i];
      final isThisPlaying = playingUrl == song.previewUrl && isPlaying;
      final isSelected = playingUrl == song.previewUrl;
      return _SongTile(
        song: song,
        isPlaying: isThisPlaying,
        isSelected: isSelected,
        onPreview: () => onPreview(song),
        onSelect: () => onSelect(song),
        delay: i * 35,
      );
    },
  );
}

// ── Song Tile ─────────────────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  final SongSearchResult song;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onPreview;
  final VoidCallback onSelect;
  final int delay;

  const _SongTile({
    required this.song,
    required this.isPlaying,
    required this.isSelected,
    required this.onPreview,
    required this.onSelect,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AuraColors.accent.withOpacity(0.22), AuraColors.pink.withOpacity(0.12), AuraColors.card],
                )
              : null,
          color: isSelected ? null : AuraColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AuraColors.accent.withOpacity(0.55) : AuraColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AuraColors.accent.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            // Album art
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  song.artworkUrl,
                  width: 56, height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: AuraColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.trackName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AuraColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artistName,
                    style: const TextStyle(color: AuraColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (song.previewUrl != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: AuraColors.accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        const Text('30s preview available',
                            style: TextStyle(color: AuraColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Buttons column
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview button
                if (song.previewUrl != null)
                  GestureDetector(
                    onTap: onPreview,
                    child: Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AuraColors.brandGradient,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey(isPlaying),
                          color: Colors.white, size: 22,
                        ),
                      ),
                    ),
                  ),
                if (song.previewUrl != null) const SizedBox(height: 6),

                // Use button
                GestureDetector(
                  onTap: onSelect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AuraColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Use', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
