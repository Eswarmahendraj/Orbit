import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';
import '../../services/ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Caption Screen — enter a song, get 3 captions + hashtags
// ─────────────────────────────────────────────────────────────────────────────

class AiCaptionScreen extends StatefulWidget {
  /// Optional pre-filled song/artist (e.g. launched from a specific Drop)
  final String? initialSong;
  final String? initialArtist;

  const AiCaptionScreen({
    super.key,
    this.initialSong,
    this.initialArtist,
  });

  @override
  State<AiCaptionScreen> createState() => _AiCaptionScreenState();
}

class _AiCaptionScreenState extends State<AiCaptionScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _songCtrl;
  late final TextEditingController _artistCtrl;
  late final AnimationController _glowCtrl;

  CaptionResult? _result;
  bool _loading = false;
  String _errorMsg = '';
  int? _copiedIndex;

  @override
  void initState() {
    super.initState();
    _songCtrl   = TextEditingController(text: widget.initialSong ?? '');
    _artistCtrl = TextEditingController(text: widget.initialArtist ?? '');
    _glowCtrl   = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _songCtrl.dispose();
    _artistCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final song   = _songCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    if (song.isEmpty) {
      setState(() => _errorMsg = 'Enter a song name first');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _errorMsg = ''; _result = null; });

    try {
      final result = await AiService.instance.suggestCaption(
        song: song,
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
      );
      if (mounted) {
        setState(() { _result = result; _loading = false; });
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Something went wrong. Check your API key.';
        });
      }
    }
  }

  void _copy(String text, int index) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    setState(() => _copiedIndex = index);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _copiedIndex = null); });
  }

  void _copyHashtags() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!.hashtags.join(' ')));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Hashtags copied!'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AuraTheme.purple, AuraTheme.cyan],
          ).createShader(b),
          child: const Text('✨ AI Caption',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Intro text
          Text('Enter a song and I\'ll write your Drop caption.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 20),

          // Song input
          _Label('SONG'),
          const SizedBox(height: 6),
          _Field(
            controller: _songCtrl,
            hint: 'e.g. Espresso',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Artist input
          _Label('ARTIST (optional)'),
          const SizedBox(height: 6),
          _Field(
            controller: _artistCtrl,
            hint: 'e.g. Sabrina Carpenter',
          ),
          const SizedBox(height: 24),

          // Generate button
          GestureDetector(
            onTap: _loading ? null : _generate,
            child: AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                final canGen = _songCtrl.text.trim().isNotEmpty && !_loading;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: canGen
                        ? const LinearGradient(
                            colors: [AuraTheme.purple, AuraTheme.cyan])
                        : null,
                    color: canGen ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canGen ? [BoxShadow(
                      color: AuraTheme.purple.withOpacity(
                          0.3 + _glowCtrl.value * 0.2),
                      blurRadius: 18,
                    )] : null,
                  ),
                  child: _loading
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text('Writing captions…',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ])
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('✨', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            canGen ? 'Generate captions' : 'Enter a song first',
                            style: TextStyle(
                              color: canGen ? Colors.white : Colors.white30,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ]),
                );
              },
            ),
          ),

          // Error
          if (_errorMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_errorMsg,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],

          // Results
          if (_result != null) ...[
            const SizedBox(height: 28),
            _Label('CAPTIONS — tap to copy'),
            const SizedBox(height: 10),
            ...List.generate(_result!.captions.length, (i) {
              final caption = _result!.captions[i];
              final isCopied = _copiedIndex == i;
              return GestureDetector(
                onTap: () => _copy(caption, i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCopied
                        ? AuraTheme.purple.withOpacity(0.12)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCopied
                          ? AuraTheme.purple.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: isCopied ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Number badge
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraTheme.purple.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  color: AuraTheme.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(caption,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.5)),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isCopied
                            ? Icons.check_circle_rounded
                            : Icons.copy_rounded,
                        color: isCopied ? AuraTheme.purple : Colors.white24,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            Row(children: [
              _Label('HASHTAGS'),
              const Spacer(),
              GestureDetector(
                onTap: _copyHashtags,
                child: Row(children: [
                  const Icon(Icons.copy_rounded, size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text('copy all',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _result!.hashtags.map((h) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: h));
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuraTheme.cyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AuraTheme.cyan.withOpacity(0.25)),
                  ),
                  child: Text(h,
                      style: const TextStyle(
                          color: AuraTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              )).toList(),
            ),

            const SizedBox(height: 24),
            // Regenerate
            GestureDetector(
              onTap: _generate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔄', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('generate again',
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  const _Field({required this.controller, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white),
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AuraTheme.purple, width: 1.5),
      ),
    ),
  );
}
