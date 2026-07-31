// ORBIT_DM_v2 — futuristic direct message thread
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/audio_player_service.dart';
import '../../models/orbit_state.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../theme/aura_theme.dart';
import 'clip_streaks_screen.dart';
import 'song_clip_screen.dart';

class DMScreen extends StatefulWidget {
  final String username;
  final String displayName;
  final String? songContext;
  final String? targetUid;

  const DMScreen({
    super.key,
    required this.username,
    required this.displayName,
    this.songContext,
    this.targetUid,
  });

  @override
  State<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends State<DMScreen> with TickerProviderStateMixin {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _showTyping = false;

  // Emoji reaction overlay state
  String? _reactionTarget;
  OverlayEntry? _reactionOverlay;

  // ── Feature state ─────────────────────────────────────────────────
  bool _vibeCheckAnsweredToday = false;
  bool _listenTogetherActive   = false;
  String? _listenSong, _listenArtist, _listenUrl;
  Timer? _listenTimer;
  int _listenSeconds = 0;

  @override
  void initState() {
    super.initState();
    _messages = List.from(OrbitState().dmThreads[widget.username] ?? []);
    _loadVibeCheckState();

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
      Future.delayed(const Duration(milliseconds: 1500), _autoReply);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _reactionOverlay?.remove();
    _listenTimer?.cancel();
    AudioPlayerService.i.stopIfOwner('listen_together');
    super.dispose();
  }

  bool get _isFirestoreChat => widget.targetUid != null;

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _ctrl.clear();

    if (_isFirestoreChat) {
      ChatService().sendMessage(
        senderId: FirebaseAuth.instance.currentUser?.uid ?? '',
        senderAuraName: OrbitState().displayName,
        receiverId: widget.targetUid!,
        content: text,
      );
      _scrollToBottom();
    } else {
      OrbitState().sendDM(widget.username, text, isMe: true);
      setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
      _scrollToBottom();
      _simulateTypingReply();
    }
  }

