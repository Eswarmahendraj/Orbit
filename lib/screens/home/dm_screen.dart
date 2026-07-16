import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'clip_streaks_screen.dart';
import 'song_clip_screen.dart';

class DMScreen extends StatefulWidget {
  final String username;
  final String displayName;
  final String? songContext;

  const DMScreen({
    super.key,
    required this.username,
    required this.displayName,
    this.songContext,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages = List.from(OrbitState().dmThreads[widget.username] ?? []);

    // Seed with reaction context if first DM
    if (_messages.isEmpty && widget.songContext != null) {
      final msg = {
        'text': '🔥 reacted to "${widget.songContext}"',
        'isMe': true,
        'time': DateTime.now().toIso8601String(),
        'isReaction': true,
      };
      OrbitState().dmThreads[widget.username] = [msg];
      OrbitState().save();
      _messages = [msg];
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final reply = {
          'text': 'omg right?? that song hits different 😭',
          'isMe': false,
          'time': DateTime.now().toIso8601String(),
        };
        OrbitState().dmThreads[widget.username]!.add(reply);
        OrbitState().save();
        setState(() => _messages =
            List.from(OrbitState().dmThreads[widget.username] ?? []));
        _scrollToBottom();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    OrbitState().sendDM(widget.username, text, isMe: true);
    setState(() {
      _messages = List.from(OrbitState().dmThreads[widget.username] ?? []);
      _ctrl.clear();
    });
    _scrollToBottom();
    // Simulate a text reply after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final replies = [
        'lol true 😂',
        'no way!!',
        'ok this is my new fav song',
        'i needed this rn ngl',
        '🔥🔥🔥',
        'sending you one back rn',
        'ok but have you heard the bridge???',
      ];
      final r = replies[math.Random().nextInt(replies.length)];
      OrbitState().dmThreads[widget.username]!
          .add({'text': r, 'isMe': false, 'time': DateTime.now().toIso8601String()});
      OrbitState().save();
      if (mounted) {
        setState(() => _messages =
            List.from(OrbitState().dmThreads[widget.username] ?? []));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _openClip() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SongClipScreen(
          toUsername: widget.username,
          toDisplayName: widget.displayName,
        ),
      ),
    );
    if (sent == true && mounted) {
      setState(() =>
          _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
      _scrollToBottom();

      // Simulate the friend sending a clip back after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        // Pick a demo song for the reply
        const replySongs = [
          ('Espresso', 'Sabrina Carpenter', 8.0, 20.0),
          ('luther', 'Kendrick Lamar & SZA', 45.0 % 30, 57.0 % 30),
          ('APT.', 'ROSE & Bruno Mars', 0.0, 12.0),
          ('Die With A Smile', 'Lady Gaga & Bruno Mars', 5.0, 18.0),
        ];
        final pick = replySongs[math.Random().nextInt(replySongs.length)];
        OrbitState().dmThreads[widget.username]!.add({
          'type': 'clip',
          'song': pick.$1,
          'artist': pick.$2,
          'artUrl': null,
          'previewUrl': null,
          'clipStart': pick.$3,
          'clipEnd': pick.$4,
          'isMe': false,
          'time': DateTime.now().toIso8601String(),
        });
        // Record that they replied to update streak
        OrbitState().recordClipReceived(widget.username);
        OrbitState().save();
        if (mounted) {
          setState(() => _messages =
              List.from(OrbitState().dmThreads[widget.username] ?? []));
          _scrollToBottom();
        }
      });
    }
  }

  void _startCall({required bool video}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.85),
        pageBuilder: (_, __, ___) => _CallScreen(
          displayName: widget.displayName,
          username: widget.username,
          isVideo: video,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Map<String, dynamic>? get _clipStreak =>
      OrbitState().clipStreaks[widget.username];

  int get _streakCount =>
      (_clipStreak?['streakCount'] as int?) ?? 0;

  bool get _sentToday {
    final today = _todayStr();
    return _clipStreak?['lastSentDate'] == today;
  }

  bool get _bothToday {
    final today = _todayStr();
    return _clipStreak?['lastSentDate'] == today &&
        _clipStreak?['lastReceivedDate'] == today;
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AuraTheme.accent.withOpacity(0.15),
            child: Text(
              widget.displayName.isNotEmpty
                  ? widget.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AuraTheme.accent, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.displayName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.username,
                style: const TextStyle(
                    fontSize: 11, color: AuraTheme.textSecondary)),
          ]),
        ]),
        actions: [
          // Voice call
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AuraTheme.accent, size: 22),
            tooltip: 'Voice call',
            onPressed: () => _startCall(video: false),
          ),
          // Video call
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AuraTheme.accent, size: 24),
            tooltip: 'Video call',
            onPressed: () => _startCall(video: true),
          ),
          // Streak history icon
          IconButton(
            icon: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.local_fire_department_outlined,
                  color: AuraTheme.accent, size: 24),
              if (_streakCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                        color: AuraTheme.accent, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_streakCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ]),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClipStreaksScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Streak banner ──
          if (_streakCount > 0 || _sentToday) _streakBanner(),

          // ── Messages ──
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      if (msg['type'] == 'clip') {
                        return _ClipBubble(
                          msg: msg,
                          displayName: widget.displayName,
                        );
                      }
                      return _bubble(msg);
                    },
                  ),
          ),

          _inputBar(),
        ],
      ),
    );
  }

  // ── Streak banner ──────────────────────────────────────────────

  Widget _streakBanner() {
    String label;
    Color bg;
    if (_bothToday) {
      label = '🔥 $_streakCount-day streak · both sent today ✓';
      bg = const Color(0xFF00B894).withOpacity(0.1);
    } else if (_sentToday) {
      label = '🔥 $_streakCount-day streak · waiting for their clip';
      bg = AuraTheme.accent.withOpacity(0.08);
    } else {
      label = '🔥 $_streakCount-day streak · send a clip to keep it going';
      bg = AuraTheme.accent.withOpacity(0.08);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClipStreaksScreen()),
      ),
      child: Container(
        width: double.infinity,
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AuraTheme.accent)),
      ),
    );
  }

  // ── Text message bubble ────────────────────────────────────────

  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    final isReaction = msg['isReaction'] == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AuraTheme.accent : AuraTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : AuraTheme.textPrimary,
            fontSize: isReaction ? 13 : 15,
            fontStyle: isReaction ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Start a convo with ${widget.displayName}',
            style: const TextStyle(
                color: AuraTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openClip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.music_note_rounded,
                  color: AuraTheme.accent, size: 16),
              SizedBox(width: 6),
              Text('send them a clip',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(color: AuraTheme.card),
      child: Row(children: [
        // Clip button
        GestureDetector(
          onTap: _openClip,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.music_note_rounded,
                color: AuraTheme.accent, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Text input
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Message...',
              border: InputBorder.none,
              filled: false,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: AuraTheme.accent, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ── Clip message bubble ────────────────────────────────────────────

class _ClipBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _ClipBubble({required this.msg, required this.displayName});

  @override
  State<_ClipBubble> createState() => _ClipBubbleState();
}

class _ClipBubbleState extends State<_ClipBubble> {
  final _player = AudioPlayer();
  bool _playing = false;
  double _playPos = 0;
  Timer? _stopTimer;
  Timer? _posTimer;
  late List<double> _wave;

  double get _clipStart => (widget.msg['clipStart'] as num?)?.toDouble() ?? 0;
  double get _clipEnd => (widget.msg['clipEnd'] as num?)?.toDouble() ?? 15;
  double get _clipDur => _clipEnd - _clipStart;
  bool get _isMe => widget.msg['isMe'] == true;

  @override
  void initState() {
    super.initState();
    final seed = (widget.msg['song'] ?? '') as String;
    final rng = math.Random(seed.hashCode.abs());
    _wave = List.generate(28, (_) => 3.0 + rng.nextDouble() * 16.0);
    _playPos = _clipStart;
  }

  @override
  void dispose() {
    _player.dispose();
    _stopTimer?.cancel();
    _posTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      _stopTimer?.cancel();
      _posTimer?.cancel();
      setState(() { _playing = false; _playPos = _clipStart; });
      return;
    }

    final url = widget.msg['previewUrl'] as String?;
    if (url == null || url.isEmpty) {
      // No preview URL — just animate visually for 15s
      setState(() { _playing = true; _playPos = _clipStart; });
      _posTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (!mounted) return;
        setState(() {
          _playPos = (_playPos + 0.15).clamp(_clipStart, _clipEnd);
        });
      });
      _stopTimer = Timer(
          Duration(milliseconds: (_clipDur * 1000).round()),
          () {
            _posTimer?.cancel();
            if (mounted) setState(() { _playing = false; _playPos = _clipStart; });
          });
      return;
    }

    setState(() { _playing = true; _playPos = _clipStart; });
    try {
      await _player.setUrl(url);
      await _player.seek(
          Duration(milliseconds: (_clipStart * 1000).round()));
      await _player.play();

      _posTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _playPos = (_player.position.inMilliseconds / 1000.0)
              .clamp(_clipStart, _clipEnd);
        });
      });

      _stopTimer = Timer(
          Duration(milliseconds: (_clipDur * 1000).round()),
          () async {
            await _player.pause();
            _posTimer?.cancel();
            if (mounted) setState(() { _playing = false; _playPos = _clipStart; });
          });
    } catch (_) {
      _posTimer?.cancel();
      if (mounted) setState(() => _playing = false);
    }
  }

  String _fmt(double s) {
    final sec = s.round();
    return '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final artUrl = widget.msg['artUrl'] as String?;
    final song = widget.msg['song'] as String? ?? 'unknown';
    final artist = widget.msg['artist'] as String? ?? '';
    final progFrac = _playing
        ? ((_playPos - _clipStart) / _clipDur).clamp(0.0, 1.0)
        : 0.0;

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: 230,
        decoration: BoxDecoration(
          color: _isMe
              ? AuraTheme.accent.withOpacity(0.08)
              : AuraTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_isMe ? 16 : 4),
            bottomRight: Radius.circular(_isMe ? 4 : 16),
          ),
          border: Border.all(
              color: AuraTheme.accent.withOpacity(0.25), width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Song info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: artUrl != null && artUrl.isNotEmpty
                    ? Image.network(artUrl,
                        width: 36, height: 36, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artPlaceholder())
                    : _artPlaceholder(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(song,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(artist,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),

          // ── Waveform ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _wave.asMap().entries.map((e) {
                  final barT =
                      e.key / _wave.length * _clipDur + _clipStart;
                  final played = barT <= _playPos && _playing;
                  return Expanded(
                    child: Container(
                      height: e.value,
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        color: played
                            ? AuraTheme.accent
                            : AuraTheme.accentLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Controls ──
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(children: [
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                      color: AuraTheme.accent, shape: BoxShape.circle),
                  child: Icon(
                    _playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progFrac,
                      backgroundColor:
                          AuraTheme.accentLight.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AuraTheme.accent),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(_clipStart)} – ${_fmt(_clipEnd)}  ·  ${_clipDur.round()}s clip',
                    style: const TextStyle(
                        fontSize: 9, color: AuraTheme.textMuted),
                  ),
                ]),
              ),
            ]),
          ),

          // ── From label ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14)),
            ),
            child: Text(
              _isMe ? 'you dropped this' : '${widget.displayName} dropped this',
              style: const TextStyle(
                  fontSize: 9,
                  color: AuraTheme.textMuted,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7)),
      child: const Icon(Icons.music_note_rounded,
          color: AuraTheme.accent, size: 18),
    );
  }
}

