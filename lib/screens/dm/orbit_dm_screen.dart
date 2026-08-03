import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../services/audio_player_service.dart';
import '../../config/api_config.dart';
import 'orbit_dm_model.dart';
import 'orbit_dm_service.dart';
import 'orbit_dm_wallpapers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORBIT DM Screen — full-featured messaging
// Features: voice notes · guess-the-song · music poll · collab playlist pin
//           shared mood board · thread replies · disappearing messages
//           scheduled send · pinned messages · message search
//           read receipts w/ song · conversation theme · concert status
//           AI chat recap · tone shifter · smart reply chips
// ─────────────────────────────────────────────────────────────────────────────

class OrbitDmScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String otherHandle;

  const OrbitDmScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    required this.otherHandle,
  });

  @override
  State<OrbitDmScreen> createState() => _OrbitDmScreenState();
}

class _OrbitDmScreenState extends State<OrbitDmScreen>
    with WidgetsBindingObserver {
  final _svc = OrbitDmService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  late final String _myUid;
  late final String _cid;

  // UI state
  bool _showSearch = false;
  String _searchQuery = '';
  bool _showPinned = false;
  bool _showMoodBoard = false;
  bool _showAttachmentPicker = false;
  bool _showScheduleSheet = false;

  // Thread reply
  DmMessage? _replyingTo;

  // Scheduled send
  DateTime? _scheduledAt;

  // Recap
  bool _loadingRecap = false;
  String? _recapText;

  // Tone shifter
  String? _activeVibe;          // 'fire' | 'tender' | 'mysterious' | 'chill'
  bool _rewriting = false;
  String? _originalDraft;       // saved before rewrite so user can undo

  // Smart replies
  List<String> _smartReplies = [];
  bool _loadingReplies = false;
  String? _lastIncomingMsgId;   // track which msg we generated replies for

  // Theme (accent colour + optional photo background)
  Color _themeColor = AuraTheme.accent;

  // Pinned messages cache
  List<DmMessage> _pinnedMessages = [];

  // Disappearing timer
  int? _disappearAfterSecs;

  // Concert status
  bool _atConcert = false;
  String? _concertLabel;

  // Wallpaper / custom background
  DmWallpaper _wallpaper = DmWallpaper.none;
  String? _bgImagePath;    // local file path for DmWallpaper.custom
  Color? _customColor;     // user-picked hex colour (from color wheel)

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _cid = OrbitDmService.convId(_myUid, widget.otherUid);
    WidgetsBinding.instance.addObserver(this);
    _svc.ensureConversation(_myUid, widget.otherUid, _cid);
    // Prune expired messages on open
    _svc.pruneExpiredMessages(_cid);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _svc.pruneExpiredMessages(_cid);
    }
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

  Color get _accent => _themeColor;

  String _msgPreview(DmMessage m) {
    switch (m.type) {
      case DmMsgType.text:
        return m.text ?? '';
      case DmMsgType.clip:
        return '🎵 ${m.songTitle}';
      case DmMsgType.voiceNote:
        return '🎤 voice note';
      case DmMsgType.guessSong:
        return '🎲 guess the song';
      case DmMsgType.poll:
        return '📊 ${m.pollQuestion}';
      case DmMsgType.lyric:
        return '"${m.lyricText}"';
      case DmMsgType.gif:
        return '🎞 GIF';
      case DmMsgType.sticker:
        return '🪄 sticker';
      case DmMsgType.location:
        return '📍 location';
      case DmMsgType.viewOnce:
        return '👁 view once';
      case DmMsgType.doodle:
        return '✏️ doodle';
      case DmMsgType.whiteboard:
        return '🖌️ whiteboard';
      default:
        return m.type.name;
    }
  }

  // ── SEND HELPERS ───────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final reply = _replyingTo;
    final sched = _scheduledAt;
    final disappear = _disappearAfterSecs != null
        ? DateTime.now().add(Duration(seconds: _disappearAfterSecs!))
        : null;

    await _svc.sendText(
      _cid,
      text: text,
      replyToId: reply?.id,
      replyToPreview:
          reply != null ? _msgPreview(reply) : null,
      scheduledAt: sched,
      disappearsAt: disappear,
    );

    if (!mounted) return;
    setState(() {
      _ctrl.clear();
      _replyingTo = null;
      _scheduledAt = null;
      _activeVibe = null;
      _originalDraft = null;
      _smartReplies = [];
    });
    _scrollToBottom();
  }

  Future<void> _sendDemoVoiceNote() async {
    // Demo: fake waveform. Real implementation uses `record` package.
    final rng = math.Random();
    final wave = List.generate(40, (_) => 0.1 + rng.nextDouble() * 0.9);
    await _svc.sendVoiceNote(
      _cid,
      voiceUrl: '',         // Real: Firebase Storage URL after upload
      duration: 12.0,       // Real: actual recording duration
      waveform: wave,
      replyToId: _replyingTo?.id,
      replyToPreview:
          _replyingTo != null ? _msgPreview(_replyingTo!) : null,
    );
    if (!mounted) return;
    setState(() { _replyingTo = null; _showAttachmentPicker = false; });
    _scrollToBottom();
  }

  Future<void> _sendGuessSong() async {
    // Demo song — real: open a song-picker sheet
    await _svc.sendGuessSong(
      _cid,
      songTitle: 'Espresso',
      artist: 'Sabrina Carpenter',
      artUrl:
          'https://i.scdn.co/image/ab67616d0000b273e3e3b64cea45265469d4cde5',
      previewUrl: null,
      clipStart: 30.0,
      clipEnd: 33.0,
    );
    if (!mounted) return;
    setState(() => _showAttachmentPicker = false);
    _scrollToBottom();
  }

  Future<void> _sendMusicPoll() async {
    await _svc.sendPoll(
      _cid,
      question: 'which song for our playlist?',
      options: [
        DmPollOption(id: '1', label: 'Espresso', artist: 'Sabrina Carpenter',
            artUrl: 'https://i.scdn.co/image/ab67616d0000b273e3e3b64cea45265469d4cde5'),
        DmPollOption(id: '2', label: 'Cruel Summer', artist: 'Taylor Swift',
            artUrl: 'https://i.scdn.co/image/ab67616d0000b273e787cffec20aa2a396a61647'),
      ],
    );
    if (!mounted) return;
    setState(() => _showAttachmentPicker = false);
    _scrollToBottom();
  }

  Future<void> _sendLyric() async {
    await _svc.sendLyric(
      _cid,
      lyricText: 'I\'m working late \'cause I\'m a singer',
      lyricSong: 'Espresso',
      lyricArtist: 'Sabrina Carpenter',
      artUrl:
          'https://i.scdn.co/image/ab67616d0000b273e3e3b64cea45265469d4cde5',
    );
    if (!mounted) return;
    setState(() => _showAttachmentPicker = false);
    _scrollToBottom();
  }

  Future<void> _sendLocation() async {
    await _svc.sendLocation(
      _cid,
      lat: 12.9716,
      lng: 77.5946,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    if (!mounted) return;
    setState(() => _showAttachmentPicker = false);
    _scrollToBottom();
  }

  Future<void> _sendViewOnce() async {
    await _svc.sendViewOnce(
      _cid,
      text: 'this disappears after you read it 👁',
    );
    if (!mounted) return;
    setState(() => _showAttachmentPicker = false);
    _scrollToBottom();
  }

  // ── DOODLE CANVAS ─────────────────────────────────────────────────
  void _openDoodleCanvas() {
    setState(() => _showAttachmentPicker = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoodleSheet(
        accentColor: _themeColor,
        onSend: (strokes) async {
          final hex = '#${_themeColor.value.toRadixString(16).substring(2).toUpperCase()}';
          await _svc.sendDoodle(
            _cid,
            strokes: strokes,
            color: hex,
            replyToId: _replyingTo?.id,
            replyToPreview: _replyingTo != null ? _msgPreview(_replyingTo!) : null,
          );
          if (mounted) {
            setState(() => _replyingTo = null);
            _scrollToBottom();
          }
        },
      ),
    );
  }

  // ── WHITEBOARD CANVAS ─────────────────────────────────────────────
  void _openWhiteboardCanvas() {
    setState(() => _showAttachmentPicker = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhiteboardSheet(
        onSend: (data) async {
          await _svc.sendWhiteboard(
            _cid,
            data: data,
            replyToId: _replyingTo?.id,
            replyToPreview: _replyingTo != null ? _msgPreview(_replyingTo!) : null,
          );
          if (mounted) {
            setState(() => _replyingTo = null);
            _scrollToBottom();
          }
        },
      ),
    );
  }

  // ── GEMINI HELPER ─────────────────────────────────────────────────
  Future<String?> _callGemini(String prompt) async {
    try {
      final key = ApiConfig.geminiKey;   // your Gemini API key from ApiConfig
      if (key == null || key.isEmpty) return null;
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash-latest:generateContent?key=$key',
      );
      final body = jsonEncode({
        'contents': [
          {'parts': [{'text': prompt}]}
        ],
        'generationConfig': {'maxOutputTokens': 150, 'temperature': 0.8},
      });
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['candidates'] as List?)
          ?.firstOrNull?['content']?['parts']
              ?.firstOrNull?['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── TONE SHIFTER ───────────────────────────────────────────────────
  Future<void> _rewriteWithTone(String vibe) async {
    final draft = _ctrl.text.trim();
    if (draft.isEmpty) return;

    // Save original so user can undo
    if (_originalDraft == null) _originalDraft = draft;

    setState(() { _rewriting = true; _activeVibe = vibe; });

    final vibeInstructions = {
      'fire':
          'Rewrite as intense, hyped, all-caps energy. Keep it short (≤12 words). '
          'Use at most one emoji. No hashtags.',
      'tender':
          'Rewrite as warm, soft, emotionally sincere. Keep it short (≤12 words). '
          'Gentle language, no slang. At most one soft emoji.',
      'mysterious':
          'Rewrite as cryptic and poetic — sounds like a lyric. ≤12 words. '
          'No emoji. Leave something unsaid.',
      'chill':
          'Rewrite as super casual, relaxed, like a text from a cool friend. '
          '≤10 words. Lowercase OK. At most one emoji.',
    };

    final prompt = 'Rewrite this message in a "$vibe" tone for a music app DM. '
        '${vibeInstructions[vibe]} '
        'Return ONLY the rewritten message, nothing else.\n\n'
        'Original: "$draft"';

    final result = await _callGemini(prompt);

    if (!mounted) return;
    setState(() {
      _rewriting = false;
      if (result != null && result.trim().isNotEmpty) {
        _ctrl.text = result.trim();
        _ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _ctrl.text.length));
      }
    });
  }

  void _clearVibe() {
    if (_originalDraft != null) {
      _ctrl.text = _originalDraft!;
      _ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _ctrl.text.length));
      _originalDraft = null;
    }
    setState(() => _activeVibe = null);
  }

  // ── SMART REPLIES ──────────────────────────────────────────────────
  Future<void> _generateSmartReplies(DmMessage lastMsg) async {
    if (lastMsg.id == _lastIncomingMsgId) return;   // already generated
    if (lastMsg.senderId == _myUid) return;          // only for incoming msgs

    _lastIncomingMsgId = lastMsg.id;
    setState(() { _smartReplies = []; _loadingReplies = true; });

    final context = _msgPreview(lastMsg);
    final prompt =
        'You are a smart reply generator for a music social app called ORBIT. '
        'Generate exactly 3 short, casual, music-aware reply suggestions for this '
        'incoming message: "$context". '
        'Rules: each reply ≤6 words · lowercase · max 1 emoji per reply · '
        'music-related where natural · comma-separated on ONE line · no numbering · '
        'no quotes. Example format:  ok this slaps 🔥, sending one back rn, knew you\'d love this era';

    final result = await _callGemini(prompt);

    if (!mounted) return;

    List<String> replies = [];
    if (result != null && result.trim().isNotEmpty) {
      replies = result
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length < 50)
          .take(3)
          .toList();
    }

    // Fallback replies if AI call fails or key missing
    if (replies.isEmpty) {
      replies = _fallbackReplies(lastMsg);
    }

    if (mounted) setState(() { _smartReplies = replies; _loadingReplies = false; });
  }

  List<String> _fallbackReplies(DmMessage msg) {
    switch (msg.type) {
      case DmMsgType.clip:
        return ['ok this SLAPS 🔥', 'sending one back rn', 'this is my song rn'];
      case DmMsgType.poll:
        return ['voted!', 'tough choice ngl', 'adding both honestly'];
      case DmMsgType.lyric:
        return ['this lyric hits different', 'ok you get me 💜', 'sending you one back'];
      case DmMsgType.guessSong:
        return ['is it espresso??', 'no idea but I\'m hooked', 'play it again'];
      case DmMsgType.voiceNote:
        return ['ok i felt that', 'saying so much 🎤', 'voice note back rn'];
      case DmMsgType.doodle:
        return ['ok this is art ✏️', 'drawing one back', 'this doodle is everything'];
      case DmMsgType.whiteboard:
        return ['ok this is a masterpiece', 'painting one back 🖌️', 'love this'];
      default:
        return ['lol same', 'fr tho', 'ok this 🔥'];
    }
  }

  // ── AI RECAP ───────────────────────────────────────────────────────
  Future<void> _loadRecap() async {
    if (_loadingRecap) return;
    setState(() => _loadingRecap = true);
    final context = await _svc.buildRecapContext(
      _cid,
      myName: 'you',
      theirName: widget.otherName,
    );
    // Real: call Gemini/GPT with context. Demo: generate locally.
    final lines = context.split('\n').where((l) => l.isNotEmpty).toList();
    final songs = lines
        .where((l) => l.contains('[sent clip') || l.contains('[shared song'))
        .length;
    final polls = lines.where((l) => l.contains('[poll')).length;
    final total = lines.length;
    final recap = 'this week you and ${widget.otherName} exchanged $total '
        'messages${songs > 0 ? ', shared $songs song${songs == 1 ? '' : 's'}' : ''}'
        '${polls > 0 ? ', ran $polls poll${polls == 1 ? '' : 's'}' : ''}. '
        'vibes were all over the place — in the best way.';
    if (!mounted) return;
    setState(() { _loadingRecap = false; _recapText = recap; });
  }

  // ── PINNED MESSAGES ────────────────────────────────────────────────
  Future<void> _loadPinnedMessages(List<String> ids) async {
    _pinnedMessages = await _svc.fetchPinnedMessages(_cid, ids);
    if (mounted) setState(() {});
  }

  // ── BUILD ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DmConversation?>(
      stream: _svc.conversationStream(_cid),
      builder: (ctx, convSnap) {
        final conv = convSnap.data;
        if (conv != null) {
          // Apply theme
          final hex = conv.themeColor;
          if (hex != null && hex.isNotEmpty) {
            try {
              _themeColor = Color(
                  int.parse(hex.replaceFirst('#', ''), radix: 16) +
                      0xFF000000);
            } catch (_) {}
          }
          _disappearAfterSecs = conv.disappearAfterSeconds;
          // Concert status
          final cs = conv.concertStatus[widget.otherUid];
          _atConcert = cs != null;
          _concertLabel = cs;
          // Load pinned if changed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadPinnedMessages(conv.pinnedMessageIds);
          });
        }

        final hasWallpaper = _wallpaper != DmWallpaper.none;
        return Scaffold(
          backgroundColor: AuraTheme.background,
          extendBodyBehindAppBar: hasWallpaper,
          appBar: hasWallpaper ? null : _buildAppBar(conv),
          body: hasWallpaper
              ? WallpaperWidget(
                  wallpaper: _wallpaper,
                  customImagePath: _bgImagePath,
                  child: _dmBody(conv),
                )
              : _dmBody(conv),
        );
      },
    );
  }

  Widget _dmBody(DmConversation? conv) {
    return Column(children: [
      // ── App bar overlay when wallpaper is active ──
      if (_wallpaper != DmWallpaper.none) _buildAppBar(conv),

      // ── Concert status banner ──
      if (_atConcert && _concertLabel != null) _concertBanner(),

      // ── Disappearing timer indicator ──
      if (_disappearAfterSecs != null) _disappearBanner(),

      // ── Pinned messages ribbon ──
      if (_showPinned && _pinnedMessages.isNotEmpty)
        _pinnedRibbon(conv),

      // ── Shared mood board ──
      if (_showMoodBoard) _moodBoardPanel(),

      // ── Search bar ──
      if (_showSearch) _searchBar(),

      // ── AI recap card ──
      if (_recapText != null) _recapCard(),

      // ── Messages ──
      Expanded(child: _buildMessageList()),

      // ── Reply preview ──
      if (_replyingTo != null) _replyPreview(),

      // ── Scheduled send indicator ──
      if (_scheduledAt != null) _scheduledBanner(),

      // ── Attachment picker ──
      if (_showAttachmentPicker) _attachmentPicker(),

      // ── Input bar ──
      _inputBar(),
    ]);
      },
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(DmConversation? conv) {
    return AppBar(
      backgroundColor: AuraTheme.background,
      elevation: 0,
      titleSpacing: 0,
      title: Row(children: [
        // Avatar + pulse ring if at concert
        Stack(alignment: Alignment.center, children: [
          if (_atConcert)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accent, width: 2),
              ),
            ),
          CircleAvatar(
            radius: 18,
            backgroundColor: _accent.withOpacity(0.15),
            child: Text(
              widget.otherName.isNotEmpty
                  ? widget.otherName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: _accent, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            if (_atConcert && _concertLabel != null)
              Text('🎤 at a concert · $_concertLabel',
                  style: TextStyle(fontSize: 10, color: _accent),
                  overflow: TextOverflow.ellipsis)
            else
              Text('@${widget.otherHandle}',
                  style: const TextStyle(
                      fontSize: 11, color: AuraTheme.textMuted)),
          ]),
        ),
      ]),
      actions: [
        // Search
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search,
              color: AuraTheme.textPrimary, size: 22),
          onPressed: () =>
              setState(() { _showSearch = !_showSearch; _searchQuery = ''; }),
        ),
        // More options menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AuraTheme.textPrimary, size: 22),
          color: AuraTheme.card,
          onSelected: _handleMenuAction,
          itemBuilder: (_) => [
            _menuItem('theme',   '🎨  change theme'),
            _menuItem('pinned',  '📌  pinned messages'),
            _menuItem('board',   '🎵  mood board'),
            _menuItem('recap',   '✨  ai recap'),
            _menuItem('timer',   '⏱  disappearing messages'),
            _menuItem('concert', '🎤  ${_atConcert ? 'leave' : 'set'} concert status'),
            _menuItem('sched',   '📅  scheduled send'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label) =>
      PopupMenuItem(
        value: value,
        child: Text(label,
            style: const TextStyle(
                color: AuraTheme.textPrimary, fontSize: 14)),
      );

  void _handleMenuAction(String action) {
    switch (action) {
      case 'theme':
        _showThemePicker();
      case 'pinned':
        setState(() => _showPinned = !_showPinned);
      case 'board':
        setState(() => _showMoodBoard = !_showMoodBoard);
      case 'recap':
        _loadRecap();
      case 'timer':
        _showTimerPicker();
      case 'concert':
        _showConcertDialog();
      case 'sched':
        _showSchedulePicker();
    }
  }

  // ── BANNERS ────────────────────────────────────────────────────────

  Widget _concertBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      color: _accent.withOpacity(0.12),
      child: Row(children: [
        const Text('🎤', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${widget.otherName} is at a concert — $_concertLabel',
            style: TextStyle(fontSize: 12, color: _accent,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _disappearBanner() {
    final label = _disappearAfterSecs! >= 86400
        ? '${_disappearAfterSecs! ~/ 86400}d'
        : _disappearAfterSecs! >= 3600
            ? '${_disappearAfterSecs! ~/ 3600}h'
            : '${_disappearAfterSecs! ~/ 60}m';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.white.withOpacity(0.04),
      child: Row(children: [
        const Icon(Icons.timer_outlined, size: 13, color: AuraTheme.textMuted),
        const SizedBox(width: 6),
        Text('disappearing messages · $label',
            style: const TextStyle(
                fontSize: 11, color: AuraTheme.textMuted)),
        const Spacer(),
        GestureDetector(
          onTap: () => _svc.setDisappearTimer(_cid, null),
          child: const Text('turn off',
              style: TextStyle(fontSize: 11, color: AuraTheme.accent)),
        ),
      ]),
    );
  }

  Widget _scheduledBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      color: const Color(0xFF1A1A2E),
      child: Row(children: [
        const Icon(Icons.schedule, size: 14, color: AuraTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'sending at ${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
            '${_scheduledAt!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
                fontSize: 12, color: AuraTheme.textMuted),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _scheduledAt = null),
          child: const Icon(Icons.close, size: 14, color: AuraTheme.textMuted),
        ),
      ]),
    );
  }

  // ── PINNED RIBBON ──────────────────────────────────────────────────

  Widget _pinnedRibbon(DmConversation? conv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.push_pin_rounded, size: 13, color: _accent),
          const SizedBox(width: 5),
          Text('pinned · ${_pinnedMessages.length}',
              style: TextStyle(
                  fontSize: 11, color: _accent, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showPinned = false),
            child: const Icon(Icons.close, size: 14, color: AuraTheme.textMuted),
          ),
        ]),
        const SizedBox(height: 6),
        ..._pinnedMessages.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.push_pin_outlined, size: 11,
                    color: AuraTheme.textMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _msgPreview(m),
                    style: const TextStyle(
                        fontSize: 12, color: AuraTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _svc.togglePin(_cid, m.id, true),
                  child: const Icon(Icons.close, size: 12,
                      color: AuraTheme.textMuted),
                ),
              ]),
            )),
      ]),
    );
  }

  // ── MOOD BOARD ─────────────────────────────────────────────────────

  Widget _moodBoardPanel() {
    return StreamBuilder<List<MoodBoardItem>>(
      stream: _svc.moodBoardStream(_cid),
      builder: (ctx, snap) {
        final items = snap.data ?? [];
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.grid_view_rounded, size: 13, color: _accent),
              const SizedBox(width: 5),
              Text('shared mood board',
                  style: TextStyle(
                      fontSize: 11,
                      color: _accent,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => _addMoodBoardItem(),
                child: Icon(Icons.add, size: 16, color: _accent),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showMoodBoard = false),
                child: const Icon(Icons.close, size: 14,
                    color: AuraTheme.textMuted),
              ),
            ]),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('pin songs, lyrics & vibes here',
                    style: const TextStyle(
                        fontSize: 11, color: AuraTheme.textMuted)),
              )
            else ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: items.map((item) => _moodBoardChip(item)).toList(),
              ),
            ],
          ]),
        );
      },
    );
  }

  Widget _moodBoardChip(MoodBoardItem item) {
    final color = item.addedByUid == _myUid ? _accent : const Color(0xFF7F77DD);
    IconData icon;
    switch (item.type) {
      case MoodBoardItemType.song:
        icon = Icons.music_note_rounded;
      case MoodBoardItemType.lyric:
        icon = Icons.format_quote_rounded;
      case MoodBoardItemType.vibe:
        icon = Icons.auto_awesome;
    }
    return GestureDetector(
      onLongPress: () => _svc.removeMoodBoardItem(_cid, item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(item.content,
              style: TextStyle(fontSize: 11, color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _addMoodBoardItem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('add to mood board',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),
          _boardAddBtn(MoodBoardItemType.song, '🎵 add a song',
              'Espresso', artist: 'Sabrina Carpenter'),
          const SizedBox(height: 8),
          _boardAddBtn(MoodBoardItemType.lyric, '💬 add a lyric',
              '"I\'m working late \'cause I\'m a singer"'),
          const SizedBox(height: 8),
          _boardAddBtn(MoodBoardItemType.vibe, '✨ add a vibe',
              'golden hour energy'),
        ]),
      ),
    );
  }

  Widget _boardAddBtn(MoodBoardItemType type, String label, String content,
      {String? artist}) {
    return GestureDetector(
      onTap: () {
        _svc.addMoodBoardItem(
          _cid,
          MoodBoardItem(
            id: '',
            type: type,
            content: content,
            artist: artist,
            addedByUid: _myUid,
            addedAt: DateTime.now(),
          ),
        );
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AuraTheme.textPrimary, fontSize: 14)),
      ),
    );
  }

  // ── SEARCH BAR ─────────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.search, size: 16, color: AuraTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'search songs, lyrics, messages…',
              hintStyle: TextStyle(
                  color: AuraTheme.textMuted, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
                color: AuraTheme.textPrimary, fontSize: 13),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
      ]),
    );
  }

  // ── RECAP CARD ─────────────────────────────────────────────────────

  Widget _recapCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          const Text('ai recap',
              style: TextStyle(
                  color: AuraTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _recapText = null),
            child: const Icon(Icons.close, size: 14,
                color: AuraTheme.textMuted),
          ),
        ]),
        const SizedBox(height: 6),
        _loadingRecap
            ? const SizedBox(
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(_recapText ?? '',
                style: const TextStyle(
                    fontSize: 13, color: AuraTheme.textPrimary,
                    height: 1.5)),
      ]),
    );
  }

  // ── MESSAGE LIST ───────────────────────────────────────────────────

  Widget _buildMessageList() {
    return StreamBuilder<List<DmMessage>>(
      stream: _svc.messagesStream(_cid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2));
        }
        var messages = snap.data ?? [];

        // Filter by search
        if (_showSearch && _searchQuery.isNotEmpty) {
          messages = messages.where((m) {
            final preview = _msgPreview(m).toLowerCase();
            return preview.contains(_searchQuery) ||
                (m.text?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        // Mark all as read + generate smart replies for last incoming message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _svc.markAllRead(
            _cid,
            messages,
            nowPlayingSong: AudioPlayerService.i.currentTitle,
          );
          final lastIncoming = messages.lastOrNull;
          if (lastIncoming != null && lastIncoming.senderId != _myUid) {
            _generateSmartReplies(lastIncoming);
          }
        });

        if (messages.isEmpty) return _emptyState();

        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];
            return _MessageWrapper(
              msg: msg,
              isMe: msg.senderId == _myUid,
              accent: _accent,
              otherName: widget.otherName,
              onReply: () => setState(() => _replyingTo = msg),
              onPin: () => _svc.togglePin(_cid, msg.id, msg.isPinned),
              onDelete: () => _svc.deleteMessage(_cid, msg.id),
              onVote: (optionId) => _svc.votePoll(
                cid: _cid,
                msgId: msg.id,
                optionId: optionId,
                currentMsg: msg,
              ),
              onGuess: (guess) => _svc.submitGuess(
                cid: _cid,
                msgId: msg.id,
                data: msg.guessSongData!,
                guess: guess,
              ),
              onRevealGuess: () => _svc.revealGuessSong(_cid, msg.id),
              onViewOnce: () => _svc.markViewOnceViewed(_cid, msg.id),
              myUid: _myUid,
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('💬', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('start something with ${widget.otherName}',
            style: const TextStyle(
                color: AuraTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _showAttachmentPicker = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_circle_outline, color: _accent, size: 16),
              const SizedBox(width: 6),
              Text('send something',
                  style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── REPLY PREVIEW ──────────────────────────────────────────────────

  Widget _replyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AuraTheme.card,
      child: Row(children: [
        Container(width: 3, height: 36, color: _accent,
            margin: const EdgeInsets.only(right: 8)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('replying to ${_replyingTo!.senderId == _myUid ? 'yourself' : widget.otherName}',
                style: TextStyle(
                    fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
            Text(_msgPreview(_replyingTo!),
                style: const TextStyle(
                    fontSize: 12, color: AuraTheme.textMuted),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => _replyingTo = null),
          child: const Icon(Icons.close, size: 18, color: AuraTheme.textMuted),
        ),
      ]),
    );
  }

  // ── ATTACHMENT PICKER ──────────────────────────────────────────────

  Widget _attachmentPicker() {
    final items = [
      _AttachItem('🎤', 'voice note', _sendDemoVoiceNote),
      _AttachItem('🎲', 'guess song', _sendGuessSong),
      _AttachItem('📊', 'music poll', _sendMusicPoll),
      _AttachItem('🎵', 'song clip', () => Navigator.pop(context)),
      _AttachItem('💬', 'lyric', _sendLyric),
      _AttachItem('📍', 'location', _sendLocation),
      _AttachItem('👁', 'view once', _sendViewOnce),
      _AttachItem('🎨', 'gif/sticker', () {}),
      _AttachItem('✏️', 'doodle', _openDoodleCanvas),
      _AttachItem('🖌️', 'whiteboard', _openWhiteboardCanvas),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      color: AuraTheme.card,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('send something',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showAttachmentPicker = false),
            child: const Icon(Icons.close, size: 18, color: AuraTheme.textMuted),
          ),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: items.map((item) => _attachBtn(item)).toList(),
        ),
      ]),
    );
  }

  Widget _attachBtn(_AttachItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Text(item.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(item.label,
              style: const TextStyle(
                  fontSize: 10, color: AuraTheme.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── INPUT BAR ──────────────────────────────────────────────────────

  Widget _inputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AuraTheme.card,
        image: _bgImagePath != null
            ? null
            : null, // bg handled at Scaffold level
      ),
      padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 6,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Smart reply chips ──
        if (_smartReplies.isNotEmpty || _loadingReplies)
          _smartReplyRow(),

        // ── Tone shifter vibe row ──
        if (_ctrl.text.isNotEmpty || _activeVibe != null)
          _toneShifterRow(),

        // ── Main input row ──
        Row(children: [
          GestureDetector(
            onTap: () => setState(() =>
                _showAttachmentPicker = !_showAttachmentPicker),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: _accent, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'message…',
                border: InputBorder.none,
                filled: false,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              onChanged: (v) {
                // Show vibe row as soon as they type
                if (v.isNotEmpty && _activeVibe == null) setState(() {});
                // Reset vibe if user edits after rewrite
                if (_activeVibe != null) {
                  setState(() {
                    _activeVibe = null;
                    _originalDraft = null;
                  });
                }
              },
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: _sendDemoVoiceNote,
            onTap: _sendText,
            child: _rewriting
                ? SizedBox(
                    width: 38, height: 38,
                    child: CircularProgressIndicator(
                        color: _accent, strokeWidth: 2))
                : Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: _accent, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 16),
                  ),
          ),
        ]),
      ]),
    );
  }

  Widget _smartReplyRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 6, right: 4),
        children: _loadingReplies
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 90,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ]
            : _smartReplies.map((reply) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _ctrl.text = reply;
                      _ctrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: reply.length));
                      _smartReplies = [];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _accent.withOpacity(0.3), width: 0.5),
                    ),
                    child: Text(
                      reply,
                      style: TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }

  Widget _toneShifterRow() {
    const vibes = [
      ('fire', '🔥', 'fire'),
      ('tender', '💜', 'tender'),
      ('mysterious', '🌙', 'mysterious'),
      ('chill', '🧊', 'chill'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        ...vibes.map((v) {
          final isActive = _activeVibe == v.$1;
          return GestureDetector(
            onTap: _rewriting ? null : () => _rewriteWithTone(v.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? _accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? _accent.withOpacity(0.6)
                        : Colors.white.withOpacity(0.1),
                    width: 0.5),
              ),
              child: Text(
                '${v.$2} ${v.$3}',
                style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? _accent
                        : AuraTheme.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400),
              ),
            ),
          );
        }),
        if (_activeVibe != null)
          GestureDetector(
            onTap: _clearVibe,
            child: const Icon(Icons.close, size: 14,
                color: AuraTheme.textMuted),
          ),
      ]),
    );
  }

  // ── DIALOGS & PICKERS ──────────────────────────────────────────────

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('conversation theme',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 16),

          // ── Preset colour dots ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('accent colour',
                style: TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: DmTheme.presets.map((t) {
              final color = Color(
                  int.parse(t.hex.replaceFirst('#', ''), radix: 16) +
                      0xFF000000);
              final isActive = _themeColor == color;
              return GestureDetector(
                onTap: () {
                  _svc.setTheme(_cid, t.hex);
                  setState(() {
                    _themeColor = color;
                    _wallpaper = DmWallpaper.none;
                    _bgImagePath = null;
                  });
                  Navigator.pop(ctx);
                },
                child: Column(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: isActive
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(t.label,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 10)),
                ]),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Divider(color: AuraTheme.surface),
          const SizedBox(height: 12),

          // ── Custom colour ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('custom colour',
                style: TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          _ColorWheelRow(
            initialColor: _themeColor,
            onPicked: (color) {
              final hex =
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
              _svc.setTheme(_cid, hex);
              setState(() {
                _themeColor = color;
                _wallpaper = DmWallpaper.none;
                _bgImagePath = null;
              });
              Navigator.pop(ctx);
            },
          ),

          const SizedBox(height: 20),
          const Divider(color: AuraTheme.surface),
          const SizedBox(height: 12),

          // ── Wallpaper / background ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('chat wallpaper',
                style: TextStyle(
                    color: AuraTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          _themeActionBtn(
            icon: Icons.wallpaper_outlined,
            label: _wallpaper == DmWallpaper.none
                ? 'choose wallpaper'
                : _wallpaper.label,
            onTap: () {
              Navigator.pop(ctx);
              _openWallpaperPicker();
            },
          ),
          if (_wallpaper != DmWallpaper.none) ...[
            const SizedBox(height: 8),
            _themeActionBtn(
              icon: Icons.clear,
              label: 'remove wallpaper',
              onTap: () {
                setState(() {
                  _wallpaper = DmWallpaper.none;
                  _bgImagePath = null;
                });
                Navigator.pop(ctx);
              },
            ),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _svc.setTheme(_cid, null);
              setState(() {
                _themeColor = AuraTheme.accent;
                _wallpaper = DmWallpaper.none;
                _bgImagePath = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('reset to default',
                style: TextStyle(color: AuraTheme.textMuted)),
          ),
        ]),
      ),
    );
  }

  Widget _themeActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AuraTheme.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AuraTheme.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null || !mounted) return;
      setState(() {
        _bgImagePath = picked.path;
        _wallpaper = DmWallpaper.custom;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Could not open gallery. Make sure image_picker is in pubspec.yaml.')),
        );
      }
    }
  }

  void _openWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WallpaperPickerSheet(
        current: _wallpaper,
        currentImagePath: _bgImagePath,
        onPicked: (w, path) {
          setState(() {
            _wallpaper = w;
            _bgImagePath = (w == DmWallpaper.custom) ? path : null;
          });
        },
      ),
    );
  }

  void _showTimerPicker() {
    final options = [
      (null, 'off'),
      (86400, '24 hours'),
      (604800, '7 days'),
      (2592000, '30 days'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('disappearing messages',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 14),
          ...options.map((opt) => ListTile(
                title: Text(opt.$2,
                    style: const TextStyle(
                        color: AuraTheme.textPrimary, fontSize: 14)),
                trailing: _disappearAfterSecs == opt.$1
                    ? Icon(Icons.check, color: _accent)
                    : null,
                onTap: () {
                  _svc.setDisappearTimer(_cid, opt.$1);
                  Navigator.pop(context);
                },
              )),
        ]),
      ),
    );
  }

  void _showConcertDialog() {
    final controller = TextEditingController(
        text: _concertLabel ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AuraTheme.card,
        title: const Text('at a concert',
            style: TextStyle(color: AuraTheme.textPrimary)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Taylor Swift · Eras Tour',
            hintStyle: TextStyle(color: AuraTheme.textMuted),
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(color: AuraTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _svc.setConcertStatus(_cid, _myUid, null);
              Navigator.pop(context);
            },
            child: const Text('clear',
                style: TextStyle(color: AuraTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final val = controller.text.trim();
              _svc.setConcertStatus(
                  _cid, _myUid, val.isEmpty ? null : val);
              Navigator.pop(context);
            },
            child: Text('set',
                style: TextStyle(color: _accent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSchedulePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    final now = DateTime.now();
    var sched = DateTime(
        now.year, now.month, now.day, picked.hour, picked.minute);
    if (sched.isBefore(now)) {
      sched = sched.add(const Duration(days: 1)); // tomorrow
    }
    setState(() => _scheduledAt = sched);
  }
}

// ── Message wrapper (long-press menu) ─────────────────────────────────────────

class _MessageWrapper extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  final String otherName;
  final VoidCallback onReply;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final void Function(String) onVote;
  final void Function(String) onGuess;
  final VoidCallback onRevealGuess;
  final VoidCallback onViewOnce;
  final String myUid;

  const _MessageWrapper({
    required this.msg,
    required this.isMe,
    required this.accent,
    required this.otherName,
    required this.onReply,
    required this.onPin,
    required this.onDelete,
    required this.onVote,
    required this.onGuess,
    required this.onRevealGuess,
    required this.onViewOnce,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = _buildBubble(context);
    final readReceipt = _buildReadReceipt();

    return Column(crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      // Reply-to quote
      if (msg.replyToId != null && msg.replyToPreview != null)
        _replyQuote(),
      // Bubble with long-press
      GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: bubble,
      ),
      // Read receipt (only for my last message)
      if (isMe && readReceipt != null) readReceipt,
      const SizedBox(height: 4),
    ]);
  }

  Widget _replyQuote() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3, left: 12, right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: accent, width: 2),
          ),
        ),
        child: Text(
          msg.replyToPreview!,
          style: const TextStyle(fontSize: 11, color: AuraTheme.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget? _buildReadReceipt() {
    final others = msg.readBy.values
        .where((r) => r.uid != myUid)
        .toList();
    if (others.isEmpty) return null;
    final r = others.last;
    final timeStr =
        '${r.at.hour.toString().padLeft(2, '0')}:${r.at.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 2),
      child: Text(
        r.songPlaying != null
            ? 'read $timeStr · while listening to ${r.songPlaying}'
            : 'read $timeStr',
        style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ctxItem(context, Icons.reply_rounded, 'reply', onReply),
          _ctxItem(context, Icons.push_pin_rounded,
              msg.isPinned ? 'unpin' : 'pin', onPin),
          if (isMe)
            _ctxItem(context, Icons.delete_outline, 'delete', onDelete,
                color: Colors.redAccent),
        ]),
      ),
    );
  }

  Widget _ctxItem(BuildContext ctx, IconData icon, String label,
      VoidCallback action, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AuraTheme.textPrimary, size: 20),
      title: Text(label,
          style: TextStyle(
              color: color ?? AuraTheme.textPrimary, fontSize: 14)),
      onTap: () {
        Navigator.pop(ctx);
        action();
      },
    );
  }

  Widget _buildBubble(BuildContext context) {
    switch (msg.type) {
      case DmMsgType.text:
        return _TextBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.voiceNote:
        return _VoiceNoteBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.clip:
        return _ClipBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.guessSong:
        return _GuessSongBubble(
            msg: msg, isMe: isMe, accent: accent,
            onGuess: onGuess, onReveal: onRevealGuess, myUid: myUid);
      case DmMsgType.poll:
        return _PollBubble(msg: msg, isMe: isMe, accent: accent,
            onVote: onVote, myUid: myUid);
      case DmMsgType.lyric:
        return _LyricBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.location:
        return _LocationBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.viewOnce:
        return _ViewOnceBubble(msg: msg, isMe: isMe, accent: accent,
            myUid: myUid, onView: onViewOnce);
      case DmMsgType.gif:
      case DmMsgType.sticker:
        return _GifBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.doodle:
        return _DoodleBubble(msg: msg, isMe: isMe, accent: accent);
      case DmMsgType.whiteboard:
        return _WhiteboardBubble(msg: msg, isMe: isMe, accent: accent);
      default:
        return _TextBubble(
            msg: DmMessage(
              id: msg.id, type: DmMsgType.text,
              senderId: msg.senderId,
              createdAt: msg.createdAt,
              text: '[${msg.type.name}]',
            ),
            isMe: isMe,
            accent: accent);
    }
  }
}