  void _simulateTypingReply() {
    setState(() => _showTyping = true);
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showTyping = false);
      final replies = [
        'lol true 😂', 'no way!!', 'ok this is my new fav song',
        'i needed this rn ngl', '🔥🔥🔥', 'sending you one back rn',
        'ok but have you heard the bridge???',
      ];
      final r = replies[math.Random().nextInt(replies.length)];
      OrbitState().dmThreads[widget.username]!
          .add({'text': r, 'isMe': false, 'time': DateTime.now().toIso8601String()});
      OrbitState().save();
      if (mounted) {
        setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
        _scrollToBottom();
      }
    });
  }

  void _autoReply() {
    if (!mounted) return;
    final reply = {
      'text': 'omg right?? that song hits different 😭',
      'isMe': false,
      'time': DateTime.now().toIso8601String(),
    };
    OrbitState().dmThreads[widget.username]!.add(reply);
    OrbitState().save();
    setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
    _scrollToBottom();
  }

  void _sendNudge() {
    HapticFeedback.heavyImpact();
    final nudge = {
      'type': 'nudge',
      'isMe': true,
      'time': DateTime.now().toIso8601String(),
    };
    if (!_isFirestoreChat) {
      OrbitState().dmThreads[widget.username] ??= [];
      OrbitState().dmThreads[widget.username]!.add(nudge);
      OrbitState().save();
      setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
      _scrollToBottom();
      // Echo back after 0.8s
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        OrbitState().dmThreads[widget.username]!.add({
          'type': 'nudge',
          'isMe': false,
          'time': DateTime.now().toIso8601String(),
        });
        OrbitState().save();
        setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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
      setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
      _scrollToBottom();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        const replySongs = [
          ('Espresso', 'Sabrina Carpenter', 8.0, 20.0),
          ('luther', 'Kendrick Lamar & SZA', 15.0, 27.0),
          ('APT.', 'ROSE & Bruno Mars', 0.0, 12.0),
          ('Die With A Smile', 'Lady Gaga & Bruno Mars', 5.0, 18.0),
        ];
        final pick = replySongs[math.Random().nextInt(replySongs.length)];
        OrbitState().dmThreads[widget.username]!.add({
          'type': 'clip',
          'song': pick.$1, 'artist': pick.$2,
          'artUrl': null, 'previewUrl': null,
          'clipStart': pick.$3, 'clipEnd': pick.$4,
          'isMe': false, 'time': DateTime.now().toIso8601String(),
        });
        OrbitState().recordClipReceived(widget.username);
        OrbitState().save();
        if (mounted) {
          setState(() => _messages = List.from(OrbitState().dmThreads[widget.username] ?? []));
          _scrollToBottom();
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE 1 — SONG PASS
  // ═══════════════════════════════════════════════════════════════════

  void _openSongPass() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SongPickerSheet(
        title: 'pass a song',
        subtitle: 'say it with music',
        onPicked: (song, artist, artUrl, previewUrl) {
          Navigator.pop(context);
          _addMessage({
            'type': 'song_pass',
            'song': song, 'artist': artist,
            'artUrl': artUrl, 'previewUrl': previewUrl,
            'isMe': true,
            'time': DateTime.now().toIso8601String(),
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            const replies = [
              ('luther', 'Kendrick Lamar & SZA', null, null),
              ('Golden Hour', 'JVKE', null, null),
              ('APT.', 'ROSÉ & Bruno Mars', null, null),
              ('Die With A Smile', 'Lady Gaga & Bruno Mars', null, null),
            ];
            final r = replies[math.Random().nextInt(replies.length)];
            _addMessage({
              'type': 'song_pass',
              'song': r.$1, 'artist': r.$2,
              'artUrl': r.$3, 'previewUrl': r.$4,
              'isMe': false,
              'time': DateTime.now().toIso8601String(),
            });
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE 2 — VIBE CHECK DM
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _loadVibeCheckState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vibecheck_${widget.username}_${_todayStr()}';
    if (mounted) setState(() => _vibeCheckAnsweredToday = prefs.getBool(key) ?? false);
  }

  void _answerVibeCheck() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SongPickerSheet(
        title: "what's your song right now?",
        subtitle: 'your morning vibe',
        onPicked: (song, artist, artUrl, previewUrl) async {
          Navigator.pop(context);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('vibecheck_${widget.username}_${_todayStr()}', true);
          _addMessage({
            'type': 'vibe_check',
            'song': song, 'artist': artist,
            'artUrl': artUrl, 'previewUrl': previewUrl,
            'isMe': true,
            'time': DateTime.now().toIso8601String(),
          });
          setState(() => _vibeCheckAnsweredToday = true);
          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            const answers = [
              ('Espresso', 'Sabrina Carpenter'),
              ('luther', 'Kendrick Lamar & SZA'),
              ('Flowers', 'Miley Cyrus'),
            ];
            final a = answers[math.Random().nextInt(answers.length)];
            _addMessage({
              'type': 'vibe_check',
              'song': a.$1, 'artist': a.$2,
              'artUrl': null, 'previewUrl': null,
              'isMe': false,
              'time': DateTime.now().toIso8601String(),
            });
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE 3 — LISTEN TOGETHER
  // ═══════════════════════════════════════════════════════════════════

  void _openListenTogether() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SongPickerSheet(
        title: 'listen together',
        subtitle: 'same song, same second',
        onPicked: (song, artist, artUrl, previewUrl) async {
          Navigator.pop(context);
          _addMessage({
            'type': 'listen_together',
            'song': song, 'artist': artist,
            'artUrl': artUrl, 'previewUrl': previewUrl,
            'startedAt': DateTime.now().toIso8601String(),
            'isMe': true,
            'time': DateTime.now().toIso8601String(),
          });
          setState(() {
            _listenTogetherActive = true;
            _listenSong = song; _listenArtist = artist; _listenUrl = previewUrl;
            _listenSeconds = 0;
          });
          if (previewUrl != null) {
            await AudioPlayerService.i.play(previewUrl, owner: 'listen_together', loop: true);
          }
          _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _listenSeconds++);
          });
        },
      ),
    );
  }

  void _endListenTogether() {
    _listenTimer?.cancel();
    AudioPlayerService.i.stopIfOwner('listen_together');
    setState(() { _listenTogetherActive = false; _listenSeconds = 0; });
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE 4 — ROAST MY PLAYLIST
  // ═══════════════════════════════════════════════════════════════════

  void _sendRoastCard() {
    HapticFeedback.mediumImpact();
    final songs = [
      {'song': 'Espresso', 'artist': 'Sabrina Carpenter'},
      {'song': 'luther', 'artist': 'Kendrick Lamar & SZA'},
      {'song': 'APT.', 'artist': 'ROSÉ & Bruno Mars'},
      {'song': 'Die With A Smile', 'artist': 'Lady Gaga & Bruno Mars'},
      {'song': 'Golden Hour', 'artist': 'JVKE'},
    ];
    _addMessage({
      'type': 'roast',
      'songs': songs,
      'isMe': true,
      'time': DateTime.now().toIso8601String(),
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      const roasts = [
        '💀 bro your playlist is literally a 2023 spotify ad. espresso AND golden hour?? at least add one unhinged track',
        '😭 okay we need to talk. this is the most "main character at a coffee shop" playlist i have ever seen in my life',
        '🪦 rest in peace your music taste. I counted 3 songs from movies and 2 from tiktok. you are not okay.',
        '😂 this playlist should come with a warning label. "may cause involuntary dancing and posting instagram stories"',
      ];
      final r = roasts[math.Random().nextInt(roasts.length)];
      _addMessage({
        'text': r, 'isMe': false,
        'time': DateTime.now().toIso8601String(),
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEATURE 5 — MOOD REPLIES (wired into long-press)
  // ═══════════════════════════════════════════════════════════════════

  void _openMoodReply(Map<String, dynamic> originalMsg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SongPickerSheet(
        title: 'reply with a song',
        subtitle: 'say it in music',
        onPicked: (song, artist, artUrl, previewUrl) {
          Navigator.pop(context);
          _addMessage({
            'type': 'mood_reply',
            'song': song, 'artist': artist,
            'artUrl': artUrl, 'previewUrl': previewUrl,
            'replyTo': originalMsg['text'] ?? '${originalMsg['song'] ?? ''} — ${originalMsg['artist'] ?? ''}',
            'isMe': true,
            'time': DateTime.now().toIso8601String(),
          });
        },
      ),
    );
  }

  // ── Shared helper ─────────────────────────────────────────────────
  void _addMessage(Map<String, dynamic> msg) {
    OrbitState().dmThreads[widget.username] ??= [];
    OrbitState().dmThreads[widget.username]!.add(msg);
    OrbitState().save();
    if (mounted) {
      setState(() => _messages = List.from(OrbitState().dmThreads[widget.username]!));
      _scrollToBottom();
    }
  }

  // ── Feature actions sheet ─────────────────────────────────────────
  void _showFeatureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.purple.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          _FeatureRow(icon: Icons.music_note_rounded, color: AuraTheme.accent,
              label: 'song pass', sublabel: 'pass a song, no words needed',
              onTap: () { Navigator.pop(context); _openSongPass(); }),
          _FeatureRow(icon: Icons.wb_sunny_rounded, color: const Color(0xFFFFD700),
              label: 'vibe check DM', sublabel: "what's your song today?",
              onTap: () { Navigator.pop(context); _answerVibeCheck(); }),
          _FeatureRow(icon: Icons.headphones_rounded, color: const Color(0xFF4ECDC4),
              label: 'listen together', sublabel: 'same song, same second',
              onTap: () { Navigator.pop(context); _openListenTogether(); }),
          _FeatureRow(icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF6B35),
              label: 'roast my playlist', sublabel: 'send your 5 songs, get destroyed',
              onTap: () { Navigator.pop(context); _sendRoastCard(); }),
        ]),
      ),
    );
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

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(displayName: widget.displayName, username: widget.username, onNudge: _sendNudge, onCall: () => _startCall(video: false)),
    );
  }

  Map<String, dynamic>? get _clipStreak => OrbitState().clipStreaks[widget.username];
  int get _streakCount => (_clipStreak?['streakCount'] as int?) ?? 0;
  bool get _sentToday => _clipStreak?['lastSentDate'] == _todayStr();
  bool get _bothToday => _sentToday && _clipStreak?['lastReceivedDate'] == _todayStr();
  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: _buildAppBar(),
      body: Column(children: [
        if (_streakCount > 0 || _sentToday) _streakBanner(),
        if (!_vibeCheckAnsweredToday) _vibeCheckPrompt(),
        if (_listenTogetherActive) _listenTogetherBanner(),
        Expanded(child: _buildMessageList()),
        _inputBar(),
      ]),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AuraTheme.background,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _showProfileSheet,
        child: Row(children: [
          // Orbital avatar tap to see profile
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AuraTheme.purple, AuraTheme.cyan],
              ),
            ),
            child: Center(
              child: Text(
                widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              widget.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.username,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AuraTheme.cyan.withOpacity(0.8),
              ),
            ),
          ]),
        ]),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded, size: 20),
          color: AuraTheme.purple,
          onPressed: () => _startCall(video: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 22),
          color: AuraTheme.purple,
          onPressed: () => _startCall(video: true),
        ),
        IconButton(
          icon: Stack(alignment: Alignment.center, children: [
            const Icon(Icons.local_fire_department_outlined, size: 22),
            if (_streakCount > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: const BoxDecoration(color: AuraTheme.accent, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$_streakCount',
                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ]),
          color: AuraTheme.accent,
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ClipStreaksScreen())),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Messages ─────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_isFirestoreChat) {
      return StreamBuilder<List<Message>>(
        stream: ChatService().getMessages(
          FirebaseAuth.instance.currentUser?.uid ?? '',
          widget.targetUid!,
        ),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              color: AuraTheme.purple, strokeWidth: 2));
          }
          final msgs = snap.data ?? [];
          if (msgs.isEmpty) return _emptyState();
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final m = msgs[i];
              final isMe = m.senderId == FirebaseAuth.instance.currentUser?.uid;
              return _bubble({'text': m.content, 'isMe': isMe});
            },
          );
        },
      );
    }

    final items = [..._messages];
    if (items.isEmpty && !_showTyping) return _emptyState();

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: items.length + (_showTyping ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == items.length) return _typingIndicator();
        final msg = items[i];
        switch (msg['type'] as String?) {
          case 'clip':
            return _ClipBubble(msg: msg, displayName: widget.displayName);
          case 'nudge':
            return _nudgeMarker(msg);
          case 'song_pass':
            return _SongPassBubble(msg: msg, displayName: widget.displayName);
          case 'vibe_check':
            return _VibeCheckBubble(msg: msg, displayName: widget.displayName);
          case 'listen_together':
            return _ListenTogetherCard(
              msg: msg,
              displayName: widget.displayName,
              isActive: _listenTogetherActive,
              seconds: _listenSeconds,
              onEnd: _endListenTogether,
            );
          case 'roast':
            return _RoastCard(msg: msg, displayName: widget.displayName);
          case 'mood_reply':
            return _MoodReplyBubble(msg: msg, displayName: widget.displayName);
          default:
            return _bubble(msg);
        }
      },
    );
  }

  // ── Streak banner ────────────────────────────────────────────────

  Widget _streakBanner() {
    final label = _bothToday
        ? '🔥 $_streakCount-day streak · both sent today ✓'
        : _sentToday
            ? '🔥 $_streakCount-day streak · waiting for their clip'
            : '🔥 $_streakCount-day streak · send a clip to keep it going';
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ClipStreaksScreen())),
      child: Container(
        width: double.infinity,
        color: AuraTheme.accent.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label,
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AuraTheme.accent)),
      ),
    );
  }

  Widget _vibeCheckPrompt() {
    return GestureDetector(
      onTap: _answerVibeCheck,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFD700).withOpacity(0.12), AuraTheme.purple.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
        ),
        child: Row(children: [
          const Text('☀️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('vibe check DM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD700))),
              Text("what's your song rn? tap to answer",
                style: TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AuraTheme.textMuted, size: 18),
        ]),
      ),
    );
  }

  Widget _listenTogetherBanner() {
    final m = _listenSeconds ~/ 60;
    final s = (_listenSeconds % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4ECDC4).withOpacity(0.12), AuraTheme.purple.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.4)),
      ),
      child: Row(children: [
        const Text('🎧', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_listenSong ?? 'listening together',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF4ECDC4)), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$m:$s · same second',
              style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
          ]),
        ),
        GestureDetector(
          onTap: _endListenTogether,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.4)),
            ),
            child: const Text('end', style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700, color: Color(0xFF4ECDC4))),
          ),
        ),
      ]),
    );
  }

  // ── Text bubble ──────────────────────────────────────────────────

  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    final isReaction = msg['isReaction'] == true;
    final text = msg['text'] as String? ?? '';

    return GestureDetector(
      onLongPress: () => _showReactionPicker(msg),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: isMe
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AuraTheme.purple, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AuraTheme.purple.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: const Border(
                    left: BorderSide(color: AuraTheme.purple, width: 3),
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isReaction ? 13 : 15,
                  fontStyle: isReaction ? FontStyle.italic : FontStyle.normal,
                  height: 1.3,
                ),
              ),
              if (msg['reaction'] != null) ...[
                const SizedBox(height: 4),
                Text(msg['reaction'] as String,
                  style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── NUDGE event marker ───────────────────────────────────────────

  Widget _nudgeMarker(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        const Expanded(child: Divider(color: Color(0xFF2A2A45), height: 1)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AuraTheme.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AuraTheme.purple.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚡', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 5),
            Text(
              isMe ? 'you nudged ${widget.displayName}' : '${widget.displayName} nudged you',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AuraTheme.purple,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFF2A2A45), height: 1)),
      ]),
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border(left: BorderSide(color: AuraTheme.purple, width: 3)),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  // ── Reaction picker ──────────────────────────────────────────────

  void _showReactionPicker(Map<String, dynamic> msg) {
    final overlay = Overlay.of(context);
    _reactionOverlay?.remove();
    final idx = _messages.indexOf(msg);
    if (idx < 0) return;

    _reactionOverlay = OverlayEntry(builder: (_) => Positioned.fill(
      child: GestureDetector(
        onTap: () { _reactionOverlay?.remove(); _reactionOverlay = null; },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AuraTheme.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AuraTheme.purple.withOpacity(0.3)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['❤️', '🔥', '😂', '😮', '👏', '💯'].map((emoji) =>
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _messages[idx] = {..._messages[idx], 'reaction': emoji};
                        });
                        _reactionOverlay?.remove();
                        _reactionOverlay = null;
                        HapticFeedback.selectionClick();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _reactionOverlay?.remove();
                    _reactionOverlay = null;
                    _openMoodReply(msg);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AuraTheme.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AuraTheme.purple.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.music_note_rounded, color: AuraTheme.purple, size: 13),
                      SizedBox(width: 5),
                      Text('reply with a song',
                        style: TextStyle(fontSize: 12, color: AuraTheme.purple,
                            fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ));
    overlay.insert(_reactionOverlay!);
  }

  // ── Empty state ──────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AuraTheme.purple, AuraTheme.cyan],
            ),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
            color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          'Start a transmission with\n${widget.displayName}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AuraTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openClip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AuraTheme.purple, AuraTheme.cyan],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.music_note_rounded, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text('drop a clip',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 10, right: 10, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        border: const Border(top: BorderSide(color: Color(0xFF1A1A2E), width: 1)),
      ),
      child: Row(children: [
        // Clip button
        _InputIconBtn(
          icon: Icons.music_note_rounded,
          color: AuraTheme.accent,
          onTap: _openClip,
        ),
        const SizedBox(width: 4),
        // NUDGE button
        _InputIconBtn(
          icon: Icons.bolt_rounded,
          color: AuraTheme.purple,
          onTap: _sendNudge,
          tooltip: 'Nudge',
        ),
        const SizedBox(width: 4),
        // Features "+" button
        _InputIconBtn(
          icon: Icons.add_rounded,
          color: const Color(0xFF4ECDC4),
          onTap: _showFeatureSheet,
          tooltip: 'More',
        ),
        const SizedBox(width: 8),
        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AuraTheme.purple.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: AuraTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'TRANSMIT_',
                hintStyle: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  color: AuraTheme.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AuraTheme.purple, Color(0xFF2563EB)],
              ),
              shape: BoxShape.circle,
              boxShadow: AuraTheme.glowShadow(color: AuraTheme.purple, radius: 8),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
          ),
        ),
      ]),
    );
  }
}

