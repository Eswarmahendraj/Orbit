import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/aura_theme.dart';
import '../../services/ai_service.dart';

// ── Trending sounds available in Meme Studio ─────────────────────────────────
class _Sound {
  final String song;
  final String artist;
  final Color color;
  final String emoji;
  final int drops;
  const _Sound(this.song, this.artist, this.color, this.emoji, this.drops);
}

const _sounds = [
  _Sound('Espresso',         'Sabrina Carpenter', Color(0xFFFF6B35), '☕', 8421),
  _Sound('luther',           'Kendrick & SZA',    Color(0xFF7C83FD), '💜', 6203),
  _Sound('APT.',             'ROSÉ & Bruno Mars', Color(0xFFFC466B), '🪷', 5891),
  _Sound('Golden Hour',      'JVKE',              Color(0xFFF7971E), '🌅', 4320),
  _Sound('Die With A Smile', 'Lady Gaga',         Color(0xFFE96C9D), '😭', 3874),
  _Sound('Blinding Lights',  'The Weeknd',        Color(0xFFFF0080), '⚡', 3102),
  _Sound('good 4 u',         'Olivia Rodrigo',    Color(0xFF43E97B), '🔪', 2944),
  _Sound('As It Was',        'Harry Styles',      Color(0xFF4FACFE), '🌊', 2711),
];

// ── Meme text style presets ───────────────────────────────────────────────────
const _textStyles = [
  ('Impact', 'CLASSIC'),
  ('Bold', 'MODERN'),
  ('Italic', 'CURSED'),
  ('Mono', 'GLITCH'),
];

// ── Background color options (used when no image picked) ─────────────────────
const _bgColors = [
  [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
  [Color(0xFF1A0A2E), Color(0xFF2E1065)],
  [Color(0xFF0A1A0D), Color(0xFF0D3B1A)],
  [Color(0xFF1A0A0A), Color(0xFF3B0D0D)],
  [Color(0xFF000000), Color(0xFF1A1A1A)],
  [Color(0xFF0D1A2E), Color(0xFF0F3460)],
];

// ─────────────────────────────────────────────────────────────────────────────
// MemeStudioScreen
// ─────────────────────────────────────────────────────────────────────────────

class MemeStudioScreen extends StatefulWidget {
  final String? preSelectedSong;
  final String? preSelectedArtist;
  final Color? preSelectedColor;

  const MemeStudioScreen({
    super.key,
    this.preSelectedSong,
    this.preSelectedArtist,
    this.preSelectedColor,
  });

  @override
  State<MemeStudioScreen> createState() => _MemeStudioScreenState();
}

class _MemeStudioScreenState extends State<MemeStudioScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0=sound, 1=background, 2=text, 3=preview

  // Selections
  _Sound? _sound;
  int _bgIndex = 0;
  int _styleIndex = 0;
  final _topCtrl = TextEditingController();
  final _botCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  late final AnimationController _glowCtrl;
  bool _aiSuggesting = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    // Pre-fill if launched from Trending Sounds
    if (widget.preSelectedSong != null) {
      try {
        _sound = _sounds.firstWhere(
            (s) => s.song == widget.preSelectedSong);
      } catch (_) {}
      if (_sound != null) _step = 1;
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _topCtrl.dispose();
    _botCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Color get _accent => _sound?.color ?? AuraTheme.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        foregroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [_accent, Colors.white],
          ).createShader(b),
          child: const Text('🎭 Meme Studio',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepBar(current: _step, accent: _accent),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: switch (_step) {
            0 => _SoundPicker(
                sounds: _sounds,
                selected: _sound,
                onPick: (s) => setState(() { _sound = s; _step = 1; }),
              ),
            1 => _BgPicker(
                colors: _bgColors,
                selected: _bgIndex,
                accent: _accent,
                onPick: (i) => setState(() { _bgIndex = i; _step = 2; }),
                onBack: () => setState(() => _step = 0),
              ),
            2 => _TextEditor(
                topCtrl: _topCtrl,
                botCtrl: _botCtrl,
                captionCtrl: _captionCtrl,
                styleIndex: _styleIndex,
                onStyleChange: (i) => setState(() => _styleIndex = i),
                accent: _accent,
                aiSuggesting: _aiSuggesting,
                onAiSuggest: _sound != null ? _aiSuggestText : null,
                onNext: () => setState(() => _step = 3),
                onBack: () => setState(() => _step = 1),
              ),
            _ => _Preview(
                sound: _sound!,
                bgColors: _bgColors[_bgIndex],
                topText: _topCtrl.text,
                botText: _botCtrl.text,
                caption: _captionCtrl.text,
                styleIndex: _styleIndex,
                glowCtrl: _glowCtrl,
                onBack: () => setState(() => _step = 2),
                onPost: _onPost,
              ),
          },
        ),
      ),
    );
  }

  Future<void> _aiSuggestText() async {
    if (_sound == null || _aiSuggesting) return;
    HapticFeedback.selectionClick();
    setState(() => _aiSuggesting = true);
    try {
      final result = await AiService.instance.suggestMemeText(
        song:   _sound!.song,
        artist: _sound!.artist,
      );
      if (mounted) {
        setState(() {
          _topCtrl.text = result.top;
          _botCtrl.text = result.bottom;
          _aiSuggesting = false;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      if (mounted) setState(() => _aiSuggesting = false);
    }
  }

  void _onPost() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🎭', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        const Text('Meme dropped to your orbit!',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
      backgroundColor: _accent.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step bar
// ─────────────────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current;
  final Color accent;
  const _StepBar({required this.current, required this.accent});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sound', 'Background', 'Text', 'Preview'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: done || active
                        ? accent
                        : Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < labels.length - 1) const SizedBox(width: 4),
            ]),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Sound picker