// ── BUBBLE TYPES ───────────────────────────────────────────────────────────────

// Shared decoration helper
BoxDecoration _bubbleDeco(bool isMe, Color accent) => BoxDecoration(
      color: isMe ? accent : AuraTheme.card,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4 : 18),
      ),
    );

// ── Text ──
class _TextBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _TextBubble({required this.msg, required this.isMe, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: _bubbleDeco(isMe, accent),
        child: Text(
          msg.text ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : AuraTheme.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Voice Note ──
class _VoiceNoteBubble extends StatefulWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _VoiceNoteBubble(
      {required this.msg, required this.isMe, required this.accent});

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> {
  final _player = AudioPlayer();
  bool _playing = false;
  double _progress = 0;
  Timer? _ticker;

  List<double> get _wave => widget.msg.waveform?.take(36).toList() ??
      List.generate(36, (_) => 0.5);
  double get _dur => widget.msg.voiceDuration ?? 12.0;

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      _ticker?.cancel();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final url = widget.msg.voiceUrl;
    setState(() { _playing = true; _progress = 0; });
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _progress =
            (_progress + 0.08 / _dur).clamp(0.0, 1.0);
        if (_progress >= 1.0) {
          _playing = false;
          _progress = 0;
          _ticker?.cancel();
        }
      });
    });

    if (url != null && url.isNotEmpty) {
      try {
        await _player.setUrl(url);
        await _player.play();
      } catch (_) {}
    }
  }

  String _fmt(double s) =>
      '${s.round() ~/ 60}:${(s.round() % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = widget.accent;
    final isMe = widget.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 240,
        padding: const EdgeInsets.all(10),
        decoration: _bubbleDeco(isMe, color),
        child: Row(children: [
          // Play/pause
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : color,
                  size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Waveform
              SizedBox(
                height: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _wave.asMap().entries.map((e) {
                    final idx = e.key / _wave.length;
                    final played = idx <= _progress && _playing;
                    return Expanded(
                      child: Container(
                        height: e.value * 22 + 3,
                        margin: const EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(
                          color: played
                              ? (isMe ? Colors.white : color)
                              : (isMe
                                  ? Colors.white.withOpacity(0.35)
                                  : color.withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _playing
                    ? _fmt(_progress * _dur)
                    : _fmt(_dur),
                style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AuraTheme.textMuted),
              ),
            ]),
          ),
          // Mic icon
          const SizedBox(width: 6),
          Icon(Icons.mic_rounded,
              size: 14,
              color: isMe
                  ? Colors.white.withOpacity(0.5)
                  : color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}

// ── Song Clip ──
class _ClipBubble extends StatefulWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _ClipBubble(
      {required this.msg, required this.isMe, required this.accent});

  @override
  State<_ClipBubble> createState() => _ClipBubbleState();
}

class _ClipBubbleState extends State<_ClipBubble> {
  final _player = AudioPlayer();
  bool _playing = false;
  double _progress = 0;
  Timer? _ticker;

  double get _start => widget.msg.clipStart ?? 0;
  double get _end => widget.msg.clipEnd ?? 15;
  double get _dur => _end - _start;

  List<double> _wave = [];

  @override
  void initState() {
    super.initState();
    final rng = math.Random((widget.msg.songTitle ?? '').hashCode.abs());
    _wave = List.generate(28, (_) => 0.2 + rng.nextDouble() * 0.8);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      _ticker?.cancel();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() { _playing = true; _progress = 0; });
    _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _progress = (_progress + 0.08 / _dur).clamp(0.0, 1.0);
        if (_progress >= 1.0) {
          _playing = false; _progress = 0;
          _ticker?.cancel();
        }
      });
    });
    final url = widget.msg.previewUrl;
    if (url != null && url.isNotEmpty) {
      try {
        await _player.setUrl(url);
        await _player.seek(Duration(milliseconds: (_start * 1000).round()));
        await _player.play();
      } catch (_) {}
    }
  }

  String _fmt(double s) {
    final sec = s.round();
    return '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final color = widget.accent;
    final artUrl = widget.msg.artUrl;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 230,
        decoration: BoxDecoration(
          color: isMe ? color.withOpacity(0.12) : AuraTheme.card,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Song info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: artUrl != null && artUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: artUrl,
                        width: 34, height: 34, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _artHolder(color))
                    : _artHolder(color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.msg.songTitle ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(widget.msg.artist ?? '',
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          // Waveform
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _wave.asMap().entries.map((e) {
                  final played = e.key / _wave.length <= _progress && _playing;
                  return Expanded(
                    child: Container(
                      height: e.value * 22 + 2,
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        color: played ? color : color.withOpacity(0.3),
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
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${_fmt(_start)} – ${_fmt(_end)}  ·  ${_dur.round()}s clip',
                      style: const TextStyle(
                          fontSize: 9, color: AuraTheme.textMuted)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _artHolder(Color color) => Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.music_note_rounded, color: color, size: 16),
      );
}

// ── Guess the Song ──
class _GuessSongBubble extends StatefulWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  final void Function(String) onGuess;
  final VoidCallback onReveal;
  final String myUid;
  const _GuessSongBubble(
      {required this.msg, required this.isMe, required this.accent,
       required this.onGuess, required this.onReveal, required this.myUid});

  @override
  State<_GuessSongBubble> createState() => _GuessSongBubbleState();
}

class _GuessSongBubbleState extends State<_GuessSongBubble> {
  final _ctrl = TextEditingController();
  bool _playing = false;
  Timer? _stopTimer;

  DmGuessSongData? get _data => widget.msg.guessSongData;
  bool get _iGuessed => _data?.guesses.containsKey(widget.myUid) ?? false;
  bool get _iCorrect => _data?.correct[widget.myUid] ?? false;
  bool get _revealed => _data?.revealed ?? false;

  @override
  void dispose() {
    _ctrl.dispose();
    _stopTimer?.cancel();
    super.dispose();
  }

  void _playClip() {
    if (_playing) return;
    setState(() => _playing = true);
    _stopTimer = Timer(
        Duration(
            milliseconds:
                (((widget.msg.guessSongData?.clipEnd ?? 3) -
                            (widget.msg.guessSongData?.clipStart ?? 0)) *
                        1000)
                    .round()),
        () { if (mounted) setState(() => _playing = false); });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent;
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('🎲', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(_revealed ? 'revealed!' : 'guess the song',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),

          // Play 3s clip button
          GestureDetector(
            onTap: _playClip,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    _playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                    color: color, size: 18),
                const SizedBox(width: 6),
                Text(_playing ? 'playing 3s clip…' : 'play 3s clip',
                    style: TextStyle(color: color, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 10),

          if (_revealed) ...[
            // Revealed answer
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.songTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text(data.artist,
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 12)),
              ]),
            ),
            if (_iGuessed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _iCorrect ? '✅ you got it!' : '❌ better luck next time',
                  style: TextStyle(
                      fontSize: 12,
                      color: _iCorrect
                          ? const Color(0xFF1D9E75)
                          : Colors.redAccent),
                ),
              ),
          ] else ...[
            // Guess input
            if (!_iGuessed && !widget.isMe) ...[
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'your guess…',
                      hintStyle: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: color.withOpacity(0.3))),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(
                        color: AuraTheme.textPrimary, fontSize: 13),
                    onSubmitted: (v) {
                      if (v.trim().isEmpty) return;
                      widget.onGuess(v.trim());
                    },
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    final g = _ctrl.text.trim();
                    if (g.isEmpty) return;
                    widget.onGuess(g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(8)),
                    child: const Text('guess',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ] else if (_iGuessed) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('you guessed: ${data.guesses[widget.myUid]}',
                    style: const TextStyle(
                        fontSize: 12, color: AuraTheme.textMuted)),
              ),
            ] else ...[
              // I sent it — show reveal button
              GestureDetector(
                onTap: widget.onReveal,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text('reveal answer',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ),
            ],
            // Show others' guesses
            if (data.guesses.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...data.guesses.entries.map((e) => Text(
                    '${e.key == widget.myUid ? 'you' : 'them'}: ${e.value} '
                    '${data.correct[e.key] == true ? '✅' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: AuraTheme.textMuted),
                  )),
            ],
          ],
        ]),
      ),
    );
  }
}