// ── Input icon button ─────────────────────────────────────────────────

class _InputIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const _InputIconBtn({required this.icon, required this.color, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ── Typing dots ────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [AuraTheme.purple, AuraTheme.purpleLight, AuraTheme.cyan];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
          final bounce = math.sin(phase * math.pi);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 7,
            height: 7 + bounce * 5,
            decoration: BoxDecoration(
              color: colors[i].withOpacity(0.4 + bounce * 0.6),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

// ── Profile Sheet ─────────────────────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  final String displayName;
  final String username;
  final VoidCallback onNudge;
  final VoidCallback onCall;

  const _ProfileSheet({
    required this.displayName,
    required this.username,
    required this.onNudge,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Avatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AuraTheme.purple, AuraTheme.cyan],
            ),
            boxShadow: AuraTheme.glowShadow(color: AuraTheme.purple, radius: 16),
          ),
          child: Center(
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AuraTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(username,
          style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11, color: AuraTheme.textMuted)),

        const SizedBox(height: 20),

        // Stats row
        Row(children: [
          _StatCard(label: 'ORBIT_SYNC', value: '87%', color: AuraTheme.purple),
          const SizedBox(width: 10),
          _StatCard(label: 'WAVELENGTH', value: 'Indie / Lo-fi', color: AuraTheme.cyan),
        ]),

        const SizedBox(height: 20),

        // Quick actions
        Row(children: [
          Expanded(
            child: _SheetAction(
              icon: Icons.bolt_rounded,
              label: 'NUDGE',
              color: AuraTheme.purple,
              onTap: () { Navigator.pop(context); onNudge(); },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SheetAction(
              icon: Icons.call_rounded,
              label: 'CALL',
              color: AuraTheme.cyan,
              onTap: () { Navigator.pop(context); onCall(); },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SheetAction(
              icon: Icons.person_rounded,
              label: 'PROFILE',
              color: AuraTheme.accent,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: TextStyle(fontFamily: 'SpaceMono', fontSize: 7, letterSpacing: 1, color: color)),
        const SizedBox(height: 4),
        Text(value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AuraTheme.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(fontFamily: 'SpaceMono', fontSize: 8, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    ),
  );
}

// ── Clip message bubble ────────────────────────────────────────────────

class _ClipBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _ClipBubble({required this.msg, required this.displayName});

  @override
  State<_ClipBubble> createState() => _ClipBubbleState();
}

class _ClipBubbleState extends State<_ClipBubble> {
  AudioPlayer get _player => AudioPlayerService.i.player;
  bool _playing = false;
  double _playPos = 0;
  Timer? _stopTimer;
  Timer? _posTimer;
  late List<double> _wave;

  double get _clipStart => (widget.msg['clipStart'] as num?)?.toDouble() ?? 0;
  double get _clipEnd   => (widget.msg['clipEnd']   as num?)?.toDouble() ?? 15;
  double get _clipDur   => _clipEnd - _clipStart;
  bool   get _isMe      => widget.msg['isMe'] == true;

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
    AudioPlayerService.i.stopIfOwner('dm_clip_${widget.msg['song']}');
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
      setState(() { _playing = true; _playPos = _clipStart; });
      _posTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (!mounted) return;
        setState(() => _playPos = (_playPos + 0.15).clamp(_clipStart, _clipEnd));
      });
      _stopTimer = Timer(Duration(milliseconds: (_clipDur * 1000).round()), () {
        _posTimer?.cancel();
        if (mounted) setState(() { _playing = false; _playPos = _clipStart; });
      });
      return;
    }

    setState(() { _playing = true; _playPos = _clipStart; });
    try {
      await AudioPlayerService.i.play(url, owner: 'dm_clip_${widget.msg['song']}');
      await _player.seek(Duration(milliseconds: (_clipStart * 1000).round()));
      _posTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() => _playPos = (_player.position.inMilliseconds / 1000.0)
            .clamp(_clipStart, _clipEnd));
      });
      _stopTimer = Timer(Duration(milliseconds: (_clipDur * 1000).round()), () async {
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
    final song   = widget.msg['song']   as String? ?? 'unknown';
    final artist = widget.msg['artist'] as String? ?? '';
    final prog   = _playing ? ((_playPos - _clipStart) / _clipDur).clamp(0.0, 1.0) : 0.0;

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: 230,
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_isMe ? 16 : 4),
            bottomRight: Radius.circular(_isMe ? 4 : 16),
          ),
          border: Border(
            left: BorderSide(
              color: _isMe ? Colors.transparent : AuraTheme.purple,
              width: _isMe ? 0 : 3,
            ),
            top:    BorderSide(color: AuraTheme.purple.withOpacity(0.2)),
            right:  BorderSide(color: AuraTheme.purple.withOpacity(0.2)),
            bottom: BorderSide(color: AuraTheme.purple.withOpacity(0.2)),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: artUrl != null && artUrl.isNotEmpty
                    ? Image.network(artUrl, width: 36, height: 36, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artPlaceholder())
                    : _artPlaceholder(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(song, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(artist, style: const TextStyle(color: AuraTheme.textMuted, fontSize: 10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),

          // Waveform
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _wave.asMap().entries.map((e) {
                  final barT = e.key / _wave.length * _clipDur + _clipStart;
                  final played = barT <= _playPos && _playing;
                  return Expanded(
                    child: Container(
                      height: e.value,
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        gradient: played
                            ? const LinearGradient(
                                colors: [AuraTheme.purple, AuraTheme.cyan],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : null,
                        color: played ? null : AuraTheme.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(children: [
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AuraTheme.purple, AuraTheme.cyan]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: prog,
                      backgroundColor: AuraTheme.textMuted.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AuraTheme.purple),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmt(_clipStart)} – ${_fmt(_clipEnd)}  ·  ${_clipDur.round()}s',
                    style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted),
                  ),
                ]),
              ),
            ]),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AuraTheme.purple.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              _isMe ? 'you dropped this' : '${widget.displayName} dropped this',
              style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted, fontStyle: FontStyle.italic),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _artPlaceholder() => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color: AuraTheme.purple.withOpacity(0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: const Icon(Icons.music_note_rounded, color: AuraTheme.purple, size: 18),
  );
}