// ── Call Screen ────────────────────────────────────────────────────────────────

enum _CallState { connecting, ringing, connected }

class _CallScreen extends StatefulWidget {
  final String displayName;
  final String username;
  final bool isVideo;

  const _CallScreen({
    required this.displayName,
    required this.username,
    required this.isVideo,
  });

  @override
  State<_CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<_CallScreen>
    with SingleTickerProviderStateMixin {
  _CallState _state = _CallState.connecting;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOff = false;
  int _seconds = 0;
  Timer? _connectTimer;
  Timer? _durationTimer;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Connecting → Ringing after 1.2s → Connected after 3s
    _connectTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _state = _CallState.ringing);
      _connectTimer = Timer(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        setState(() => _state = _CallState.connected);
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _seconds++);
        });
      });
    });
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _durationTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (_state) {
      case _CallState.connecting:
        return 'Connecting...';
      case _CallState.ringing:
        return 'Ringing...';
      case _CallState.connected:
        final m = _seconds ~/ 60;
        final s = (_seconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
    }
  }

  void _endCall() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final initial = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const Spacer(flex: 1),

            // ── Call type label ──
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isVideo ? 'Video call' : 'Voice call',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ]),

            const SizedBox(height: 32),

            // ── Avatar with pulse ──
            AnimatedBuilder(
              animation: _state == _CallState.connected ? _pulseCtrl : _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: _state == _CallState.ringing ? _pulse.value : 1.0,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraTheme.accent.withOpacity(0.2),
                    border: Border.all(
                        color: AuraTheme.accent.withOpacity(
                            _state == _CallState.ringing ? 0.8 : 0.4),
                        width: 3),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Name ──
            Text(widget.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.username,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 12),

            // ── Status / timer ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusLabel,
                key: ValueKey(_statusLabel),
                style: TextStyle(
                    color: _state == _CallState.connected
                        ? const Color(0xFF00B894)
                        : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),

            const Spacer(flex: 2),

            // ── Control buttons ──
            if (_state == _CallState.connected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                  _controlBtn(
                    icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _muted ? 'Unmute' : 'Mute',
                    active: _muted,
                    onTap: () => setState(() => _muted = !_muted),
                  ),
                  _controlBtn(
                    icon: _speakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: _speakerOn ? 'Speaker' : 'Earpiece',
                    active: _speakerOn,
                    onTap: () => setState(() => _speakerOn = !_speakerOn),
                  ),
                  if (widget.isVideo)
                    _controlBtn(
                      icon: _cameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: _cameraOff ? 'Camera off' : 'Camera on',
                      active: !_cameraOff,
                      onTap: () => setState(() => _cameraOff = !_cameraOff),
                    ),
                ]),
              ),
              const SizedBox(height: 32),
            ],

            // ── End call button ──
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: Color(0xFFE74C3C), shape: BoxShape.circle),
                child: const Icon(Icons.call_end_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            const Text('End call',
                style: TextStyle(color: Colors.white54, fontSize: 12)),

            const Spacer(flex: 1),
          ]),
        ),
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: active ? Colors.white : Colors.white38, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}