// ── Music Poll ──
class _PollBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  final void Function(String) onVote;
  final String myUid;
  const _PollBubble(
      {required this.msg, required this.isMe, required this.accent,
       required this.onVote, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final options = msg.pollOptions ?? [];
    final totalVotes =
        options.fold<int>(0, (sum, o) => sum + o.voterUids.length);
    final myVote = options
        .where((o) => o.voterUids.contains(myUid))
        .map((o) => o.id)
        .firstOrNull;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📊', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(msg.pollQuestion ?? 'poll',
                  style: const TextStyle(
                      color: AuraTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ]),
          const SizedBox(height: 10),
          ...options.map((opt) {
            final votes = opt.voterUids.length;
            final frac = totalVotes == 0 ? 0.0 : votes / totalVotes;
            final isMyVote = opt.id == myVote;

            return GestureDetector(
              onTap: msg.pollClosed ? null : () => onVote(opt.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: Stack(children: [
                  // Progress bar background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 40,
                      backgroundColor: AuraTheme.surface,
                      valueColor: AlwaysStoppedAnimation(
                          const Color(0xFF1D9E75).withOpacity(0.25)),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Row(children: [
                      if (opt.artUrl != null && opt.artUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                                imageUrl: opt.artUrl!,
                                width: 20, height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(width: 20)),
                          ),
                        ),
                      Expanded(
                        child: Text(opt.label,
                            style: TextStyle(
                                color: AuraTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: isMyVote
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ),
                      Text('$votes',
                          style: const TextStyle(
                              color: AuraTheme.textMuted, fontSize: 12)),
                      if (isMyVote)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.check_circle,
                              color: const Color(0xFF1D9E75), size: 14),
                        ),
                    ]),
                  ),
                ]),
              ),
            );
          }),
          Text('$totalVotes vote${totalVotes == 1 ? '' : 's'}',
              style: const TextStyle(
                  fontSize: 10, color: AuraTheme.textMuted)),
        ]),
      ),
    );
  }
}