// ─────────────────────────────────────────────────────────────────────────────

class _SoundPicker extends StatelessWidget {
  final List<_Sound> sounds;
  final _Sound? selected;
  final ValueChanged<_Sound> onPick;
  const _SoundPicker({required this.sounds, required this.selected, required this.onPick});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pick a sound 🎵',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          Text('What\'s the vibe of your meme?',
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sounds.length,
          itemBuilder: (_, i) {
            final s = sounds[i];
            final sel = selected == s;
            return GestureDetector(
              onTap: () => onPick(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel
                      ? s.color.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? s.color.withOpacity(0.6) : Colors.white.withOpacity(0.08),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  // Rank
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: s.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  // Color disc
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.color.withOpacity(0.2),
                      border: Border.all(color: s.color.withOpacity(0.5)),
                    ),
                    child: Center(child: Text(s.emoji,
                        style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.song,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(s.artist,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    ],
                  )),
                  // Drop count
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmt(s.drops),
                        style: TextStyle(color: s.color,
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('drops',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 9)),
                  ]),
                  const SizedBox(width: 8),
                  Icon(
                    sel ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    color: sel ? s.color : Colors.white24, size: 20,
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Background picker
// ─────────────────────────────────────────────────────────────────────────────

class _BgPicker extends StatelessWidget {
  final List<List<Color>> colors;
  final int selected;
  final Color accent;
  final ValueChanged<int> onPick;
  final VoidCallback onBack;
  const _BgPicker({required this.colors, required this.selected,
      required this.accent, required this.onPick, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white54, size: 18)),
          const SizedBox(width: 10),
          const Text('Choose background 🎨',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 20)),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text('Pick a dark background for your meme',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: colors.length,
          itemBuilder: (_, i) {
            final sel = selected == i;
            return GestureDetector(
              onTap: () => onPick(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors[i],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? accent : Colors.white.withOpacity(0.1),
                    width: sel ? 2.5 : 1,
                  ),
                  boxShadow: sel ? [BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                  )] : null,
                ),
                child: sel
                    ? Center(child: Icon(
                        Icons.check_circle_rounded,
                        color: accent, size: 32))
                    : null,
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Text editor
// ─────────────────────────────────────────────────────────────────────────────

class _TextEditor extends StatelessWidget {
  final TextEditingController topCtrl;
  final TextEditingController botCtrl;
  final TextEditingController captionCtrl;
  final int styleIndex;
  final ValueChanged<int> onStyleChange;
  final Color accent;
  final bool aiSuggesting;
  final VoidCallback? onAiSuggest;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _TextEditor({
    required this.topCtrl, required this.botCtrl,
    required this.captionCtrl, required this.styleIndex,
    required this.onStyleChange, required this.accent,
    this.aiSuggesting = false, this.onAiSuggest,
    required this.onNext, required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white54, size: 18)),
          const SizedBox(width: 10),
          const Text('Add the text 📝',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 20)),
          const Spacer(),
          // ✨ AI Suggest button
          GestureDetector(
            onTap: aiSuggesting ? null : onAiSuggest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: onAiSuggest != null && !aiSuggesting
                    ? LinearGradient(
                        colors: [accent.withOpacity(0.8), accent.withOpacity(0.4)])
                    : null,
                color: onAiSuggest == null || aiSuggesting
                    ? Colors.white.withOpacity(0.06)
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: onAiSuggest != null && !aiSuggesting
                      ? accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.12),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (aiSuggesting)
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: accent),
                  )
                else
                  const Text('✨', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  aiSuggesting ? 'Writing…' : 'AI Suggest',
                  style: TextStyle(
                    color: onAiSuggest != null && !aiSuggesting
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        if (onAiSuggest == null)
          Text('← pick a sound first to get AI suggestions',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 10)),
        const SizedBox(height: 16),

        // Top text
        _MemeTextField(
          controller: topCtrl,
          label: 'TOP TEXT',
          hint: 'when the drop hits at 3am...',
          accent: accent,
        ),
        const SizedBox(height: 12),

        // Bottom text
        _MemeTextField(
          controller: botCtrl,
          label: 'BOTTOM TEXT',
          hint: 'and you have work in 4 hours',
          accent: accent,
        ),
        const SizedBox(height: 20),

        // Style selector
        Text('Text style',
            style: TextStyle(color: Colors.white.withOpacity(0.45),
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        Row(children: List.generate(_textStyles.length, (i) {
          final sel = styleIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onStyleChange(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i < _textStyles.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(children: [
                  Text(_textStyles[i].$1,
                      style: TextStyle(
                        color: sel ? accent : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: _textStyles[i].$1 == 'Italic'
                            ? FontStyle.italic : FontStyle.normal,
                      )),
                  const SizedBox(height: 2),
                  Text(_textStyles[i].$2,
                      style: TextStyle(
                          color: (sel ? accent : Colors.white38).withOpacity(0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ]),
              ),
            ),
          );
        })),
        const SizedBox(height: 20),

        // Caption
        _MemeTextField(
          controller: captionCtrl,
          label: 'CAPTION (optional)',
          hint: 'add a caption for the orbit...',
          accent: accent,
        ),
        const SizedBox(height: 28),

        // Next
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Preview meme →',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _MemeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color accent;
  const _MemeTextField({required this.controller, required this.label,
      required this.hint, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: accent.withOpacity(0.7), fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withOpacity(0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Preview + Post
// ─────────────────────────────────────────────────────────────────────────────

class _Preview extends StatelessWidget {
  final _Sound sound;
  final List<Color> bgColors;
  final String topText;
  final String botText;
  final String caption;
  final int styleIndex;
  final AnimationController glowCtrl;
  final VoidCallback onBack;
  final VoidCallback onPost;

  const _Preview({
    required this.sound, required this.bgColors,
    required this.topText, required this.botText,
    required this.caption, required this.styleIndex,
    required this.glowCtrl, required this.onBack,
    required this.onPost,
  });

  TextStyle _memeStyle(double size) {
    return TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: FontWeight.w900,
      fontStyle: styleIndex == 2 ? FontStyle.italic : FontStyle.normal,
      letterSpacing: styleIndex == 3 ? 2 : 0.5,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: const Offset(1, 2)),
        Shadow(color: Colors.black87, blurRadius: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white54, size: 18)),
          const SizedBox(width: 10),
          const Text('Your meme 🎭',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 20)),
        ]),
      ),

      // Meme card preview
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedBuilder(
                animation: glowCtrl,
                builder: (_, __) => Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: bgColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Animated glow blob
                    Positioned(
                      top: -40,
                      left: -40,
                      child: Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sound.color.withOpacity(
                              0.12 + glowCtrl.value * 0.06),
                        ),
                      ),
                    ),

                    // Top text
                    if (topText.isNotEmpty)
                      Positioned(
                        top: 20, left: 12, right: 12,
                        child: Text(
                          topText.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: _memeStyle(22),
                        ),
                      ),

                    // Center emoji
                    Center(
                      child: Text(sound.emoji,
                          style: TextStyle(
                              fontSize: 64 + glowCtrl.value * 8)),
                    ),

                    // Bottom text
                    if (botText.isNotEmpty)
                      Positioned(
                        bottom: 60, left: 12, right: 12,
                        child: Text(
                          botText.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: _memeStyle(20),
                        ),
                      ),

                    // Song strip at bottom
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sound.color.withOpacity(0.3),
                              border: Border.all(
                                  color: sound.color.withOpacity(0.6)),
                            ),
                            child: Center(child: Text(sound.emoji,
                                style: const TextStyle(fontSize: 13))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            '${sound.song} · ${sound.artist}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          )),
                          Text('🎭',
                              style: const TextStyle(fontSize: 14)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Caption preview
      if (caption.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(caption,
              style: TextStyle(color: Colors.white.withOpacity(0.6),
                  fontSize: 13),
              textAlign: TextAlign.center),
        ),

      const SizedBox(height: 20),

      // Post button
      Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24,
            MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: onPost,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [sound.color, sound.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: sound.color.withOpacity(0.45),
                  blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎭', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Text('Drop to Orbit',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