// ── Feature row (inside _showFeatureSheet) ────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, sublabel;
  final VoidCallback onTap;
  const _FeatureRow({required this.icon, required this.color,
      required this.label, required this.sublabel, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: AuraTheme.textPrimary)),
          Text(sublabel, style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
        ])),
        Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5), size: 18),
      ]),
    ),
  );
}

// ── Song Picker Sheet ──────────────────────────────────────────────────────────

class _SongPickerSheet extends StatefulWidget {
  final String title, subtitle;
  final void Function(String song, String artist, String? artUrl, String? previewUrl) onPicked;
  const _SongPickerSheet({required this.title, required this.subtitle, required this.onPicked});

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  static const _suggestions = [
    ('Espresso', 'Sabrina Carpenter'),
    ('luther', 'Kendrick Lamar & SZA'),
    ('APT.', 'ROSÉ & Bruno Mars'),
    ('Die With A Smile', 'Lady Gaga & Bruno Mars'),
    ('Golden Hour', 'JVKE'),
    ('Flowers', 'Miley Cyrus'),
    ('Levitating', 'Dua Lipa'),
    ('Anti-Hero', 'Taylor Swift'),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final lower = q.toLowerCase();
    final filtered = _suggestions
        .where((s) => s.$1.toLowerCase().contains(lower) || s.$2.toLowerCase().contains(lower))
        .map((s) => {'song': s.$1, 'artist': s.$2, 'artUrl': null, 'previewUrl': null})
        .toList();
    if (mounted) setState(() { _results = filtered; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final items = _results.isNotEmpty
        ? _results
        : _suggestions.map((s) => {'song': s.$1, 'artist': s.$2,
            'artUrl': null as dynamic, 'previewUrl': null as dynamic}).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuraTheme.purple.withOpacity(0.2)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: AuraTheme.textPrimary)),
            Text(widget.subtitle, style: const TextStyle(fontSize: 12,
                color: AuraTheme.textMuted)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuraTheme.purple.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _search,
                style: const TextStyle(fontSize: 14, color: AuraTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'search songs...',
                  hintStyle: TextStyle(color: AuraTheme.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: AuraTheme.textMuted, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AuraTheme.purple, strokeWidth: 2))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () => widget.onPicked(
                    item['song'] as String,
                    item['artist'] as String,
                    item['artUrl'] as String?,
                    item['previewUrl'] as String?,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AuraTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AuraTheme.purple.withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AuraTheme.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note_rounded,
                            color: AuraTheme.purple, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['song'] as String, style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: AuraTheme.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(item['artist'] as String, style: const TextStyle(fontSize: 11,
                            color: AuraTheme.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      const Icon(Icons.add_rounded, color: AuraTheme.purple, size: 18),
                    ]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

// ── Song Pass Bubble ───────────────────────────────────────────────────────────

class _SongPassBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _SongPassBubble({required this.msg, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final isMe = msg['isMe'] == true;
    final song = msg['song'] as String? ?? '';
    final artist = msg['artist'] as String? ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isMe ? null : AuraTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? null : Border.all(color: AuraTheme.purple.withOpacity(0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎵 song pass', style: TextStyle(fontSize: 10,
                  color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(song, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(artist, style: const TextStyle(fontSize: 11,
                  color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── Vibe Check Bubble ──────────────────────────────────────────────────────────

class _VibeCheckBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _VibeCheckBubble({required this.msg, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final isMe = msg['isMe'] == true;
    final song = msg['song'] as String? ?? '';
    final artist = msg['artist'] as String? ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
        ),
        child: Row(children: [
          const Text('☀️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? 'your vibe rn' : "${displayName.split(' ').first}'s vibe",
              style: const TextStyle(fontSize: 10, color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(song, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AuraTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(artist, style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}

// ── Listen Together Card ───────────────────────────────────────────────────────

class _ListenTogetherCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  final bool isActive;
  final int seconds;
  final VoidCallback onEnd;
  const _ListenTogetherCard({required this.msg, required this.displayName,
      required this.isActive, required this.seconds, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final song = msg['song'] as String? ?? '';
    final artist = msg['artist'] as String? ?? '';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF4ECDC4).withOpacity(0.12),
                AuraTheme.purple.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.4)),
        ),
        child: Column(children: [
          const Text('🎧 listening together', style: TextStyle(fontSize: 11,
              color: Color(0xFF4ECDC4), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(song, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
              color: AuraTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(artist, style: const TextStyle(fontSize: 12, color: AuraTheme.textMuted)),
          if (isActive) ...[
            const SizedBox(height: 8),
            Text('$m:$s · in sync', style: const TextStyle(fontSize: 11,
                color: Color(0xFF4ECDC4))),
          ],
        ]),
      ),
    );
  }
}

// ── Roast My Playlist Card ─────────────────────────────────────────────────────

class _RoastCard extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _RoastCard({required this.msg, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final songs = (msg['songs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isMe = msg['isMe'] == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFF6B35).withOpacity(0.12),
                AuraTheme.purple.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.local_fire_department_rounded,
                color: Color(0xFFFF6B35), size: 16),
            SizedBox(width: 6),
            Text('roast my playlist', style: TextStyle(fontSize: 11,
                color: Color(0xFFFF6B35), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 10),
          ...songs.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.music_note_rounded,
                    color: Color(0xFFFF6B35), size: 14)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['song'] as String? ?? '', style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: AuraTheme.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(s['artist'] as String? ?? '', style: const TextStyle(fontSize: 10,
                    color: AuraTheme.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          )),
          const SizedBox(height: 4),
          Text(isMe ? 'waiting for the roast...' : '👆 this is the playlist lol',
            style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted,
                fontStyle: FontStyle.italic)),
        ]),
      ),
    );
  }
}

// ── Mood Reply Bubble ──────────────────────────────────────────────────────────

class _MoodReplyBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final String displayName;
  const _MoodReplyBubble({required this.msg, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final isMe = msg['isMe'] == true;
    final song = msg['song'] as String? ?? '';
    final artist = msg['artist'] as String? ?? '';
    final replyTo = msg['replyTo'] as String? ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyTo.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: AuraTheme.purple, width: 2)),
                ),
                child: Text(replyTo, style: const TextStyle(fontSize: 10,
                    color: AuraTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(colors: [AuraTheme.purple, Color(0xFF7C3AED)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isMe ? null : AuraTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: isMe ? null : Border.all(color: AuraTheme.purple.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Text('🎵', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(song, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(artist, style: const TextStyle(fontSize: 11,
                      color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Call Screen ────────────────────────────────────────────────────────────────

enum _CallState { connecting, ringing, connected }

class _CallScreen extends StatefulWidget {
  final String displayName, username;
  final bool isVideo;
  const _CallScreen({required this.displayName, required this.username, required this.isVideo});

  @override
  State<_CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<_CallScreen>
    with SingleTickerProviderStateMixin {
  _CallState _state = _CallState.connecting;
  bool _muted = false, _speakerOn = true, _cameraOff = false;
  int _seconds = 0;
  Timer? _connectTimer, _durationTimer;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _connectTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _state = _CallState.ringing);
      _connectTimer = Timer(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        setState(() => _state = _CallState.connected);
        _durationTimer = Timer.periodic(
          const Duration(seconds: 1), (_) { if (mounted) setState(() => _seconds++); });
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
      case _CallState.connecting: return 'Connecting...';
      case _CallState.ringing:    return 'Ringing...';
      case _CallState.connected:
        final m = _seconds ~/ 60;
        final s = (_seconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : '?';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF130F2A), Color(0xFF0A0A18)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const Spacer(flex: 1),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                color: Colors.white38, size: 15),
              const SizedBox(width: 6),
              Text(
                widget.isVideo ? 'Video call' : 'Voice call',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Transform.scale(
                scale: _state == _CallState.ringing ? _pulse.value : 1.0,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AuraTheme.purple, AuraTheme.cyan]),
                    boxShadow: AuraTheme.glowShadow(
                      color: AuraTheme.purple,
                      radius: _state == _CallState.ringing ? 24 : 12,
                      opacity: 0.5),
                  ),
                  child: Center(
                    child: Text(initial,
                      style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.username,
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'SpaceMono')),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusLabel,
                key: ValueKey(_statusLabel),
                style: TextStyle(
                  color: _state == _CallState.connected ? AuraTheme.cyan : Colors.white38,
                  fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(flex: 2),
            if (_state == _CallState.connected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlBtn(icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      label: _muted ? 'Unmute' : 'Mute',
                      active: _muted, onTap: () => setState(() => _muted = !_muted)),
                    _controlBtn(icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      label: _speakerOn ? 'Speaker' : 'Earpiece',
                      active: _speakerOn, onTap: () => setState(() => _speakerOn = !_speakerOn)),
                    if (widget.isVideo)
                      _controlBtn(icon: _cameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                        label: _cameraOff ? 'Camera off' : 'Camera on',
                        active: !_cameraOff, onTap: () => setState(() => _cameraOff = !_cameraOff)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 68, height: 68,
                decoration: const BoxDecoration(color: Color(0xFFE74C3C), shape: BoxShape.circle),
                child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            const Text('End call', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const Spacer(flex: 1),
          ]),
        ),
      ),
    );
  }

  Widget _controlBtn({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(active ? 0.2 : 0.08)),
          ),
          child: Icon(icon, color: active ? Colors.white : Colors.white38, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}