// ── Lyric ──
class _LyricBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _LyricBubble(
      {required this.msg, required this.isMe, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B0F1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7F77DD).withOpacity(0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('"', style: TextStyle(color: Color(0xFF7F77DD),
              fontSize: 28, height: 0.8)),
          const SizedBox(height: 4),
          Text(
            msg.lyricText ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(children: [
            if (msg.artUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                    imageUrl: msg.artUrl!,
                    width: 24, height: 24, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 24)),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(msg.lyricSong ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(msg.lyricArtist ?? '',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Location ──
class _LocationBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _LocationBubble(
      {required this.msg, required this.isMe, required this.accent});

  bool get _active {
    final exp = msg.locationExpiresAt;
    return exp == null || DateTime.now().isBefore(exp);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: 240,
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.accent.withOpacity(0.35)),
        ),
        child: Column(children: [
          // Mini map SVG-style
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 100,
              color: const Color(0xFF0D1B2A),
              child: CustomPaint(
                painter: _LocationMapPainter(accent: widget.accent),
                child: Container(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Icon(Icons.location_on_rounded,
                  color: widget.accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('live location',
                      style: TextStyle(
                          color: widget.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  Text(
                    _active
                        ? 'active · expires in 1h'
                        : 'expired',
                    style: const TextStyle(
                        color: AuraTheme.textMuted, fontSize: 10),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LocationMapPainter extends CustomPainter {
  final Color accent;
  const _LocationMapPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.5;
    for (var i = 0.0; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (var i = 0.0; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Dashed thread from me (bottom-left) to them (top-right)
    final myPos = Offset(cx - 40, cy + 20);
    final theirPos = Offset(cx + 40, cy - 20);
    final dashPaint = Paint()
      ..color = accent.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    _drawDashed(canvas, myPos, theirPos, dashPaint);

    // My dot
    canvas.drawCircle(myPos, 7,
        Paint()..color = accent);
    canvas.drawCircle(myPos, 4,
        Paint()..color = Colors.white);

    // Their dot
    canvas.drawCircle(theirPos, 7,
        Paint()..color = const Color(0xFF7F77DD));
    canvas.drawCircle(theirPos, 4,
        Paint()..color = Colors.white);
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    final d = (end - start).distance;
    final steps = (d / 8).round();
    for (var i = 0; i < steps; i++) {
      if (i % 2 == 0) {
        final t1 = i / steps;
        final t2 = (i + 1) / steps;
        canvas.drawLine(
            Offset.lerp(start, end, t1)!,
            Offset.lerp(start, end, t2)!,
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_LocationMapPainter old) => false;
}

// ── View Once ──
class _ViewOnceBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  final String myUid;
  final VoidCallback onView;
  const _ViewOnceBubble(
      {required this.msg, required this.isMe, required this.accent,
       required this.myUid, required this.onView});

  bool get _viewed => msg.viewedByUids.contains(myUid);

  @override
  Widget build(BuildContext context) {
    final shouldHide = !isMe && _viewed;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: (!isMe && !_viewed) ? () { onView(); } : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: shouldHide
                ? AuraTheme.surface
                : (isMe ? accent.withOpacity(0.12) : AuraTheme.card),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              shouldHide ? Icons.visibility_off_rounded : Icons.remove_red_eye_rounded,
              color: shouldHide ? AuraTheme.textMuted : accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              shouldHide
                  ? 'opened · gone now'
                  : isMe
                      ? 'view once sent'
                      : 'tap to view once',
              style: TextStyle(
                  color: shouldHide
                      ? AuraTheme.textMuted
                      : (isMe ? accent : AuraTheme.textPrimary),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── GIF / Sticker ──
class _GifBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;
  const _GifBubble(
      {required this.msg, required this.isMe, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isSticker = msg.isSticker;
    // Real: use GIPHY SDK to render from msg.giphyId
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        width: isSticker ? 100 : 180,
        height: isSticker ? 100 : 140,
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(isSticker ? Icons.emoji_emotions_outlined : Icons.gif_rounded,
              color: accent.withOpacity(0.4), size: isSticker ? 48 : 56),
          Positioned(
            top: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: isSticker ? Colors.transparent : Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(isSticker ? '🪄' : 'GIF',
                  style: TextStyle(
                      color: isSticker ? Colors.white : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Data class for attachment picker ──────────────────────────────────────────
class _AttachItem {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _AttachItem(this.emoji, this.label, this.onTap);
}

// ═════════════════════════════════════════════════════════════════════════════
// DOODLE BUBBLE — renders stored strokes
// ═════════════════════════════════════════════════════════════════════════════

class _DoodleBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;

  const _DoodleBubble(
      {required this.msg, required this.isMe, required this.accent});

  Color get _strokeColor {
    final hex = msg.doodleColor;
    if (hex == null || hex.isEmpty) return accent;
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strokes = msg.doodleStrokes ?? [];
    return Container(
      constraints: const BoxConstraints(maxWidth: 240, minWidth: 120),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _strokeColor.withOpacity(0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 220,
          height: 180,
          child: strokes.isEmpty
              ? Center(
                  child: Text('empty doodle',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11)))
              : CustomPaint(
                  painter: _DoodleReplayPainter(
                      strokes: strokes, color: _strokeColor),
                ),
        ),
      ),
    );
  }
}

class _DoodleReplayPainter extends CustomPainter {
  final List<List<Map<String, double>>> strokes;
  final Color color;

  const _DoodleReplayPainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from normalised coords (0–1) to canvas size
    canvas.drawRect(Offset.zero & size,
        Paint()..color = Colors.black.withOpacity(0.0));

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path();
      path.moveTo(
          (stroke.first['x'] ?? 0) * size.width,
          (stroke.first['y'] ?? 0) * size.height);
      for (final pt in stroke.skip(1)) {
        path.lineTo(
            (pt['x'] ?? 0) * size.width, (pt['y'] ?? 0) * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DoodleReplayPainter old) =>
      old.strokes != strokes || old.color != color;
}

// ═════════════════════════════════════════════════════════════════════════════
// DOODLE SHEET — draw with finger, then send
// ═════════════════════════════════════════════════════════════════════════════

class _DoodleSheet extends StatefulWidget {
  final Color accentColor;
  final Future<void> Function(List<List<Map<String, double>>> strokes) onSend;

  const _DoodleSheet({required this.accentColor, required this.onSend});

  @override
  State<_DoodleSheet> createState() => _DoodleSheetState();
}

class _DoodleSheetState extends State<_DoodleSheet> {
  final List<List<Offset>> _rawStrokes = [];  // raw pixel coords
  List<Offset> _currentStroke = [];
  double _strokeWidth = 3.0;
  bool _sending = false;

  // Canvas logical size (set in LayoutBuilder)
  Size _canvasSize = const Size(320, 320);

  void _onPanStart(DragStartDetails d) {
    _currentStroke = [d.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentStroke.length > 1) {
      _rawStrokes.add(List.from(_currentStroke));
    }
    _currentStroke = [];
  }

  void _undo() {
    if (_rawStrokes.isNotEmpty) setState(() => _rawStrokes.removeLast());
  }

  void _clear() => setState(() { _rawStrokes.clear(); _currentStroke = []; });

  Future<void> _send() async {
    if (_rawStrokes.isEmpty) return;
    setState(() => _sending = true);

    // Normalise coords to 0–1 range so they scale to any screen size
    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final normalised = _rawStrokes.map((stroke) =>
        stroke.map((pt) => {
              'x': (pt.dx / w).clamp(0.0, 1.0),
              'y': (pt.dy / h).clamp(0.0, 1.0),
            }).toList()).toList();

    await widget.onSend(normalised);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('doodle',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const Spacer(),
            // Stroke width selector
            _StrokeWidthBtn(
                current: _strokeWidth, value: 2.0, label: '·',
                onTap: () => setState(() => _strokeWidth = 2.0)),
            const SizedBox(width: 6),
            _StrokeWidthBtn(
                current: _strokeWidth, value: 4.0, label: '–',
                onTap: () => setState(() => _strokeWidth = 4.0)),
            const SizedBox(width: 6),
            _StrokeWidthBtn(
                current: _strokeWidth, value: 7.0, label: '━',
                onTap: () => setState(() => _strokeWidth = 7.0)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white54, size: 20),
              onPressed: _rawStrokes.isNotEmpty ? _undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white54, size: 20),
              onPressed: _rawStrokes.isNotEmpty ? _clear : null,
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(builder: (_, constraints) {
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: widget.accentColor.withOpacity(0.3), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: CustomPaint(
                      painter: _LiveDoodlePainter(
                        strokes: _rawStrokes,
                        currentStroke: _currentStroke,
                        color: widget.accentColor,
                        strokeWidth: _strokeWidth,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Music doodle stickers row
        _MusicStickerRow(
          accentColor: widget.accentColor,
          onStickerChosen: (stickerStrokes) {
            setState(() => _rawStrokes.addAll(stickerStrokes));
          },
        ),

        // Send button
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending || _rawStrokes.isEmpty ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('send doodle',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Stroke width button ────────────────────────────────────────────────────────
class _StrokeWidthBtn extends StatelessWidget {
  final double current;
  final double value;
  final String label;
  final VoidCallback onTap;

  const _StrokeWidthBtn({
    required this.current,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = (current - value).abs() < 0.1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withOpacity(active ? 0.4 : 0.15),
              width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

// ── Live doodle painter ────────────────────────────────────────────────────────
class _LiveDoodlePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;

  const _LiveDoodlePainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.length < 2) return;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) drawStroke(s);
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_LiveDoodlePainter old) => true;
}

// ── Music sticker row — pre-drawn doodles the user can stamp onto canvas ──────
class _MusicStickerRow extends StatelessWidget {
  final Color accentColor;
  final void Function(List<List<Offset>> strokes) onStickerChosen;

  const _MusicStickerRow({
    required this.accentColor,
    required this.onStickerChosen,
  });

  // Pre-built sticker stroke sets (in 0–1 space; caller scales to canvas)
  // Each sticker is a list of strokes; each stroke is a list of Offsets (normalised)
  static List<List<List<Offset>>> get _stickers => [
    // ♪ note
    [
      [const Offset(0.3,0.7), const Offset(0.3,0.3)],
      [const Offset(0.3,0.3), const Offset(0.6,0.25)],
      [const Offset(0.6,0.25), const Offset(0.6,0.55)],
      [for (var i = 0; i <= 8; i++)
        Offset(0.28 + math.cos(i / 8 * 2 * math.pi) * 0.04,
               0.72 + math.sin(i / 8 * 2 * math.pi) * 0.025)],
      [for (var i = 0; i <= 8; i++)
        Offset(0.58 + math.cos(i / 8 * 2 * math.pi) * 0.04,
               0.57 + math.sin(i / 8 * 2 * math.pi) * 0.025)],
    ],
    // ♡ heart
    [
      [for (var i = 0; i <= 30; i++) () {
        final t = i / 30 * 2 * math.pi;
        return Offset(
          0.5 + 0.18 * math.sin(t) * math.sin(t) * math.sin(t),
          0.45 - 0.14 * (13*math.cos(t) - 5*math.cos(2*t)
              - 2*math.cos(3*t) - math.cos(4*t)) / 13,
        );
      }()],
    ],
    // ⭐ star (5-pointed)
    [
      [for (var i = 0; i <= 10; i++) () {
        final t = i / 10 * 2 * math.pi - math.pi / 2;
        final r = i.isEven ? 0.18 : 0.08;
        return Offset(0.5 + r * math.cos(t), 0.5 + r * math.sin(t));
      }()],
    ],
    // 〜〜 wave lines (music vibe)
    [
      [for (var i = 0; i <= 20; i++)
        Offset(0.15 + i / 20 * 0.7,
               0.4 + math.sin(i / 20 * 4 * math.pi) * 0.08)],
      [for (var i = 0; i <= 20; i++)
        Offset(0.15 + i / 20 * 0.7,
               0.6 + math.sin(i / 20 * 4 * math.pi + 1.0) * 0.06)],
    ],
    // ◯ vinyl / circle
    [
      [for (var i = 0; i <= 32; i++) () {
        final t = i / 32 * 2 * math.pi;
        return Offset(0.5 + 0.2 * math.cos(t), 0.5 + 0.2 * math.sin(t));
      }()],
      [for (var i = 0; i <= 16; i++) () {
        final t = i / 16 * 2 * math.pi;
        return Offset(0.5 + 0.1 * math.cos(t), 0.5 + 0.1 * math.sin(t));
      }()],
      [for (var i = 0; i <= 6; i++) () {
        final t = i / 6 * 2 * math.pi;
        return Offset(0.5 + 0.025 * math.cos(t), 0.5 + 0.025 * math.sin(t));
      }()],
    ],
  ];

  static const _labels = ['♪', '♡', '★', '〜', '⊙'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _stickers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () {
            // Scale normalised coords to 300×300 canvas-ish space (sender normalises later)
            final sized = _stickers[i]
                .map((stroke) =>
                    stroke.map((p) => Offset(p.dx * 220, p.dy * 180)).toList())
                .toList();
            onStickerChosen(sized);
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: accentColor.withOpacity(0.3), width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(_labels[i],
                style: TextStyle(
                    color: accentColor, fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WHITEBOARD BUBBLE — renders the received whiteboard
// ═════════════════════════════════════════════════════════════════════════════

class _WhiteboardBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isMe;
  final Color accent;

  const _WhiteboardBubble(
      {required this.msg, required this.isMe, required this.accent});

  @override
  Widget build(BuildContext context) {
    final data = msg.whiteboardData ?? [];
    return Container(
      constraints: const BoxConstraints(maxWidth: 260, minWidth: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 240,
          height: 190,
          child: data.isEmpty
              ? const Center(
                  child: Text('blank whiteboard',
                      style: TextStyle(color: Colors.black26, fontSize: 11)))
              : CustomPaint(
                  painter: _WhiteboardReplayPainter(data: data),
                ),
        ),
      ),
    );
  }
}

class _WhiteboardReplayPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  const _WhiteboardReplayPainter({required this.data});

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    for (final el in data) {
      final type = el['type'] as String? ?? 'stroke';
      final color = _parseHex(el['color'] as String?);
      final width = (el['width'] as num?)?.toDouble() ?? 3.0;

      if (type == 'text') {
        final text = el['text'] as String? ?? '';
        final tx = (el['tx'] as num?)?.toDouble() ?? 0.5;
        final ty = (el['ty'] as num?)?.toDouble() ?? 0.5;
        final fontSize = (el['fontSize'] as num?)?.toDouble() ?? 14.0;
        final span = TextSpan(
            text: text,
            style: TextStyle(
                color: color, fontSize: fontSize, fontFamily: 'sans-serif'));
        final tp = TextPainter(
            text: span, textDirection: TextDirection.ltr)
          ..layout(maxWidth: size.width * 0.9);
        tp.paint(canvas, Offset(tx * size.width, ty * size.height));
        continue;
      }

      // stroke or erase
      final isErase = type == 'erase';
      final paint = Paint()
        ..color = isErase ? Colors.white : color
        ..strokeWidth = isErase ? width * 3 : width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final rawPoints = el['points'] as List<dynamic>? ?? [];
      if (rawPoints.length < 2) continue;
      final pts = rawPoints
          .map((p) {
            final m = Map<String, dynamic>.from(p as Map);
            return Offset(
                (m['x'] as num).toDouble() * size.width,
                (m['y'] as num).toDouble() * size.height);
          })
          .toList();

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WhiteboardReplayPainter old) => old.data != data;
}

// ═════════════════════════════════════════════════════════════════════════════
// WHITEBOARD SHEET — full canvas: draw, write, paint, erase → send
// ═════════════════════════════════════════════════════════════════════════════

enum _WbTool { pen, eraser, text }

class _WhiteboardSheet extends StatefulWidget {
  final Future<void> Function(List<Map<String, dynamic>> data) onSend;
  const _WhiteboardSheet({required this.onSend});

  @override
  State<_WhiteboardSheet> createState() => _WhiteboardSheetState();
}

class _WhiteboardSheetState extends State<_WhiteboardSheet> {
  // Canvas elements (will be sent to Firestore)
  final List<Map<String, dynamic>> _elements = [];

  // Current stroke being drawn
  List<Offset> _current = [];

  // Tool state
  _WbTool _tool = _WbTool.pen;
  Color _color = Colors.black;
  double _strokeWidth = 3.0;
  double _fontSize = 16.0;

  // Text input
  bool _placingText = false;
  Offset _textPos = Offset.zero;
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  bool _sending = false;
  Size _canvasSize = const Size(300, 260);

  // Full-spectrum 20-colour palette + black/white
  static final List<Color> _palette = [
    Colors.black,
    Colors.white,
    ...List.generate(18, (i) =>
        HSVColor.fromAHSV(1.0, i * 20.0, 0.85, 0.92).toColor()),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (_tool == _WbTool.text) {
      _startTextPlacement(d.localPosition);
      return;
    }
    _current = [d.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_tool == _WbTool.text) return;
    setState(() => _current.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_tool == _WbTool.text) return;
    if (_current.length < 2) { _current = []; return; }

    final w = _canvasSize.width;
    final h = _canvasSize.height;
    final pts = _current
        .map((p) => {'x': p.dx / w, 'y': p.dy / h})
        .toList();

    final hex = '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
    setState(() {
      _elements.add({
        'type': _tool == _WbTool.eraser ? 'erase' : 'stroke',
        'color': hex,
        'width': _strokeWidth,
        'points': pts,
      });
      _current = [];
    });
  }

  void _onTap(TapDownDetails d) {
    if (_tool != _WbTool.text) return;
    _startTextPlacement(d.localPosition);
  }

  void _startTextPlacement(Offset pos) {
    setState(() {
      _placingText = true;
      _textPos = pos;
      _textCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
  }

  void _commitText() {
    final t = _textCtrl.text.trim();
    if (t.isNotEmpty) {
      final w = _canvasSize.width;
      final h = _canvasSize.height;
      final hex = '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
      setState(() {
        _elements.add({
          'type': 'text',
          'color': hex,
          'text': t,
          'fontSize': _fontSize,
          'tx': _textPos.dx / w,
          'ty': _textPos.dy / h,
        });
      });
    }
    setState(() { _placingText = false; });
    _textFocus.unfocus();
  }

  void _undo() {
    if (_elements.isNotEmpty) setState(() => _elements.removeLast());
  }

  void _clear() => setState(() { _elements.clear(); _current = []; });

  Future<void> _send() async {
    if (_elements.isEmpty) return;
    setState(() => _sending = true);
    await widget.onSend(List.from(_elements));
    if (mounted) Navigator.pop(context);
  }

  String get _toolHint {
    switch (_tool) {
      case _WbTool.pen:    return 'draw';
      case _WbTool.eraser: return 'erase';
      case _WbTool.text:   return 'tap to place text';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2)),
        ),

        // ── Toolbar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            // Tool buttons
            _WbToolBtn(
              icon: Icons.edit_outlined,
              label: 'pen',
              active: _tool == _WbTool.pen,
              onTap: () => setState(() { _tool = _WbTool.pen; _placingText = false; }),
            ),
            const SizedBox(width: 6),
            _WbToolBtn(
              icon: Icons.text_fields,
              label: 'text',
              active: _tool == _WbTool.text,
              onTap: () => setState(() { _tool = _WbTool.text; }),
            ),
            const SizedBox(width: 6),
            _WbToolBtn(
              icon: Icons.auto_fix_normal,
              label: 'erase',
              active: _tool == _WbTool.eraser,
              onTap: () => setState(() { _tool = _WbTool.eraser; _placingText = false; }),
            ),

            const SizedBox(width: 10),
            // Stroke / font size
            if (_tool == _WbTool.text) ...[
              _SizeBtn(label: 'S', active: _fontSize < 14, onTap: () => setState(() => _fontSize = 11)),
              const SizedBox(width: 4),
              _SizeBtn(label: 'M', active: _fontSize >= 14 && _fontSize < 22, onTap: () => setState(() => _fontSize = 16)),
              const SizedBox(width: 4),
              _SizeBtn(label: 'L', active: _fontSize >= 22, onTap: () => setState(() => _fontSize = 26)),
            ] else ...[
              _SizeBtn(label: '·', active: _strokeWidth < 3, onTap: () => setState(() => _strokeWidth = 1.5)),
              const SizedBox(width: 4),
              _SizeBtn(label: '–', active: _strokeWidth >= 3 && _strokeWidth < 7, onTap: () => setState(() => _strokeWidth = 4.0)),
              const SizedBox(width: 4),
              _SizeBtn(label: '━', active: _strokeWidth >= 7, onTap: () => setState(() => _strokeWidth = 9.0)),
            ],

            const Spacer(),
            IconButton(
              onPressed: _elements.isNotEmpty ? _undo : null,
              icon: Icon(Icons.undo,
                  color: _elements.isNotEmpty
                      ? Colors.white70 : Colors.white24, size: 20),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _elements.isNotEmpty ? _clear : null,
              icon: Icon(Icons.delete_outline,
                  color: _elements.isNotEmpty
                      ? Colors.white70 : Colors.white24, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ]),
        ),

        // ── Color palette ─────────────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final c = _palette[i];
              final active = _color == c;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: active ? 32 : 26,
                  height: active ? 32 : 26,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: active ? Colors.white : Colors.white24,
                        width: active ? 2.5 : 1),
                    boxShadow: active
                        ? [BoxShadow(
                            color: c.withOpacity(0.5),
                            blurRadius: 6)]
                        : [],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // ── Canvas ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(builder: (_, constraints) {
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapDown: _tool == _WbTool.text ? _onTap : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(children: [
                      // Painted content
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WhiteboardLivePainter(
                            committed: _elements,
                            current: _current,
                            currentColor: _color,
                            currentWidth: _strokeWidth,
                            isErase: _tool == _WbTool.eraser,
                          ),
                        ),
                      ),
                      // Text placement overlay
                      if (_placingText) ...[
                        Positioned.fill(
                          child: Container(color: Colors.transparent),
                        ),
                        Positioned(
                          left: _textPos.dx,
                          top: _textPos.dy,
                          child: IntrinsicWidth(
                            child: TextField(
                              controller: _textCtrl,
                              focusNode: _textFocus,
                              style: TextStyle(
                                  color: _color,
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'type here…',
                                hintStyle: TextStyle(
                                    color: _color.withOpacity(0.35),
                                    fontSize: _fontSize),
                              ),
                              onSubmitted: (_) => _commitText(),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ),
                      ],
                      // Hint text
                      if (_elements.isEmpty && _current.isEmpty && !_placingText)
                        Center(
                          child: Text(_toolHint,
                              style: const TextStyle(
                                  color: Colors.black12,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic)),
                        ),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Text commit bar (shown while placing text) ────────────
        if (_placingText)
          Container(
            color: const Color(0xFF1A1A2A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Text('tap on whiteboard to reposition, then press ✓',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ),
              GestureDetector(
                onTap: _commitText,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✓ place',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ]),
          ),

        // ── Send button ───────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending || _elements.isEmpty ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('send whiteboard',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Whiteboard live painter ────────────────────────────────────────────────────
class _WhiteboardLivePainter extends CustomPainter {
  final List<Map<String, dynamic>> committed;
  final List<Offset> current;
  final Color currentColor;
  final double currentWidth;
  final bool isErase;

  const _WhiteboardLivePainter({
    required this.committed,
    required this.current,
    required this.currentColor,
    required this.currentWidth,
    required this.isErase,
  });

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    try {
      return Color(
          int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000);
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Draw committed elements
    for (final el in committed) {
      final type = el['type'] as String? ?? 'stroke';
      final color = _parseHex(el['color'] as String?);
      final width = (el['width'] as num?)?.toDouble() ?? 3.0;

      if (type == 'text') {
        final tx = (el['tx'] as num?)?.toDouble() ?? 0.0;
        final ty = (el['ty'] as num?)?.toDouble() ?? 0.0;
        final fontSize = (el['fontSize'] as num?)?.toDouble() ?? 14.0;
        final span = TextSpan(
            text: el['text'] as String? ?? '',
            style: TextStyle(
                color: color, fontSize: fontSize));
        final tp = TextPainter(
            text: span, textDirection: TextDirection.ltr)
          ..layout(maxWidth: size.width);
        tp.paint(canvas, Offset(tx * size.width, ty * size.height));
        continue;
      }

      final isEr = type == 'erase';
      final paint = Paint()
        ..color = isEr ? Colors.white : color
        ..strokeWidth = isEr ? width * 3 : width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final rawPts = (el['points'] as List<dynamic>? ?? [])
          .map((p) {
            final m = Map<String, dynamic>.from(p as Map);
            return Offset(
                (m['x'] as num).toDouble() * size.width,
                (m['y'] as num).toDouble() * size.height);
          })
          .toList();

      if (rawPts.length < 2) continue;
      final path = Path()..moveTo(rawPts.first.dx, rawPts.first.dy);
      for (final p in rawPts.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    }

    // Draw live stroke in progress
    if (current.length >= 2) {
      final paint = Paint()
        ..color = isErase ? Colors.white : currentColor
        ..strokeWidth = isErase ? currentWidth * 3 : currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current.first.dx, current.first.dy);
      for (final p in current.skip(1)) path.lineTo(p.dx, p.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WhiteboardLivePainter old) => true;
}

// ── Tool button ────────────────────────────────────────────────────────────────
class _WbToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _WbToolBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active ? Colors.white : Colors.white54, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}

// ── Size button ────────────────────────────────────────────────────────────────
class _SizeBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SizeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.white.withOpacity(active ? 0.4 : 0.15),
              width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 14)),
      ),
    );
  }
}

// ── Custom colour wheel ────────────────────────────────────────────────────────
// A row of 20 hue swatches spanning the full spectrum + a custom HSV picker.
class _ColorWheelRow extends StatefulWidget {
  final Color initialColor;
  final void Function(Color) onPicked;
  const _ColorWheelRow({required this.initialColor, required this.onPicked});

  @override
  State<_ColorWheelRow> createState() => _ColorWheelRowState();
}

class _ColorWheelRowState extends State<_ColorWheelRow> {
  late Color _selected;

  // 20 hue stops across the full 360° wheel
  static final List<Color> _hues = List.generate(20, (i) {
    final hue = i * 18.0;
    return HSVColor.fromAHSV(1.0, hue, 0.85, 0.9).toColor();
  });

  @override
  void initState() {
    super.initState();
    _selected = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hue strip
      SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _hues.length,
          itemBuilder: (_, i) {
            final c = _hues[i];
            final isSelected = _selected == c;
            return GestureDetector(
              onTap: () { setState(() => _selected = c); widget.onPicked(c); },
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      // Saturation / brightness strip for the selected hue
      Builder(builder: (_) {
        final hsv = HSVColor.fromColor(_selected);
        return Row(children: [
          const Text('brightness',
              style: TextStyle(
                  fontSize: 10, color: AuraTheme.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: hsv.value,
                    min: 0.3,
                    max: 1.0,
                    activeColor: _selected,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (v) {
                      final updated =
                          hsv.withValue(v).withSaturation(0.85).toColor();
                      setState(() => _selected = updated);
                    },
                    onChangeEnd: (v) {
                      final updated =
                          hsv.withValue(v).withSaturation(0.85).toColor();
                      widget.onPicked(updated);
                    },
                  ),
                ),
              ),
            ),
          ),
        ]);
      }),
    ]);
  }
}
