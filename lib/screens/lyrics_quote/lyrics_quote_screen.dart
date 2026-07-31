import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/audio_player_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lyrics Quote Card Screen
// ─────────────────────────────────────────────────────────────────────────────
class LyricsQuoteScreen extends StatefulWidget {
  const LyricsQuoteScreen({super.key});

  @override
  State<LyricsQuoteScreen> createState() => _LyricsQuoteScreenState();
}

class _LyricsQuoteScreenState extends State<LyricsQuoteScreen> {
  final _lyricsCtrl = TextEditingController();
  final _cardKey = GlobalKey();
  int _selectedStyle = 0;

  static const List<List<Color>> _gradients = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
    [Color(0xFF2d1b69), Color(0xFF11998e)],
    [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
  ];

  static const List<String> _styleLabels = ['Night', 'Teal', 'Cosmos'];

  @override
  void dispose() {
    _lyricsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;
    final state = Provider.of<OrbitState>(context);
    final player = AudioPlayerService();
    final hasLyric = _lyricsCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Lyrics Quote Card',
          style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          if (hasLyric)
            TextButton(
              onPressed: _shareCard,
              child: Text(
                'Share',
                style: TextStyle(
                    color: theme.accent, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Preview ───────────────────────────────────────────────
            RepaintBoundary(
              key: _cardKey,
              child: _QuoteCard(
                lyric: hasLyric
                    ? _lyricsCtrl.text.trim()
                    : 'Enter a lyric below...',
                songTitle: player.currentTitle.isNotEmpty
                    ? player.currentTitle
                    : 'Song Title',
                artist: player.currentArtist.isNotEmpty
                    ? player.currentArtist
                    : 'Artist',
                artUrl: player.currentArtUrl,
                gradient: _gradients[_selectedStyle],
                displayName: state.displayName,
              ),
            ),
            const SizedBox(height: 20),

            // ── Style Selector ─────────────────────────────────────────────
            Text(
              'Card Style',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(3, (i) {
                final selected = _selectedStyle == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStyle = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 44,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _gradients[i]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _gradients[i].last.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _styleLabels[i],
                      style: TextStyle(
                          color:
                              Colors.white.withOpacity(selected ? 1.0 : 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ── Now Playing Banner ─────────────────────────────────────────
            if (player.currentTitle.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  // Pre-fill with song info placeholder
                  if (_lyricsCtrl.text.isEmpty) {
                    setState(() {
                      _lyricsCtrl.text =
                          '${player.currentTitle} — tap to type your lyric';
                      _lyricsCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _lyricsCtrl.text.length,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.graphic_eq_rounded,
                            color: theme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 2),
                            Text(
                              player.currentTitle,
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              player.currentArtist,
                              style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: theme.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Lyric Input ────────────────────────────────────────────────
            Text(
              'Lyric',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lyricsCtrl,
              maxLines: 5,
              maxLength: 200,
              style: TextStyle(
                  color: theme.textPrimary, fontSize: 15, height: 1.5),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Paste a lyric that hits different...',
                hintStyle: TextStyle(color: theme.textMuted),
                filled: true,
                fillColor: theme.cardBackground,
                counterStyle:
                    TextStyle(color: theme.textMuted, fontSize: 11),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Share Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasLyric ? _shareCard : null,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text(
                  'Share Quote Card',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      theme.cardBackground,
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

  Future<void> _shareCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      await image.toByteData(format: ui.ImageByteFormat.png);
      // Card captured — share_plus would handle the file here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('🎵  Card ready! '),
                Text('Tap to share.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AuraTheme.current.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture card')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quote Card (also used as preview and capture target)
// ─────────────────────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final String lyric;
  final String songTitle;
  final String artist;
  final String? artUrl;
  final List<Color> gradient;
  final String displayName;

  const _QuoteCard({
    required this.lyric,
    required this.songTitle,
    required this.artist,
    this.artUrl,
    required this.gradient,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Blurred album art background
            if (artUrl != null)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      artUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                    BackdropFilter(
                      filter:
                          ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient
                                .map((c) => c.withOpacity(0.78))
                                .toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opening quote
                  Text(
                    '“',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 90,
                      height: 0.65,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  // Lyric
                  Expanded(
                    child: Center(
                      child: Text(
                        lyric,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Bottom row
                  Row(
                    children: [
                      // Album art thumbnail
                      if (artUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            artUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _artFallback(),
                          ),
                        )
                      else
                        _artFallback(),
                      const SizedBox(width: 12),

                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              songTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              artist,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Orbit watermark
                      Text(
                        'orbit',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artFallback() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white, size: 22),
      );
}
