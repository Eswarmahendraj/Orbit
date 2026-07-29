import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../theme/aura_theme.dart';
import '../../services/ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Voice → Playlist screen
// Hold the mic button to speak. Release to get your AI playlist.
// ─────────────────────────────────────────────────────────────────────────────

enum _VoiceState { idle, listening, thinking, result, error }

class VoicePlaylistScreen extends StatefulWidget {
  const VoicePlaylistScreen({super.key});

  @override
  State<VoicePlaylistScreen> createState() => _VoicePlaylistScreenState();
}

class _VoicePlaylistScreenState extends State<VoicePlaylistScreen>
    with TickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;

  _VoiceState _state = _VoiceState.idle;
  String _transcribed = '';
  PlaylistResult? _result;

  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _revealCtrl;

  // Fallback text input for when mic isn't available
  final _textCtrl = TextEditingController();
  bool _showTextFallback = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => setState(() {
        _state = _VoiceState.idle;
        _showTextFallback = true;
      }),
    );
    setState(() {});
    if (!_sttAvailable) setState(() => _showTextFallback = true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _revealCtrl.dispose();
    _textCtrl.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) return;
    HapticFeedback.mediumImpact();
    setState(() { _state = _VoiceState.listening; _transcribed = ''; });
    await _stt.listen(
      onResult: (r) => setState(() => _transcribed = r.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    final text = _transcribed.trim();
    if (text.isEmpty) {
      setState(() => _state = _VoiceState.idle);
      return;
    }
    _sendToAI(text);
  }

  Future<void> _sendToAI(String text) async {
    HapticFeedback.heavyImpact();
    setState(() { _state = _VoiceState.thinking; _transcribed = text; });

    try {
      final result = await AiService.instance.voiceToPlaylist(text);
      if (mounted) {
        setState(() { _result = result; _state = _VoiceState.result; });
        _revealCtrl.forward(from: 0);
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      if (mounted) setState(() => _state = _VoiceState.error);
    }
  }

  void _reset() {
    setState(() {
      _state = _VoiceState.idle;
      _transcribed = '';
      _result = null;
      _textCtrl.clear();
    });
    _revealCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(fit: StackFit.expand, children: [
        // Animated background
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) {
            final t = _bgCtrl.value;
            return CustomPaint(painter: _VoiceBgPainter(t, _state));
          },
        ),

        SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AuraTheme.purple, AuraTheme.cyan],
                  ).createShader(b),
                  child: const Text('voice 🎙️',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: switch (_state) {
                  _VoiceState.idle      => _IdleView(
                      sttAvailable: _sttAvailable,
                      showTextFallback: _showTextFallback,
                      textCtrl: _textCtrl,
                      pulseCtrl: _pulseCtrl,
                      onStartListening: _startListening,
                      onToggleFallback: () =>
                          setState(() => _showTextFallback = !_showTextFallback),
                      onSubmitText: () {
                        final t = _textCtrl.text.trim();
                        if (t.isNotEmpty) _sendToAI(t);
                      },
                    ),
                  _VoiceState.listening => _ListeningView(
                      transcribed: _transcribed,
                      pulseCtrl: _pulseCtrl,
                      onStop: _stopListening,
                    ),
                  _VoiceState.thinking  => _ThinkingView(pulseCtrl: _pulseCtrl,
                      transcribed: _transcribed),
                  _VoiceState.result    => _ResultView(
                      result: _result!,
                      transcribed: _transcribed,
                      revealCtrl: _revealCtrl,
                      pulseCtrl: _pulseCtrl,
                      onReset: _reset,
                    ),
                  _VoiceState.error     => _ErrorView(onReset: _reset),
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle view — hold to speak + text fallback
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final bool sttAvailable;
  final bool showTextFallback;
  final TextEditingController textCtrl;
  final AnimationController pulseCtrl;
  final VoidCallback onStartListening;
  final VoidCallback onToggleFallback;
  final VoidCallback onSubmitText;

  const _IdleView({
    required this.sttAvailable, required this.showTextFallback,
    required this.textCtrl, required this.pulseCtrl,
    required this.onStartListening, required this.onToggleFallback,
    required this.onSubmitText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Subtitle
          Text('tell me how you feel',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 14)),
          const SizedBox(height: 6),
          const Text('I\'ll build a playlist for it',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: 48),

          // Mic button (hold to speak)
          if (sttAvailable && !showTextFallback)
            GestureDetector(
              onLongPressStart: (_) => onStartListening(),
              onLongPressEnd: (_) {},
              child: AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AuraTheme.purple, AuraTheme.cyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                      color: AuraTheme.purple.withOpacity(
                          0.3 + pulseCtrl.value * 0.2),
                      blurRadius: 30 + pulseCtrl.value * 20,
                      spreadRadius: 4,
                    )],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.white, size: 40),
                      SizedBox(height: 4),
                      Text('hold', style: TextStyle(
                          color: Colors.white70, fontSize: 11,
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // Text input fallback
          if (showTextFallback || !sttAvailable) ...[
            TextField(
              controller: textCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g. "I just got off a long drive and feel like I could do anything"',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AuraTheme.purple, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onSubmitText,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AuraTheme.purple, AuraTheme.cyan]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: AuraTheme.purple.withOpacity(0.4),
                      blurRadius: 16)],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎵', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('Build my playlist',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Toggle between mic and text
          if (sttAvailable)
            GestureDetector(
              onTap: onToggleFallback,
              child: Text(
                showTextFallback ? '🎙️ Use voice instead' : '⌨️ Type instead',
                style: TextStyle(
                    color: AuraTheme.cyan.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listening view
// ─────────────────────────────────────────────────────────────────────────────

class _ListeningView extends StatelessWidget {
  final String transcribed;
  final AnimationController pulseCtrl;
  final VoidCallback onStop;
  const _ListeningView({required this.transcribed, required this.pulseCtrl, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing mic
          GestureDetector(
            onTap: onStop,
            child: AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, __) => Stack(alignment: Alignment.center, children: [
                Container(
                  width: 140 + pulseCtrl.value * 20,
                  height: 140 + pulseCtrl.value * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3 + pulseCtrl.value * 0.3),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 110, height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_rounded, color: Colors.white, size: 36),
                      SizedBox(height: 2),
                      Text('tap to stop', style: TextStyle(
                          color: Colors.white70, fontSize: 10,
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 32),
          // Live transcription
          if (transcribed.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                transcribed,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, height: 1.5),
              ),
            )
          else
            Text('listening…',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 15)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thinking view
// ─────────────────────────────────────────────────────────────────────────────

class _ThinkingView extends StatelessWidget {
  final AnimationController pulseCtrl;
  final String transcribed;
  const _ThinkingView({required this.pulseCtrl, required this.transcribed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) => Container(
              width: 90 + pulseCtrl.value * 15,
              height: 90 + pulseCtrl.value * 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AuraTheme.purple.withOpacity(0.6 + pulseCtrl.value * 0.2),
                  AuraTheme.cyan.withOpacity(0.4),
                ]),
              ),
              child: const Center(
                child: Text('🎵', style: TextStyle(fontSize: 38)),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AuraTheme.purple, AuraTheme.cyan],
            ).createShader(b),
            child: const Text('building your playlist…',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
          ),
          const SizedBox(height: 12),
          if (transcribed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('"$transcribed"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final PlaylistResult result;
  final String transcribed;
  final AnimationController revealCtrl;
  final AnimationController pulseCtrl;
  final VoidCallback onReset;

  const _ResultView({
    required this.result, required this.transcribed,
    required this.revealCtrl, required this.pulseCtrl,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    return AnimatedBuilder(
      animation: revealCtrl,
      builder: (_, child) => Opacity(
        opacity: revealCtrl.value,
        child: Transform.translate(
          offset: Offset(0, (1 - revealCtrl.value) * 30),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Mood label
          Center(
            child: Column(children: [
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Text(r.emoji,
                    style: TextStyle(
                        fontSize: 60 + pulseCtrl.value * 8)),
              ),
              const SizedBox(height: 12),
              Text('you\'re giving',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 13)),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AuraTheme.purple, AuraTheme.cyan],
                ).createShader(b),
                child: Text(r.moodLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.2)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(r.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Playlist header
          Row(children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AuraTheme.purple, AuraTheme.cyan],
              ).createShader(b),
              child: Text(r.playlistName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
            const Spacer(),
            Text('${r.tracks.length} tracks',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(r.vibeSummary,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 14),

          // Tracks
          ...r.tracks.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraTheme.purple.withOpacity(0.2),
                ),
                child: Center(
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: AuraTheme.purple,
                            fontWeight: FontWeight.w800,
                            fontSize: 11))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              const Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white24, size: 20),
            ]),
          )),

          const SizedBox(height: 20),

          // New vibe button
          GestureDetector(
            onTap: onReset,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraTheme.purple.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎙️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('new vibe',
                      style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onReset;
  const _ErrorView({required this.onReset});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😵', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      const Text('something went wrong',
          style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      Text('check your API key or connection',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      const SizedBox(height: 24),
      TextButton(
        onPressed: onReset,
        child: const Text('try again',
            style: TextStyle(color: AuraTheme.purple, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Background painter
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceBgPainter extends CustomPainter {
  final double t;
  final _VoiceState state;
  _VoiceBgPainter(this.t, this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blob 1
    final c1 = state == _VoiceState.listening
        ? Colors.redAccent.withOpacity(0.08)
        : AuraTheme.purple.withOpacity(0.08);
    paint.color = c1;
    canvas.drawCircle(
      Offset(size.width * 0.2 + math.sin(t * math.pi * 2) * 30,
          size.height * 0.3 + math.cos(t * math.pi * 2) * 20),
      180, paint,
    );

    // Blob 2
    paint.color = AuraTheme.cyan.withOpacity(0.06);
    canvas.drawCircle(
      Offset(size.width * 0.8 + math.cos(t * math.pi * 2) * 20,
          size.height * 0.7 + math.sin(t * math.pi * 2) * 30),
      150, paint,
    );
  }

  @override
  bool shouldRepaint(_VoiceBgPainter old) => true;
}
