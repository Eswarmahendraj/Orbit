import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sound Rooms — live co-listening rooms (like Clubhouse for music)
// Host controls the queue. Everyone hears the same song together.
// Firestore real-time sync: sound_rooms/{id}
// ─────────────────────────────────────────────────────────────────────────────

// ──────────────── Browse / Create Rooms ─────────────────────────────────────

class SoundRoomListScreen extends StatelessWidget {
  const SoundRoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('sound rooms 🎙️',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AuraTheme.accent),
            onPressed: () => _showCreateRoom(context, uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sound_rooms')
            .where('isLive', isEqualTo: true)
            .orderBy('listenerCount', descending: true)
            .limit(20)
            .snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🎙️', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Text('no live rooms right now',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 16)),
                const SizedBox(height: 6),
                Text('be the first to start one',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _showCreateRoom(context, uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraTheme.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('start a room',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _RoomCard(roomId: docs[i].id, data: data, myUid: uid);
            },
          );
        },
      ),
    );
  }

  void _showCreateRoom(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateRoomSheet(uid: uid),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic> data;
  final String myUid;
  const _RoomCard(
      {required this.roomId, required this.data, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Sound Room';
    final hostName = data['hostName'] as String? ?? 'Host';
    final currentSong = data['currentSong'] as String? ?? '';
    final currentArtist = data['currentArtist'] as String? ?? '';
    final artUrl = data['currentArtUrl'] as String?;
    final count = data['listenerCount'] as int? ?? 0;
    final vibe = data['vibe'] as String? ?? '🎵';

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SoundRoomScreen(roomId: roomId))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AuraTheme.accent.withOpacity(0.15), width: 1),
        ),
        child: Row(children: [
          // Art or vibe emoji
          if (artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                  imageUrl: artUrl, width: 56, height: 56, fit: BoxFit.cover),
            )
          else
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(vibe, style: const TextStyle(fontSize: 26))),
            ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              const _LivePulse(),
              const SizedBox(width: 6),
              Expanded(child: Text(name,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text('hosted by $hostName',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
            if (currentSong.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('▶ $currentSong',
                  style: TextStyle(color: AuraTheme.accent,
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(currentArtist,
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 11)),
            ],
          ])),
          const SizedBox(width: 10),
          Column(children: [
            Text('$count', style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 18)),
            Text('listening',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
    child: Container(
      width: 7, height: 7,
      decoration: const BoxDecoration(
          color: Colors.redAccent, shape: BoxShape.circle),
    ),
  );
}

// ──────────────── Create Room Sheet ─────────────────────────────────────────

class _CreateRoomSheet extends StatefulWidget {
  final String uid;
  const _CreateRoomSheet({required this.uid});

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedVibe = '🎵';
  bool _creating = false;
  final _vibes = ['🎵', '🔥', '✨', '🌙', '💜', '🏄', '🎸', '🥂', '😭', '🤘'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _creating = true);
    final state = OrbitState();
    final ref = await FirebaseFirestore.instance.collection('sound_rooms').add({
      'name': _nameCtrl.text.trim(),
      'hostUid': widget.uid,
      'hostName': state.displayName,
      'vibe': _selectedVibe,
      'isLive': true,
      'listenerCount': 1,
      'currentSong': '',
      'currentArtist': '',
      'currentArtUrl': null,
      'queue': [],
      'listeners': [widget.uid],
      'createdAt': Timestamp.now(),
    });
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => SoundRoomScreen(roomId: ref.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2)))),
        const Text('start a sound room 🎙️',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'room name...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        Text('pick a vibe',
            style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _vibes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final v = _vibes[i];
              final sel = v == _selectedVibe;
              return GestureDetector(
                onTap: () => setState(() => _selectedVibe = v),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? AuraTheme.accent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: sel
                        ? Border.all(color: AuraTheme.accent, width: 1.5)
                        : null,
                  ),
                  child: Center(
                      child: Text(v, style: const TextStyle(fontSize: 22))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _creating ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _creating
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('start room',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

// ──────────────── Sound Room Screen ─────────────────────────────────────────

class SoundRoomScreen extends StatefulWidget {
  final String roomId;
  const SoundRoomScreen({super.key, required this.roomId});

  @override
  State<SoundRoomScreen> createState() => _SoundRoomScreenState();
}

class _SoundRoomScreenState extends State<SoundRoomScreen> {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  final _player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<DocumentSnapshot>? _roomSub;
  Map<String, dynamic> _roomData = {};

  @override
  void initState() {
    super.initState();
    _joinRoom();
    _roomSub = _db.collection('sound_rooms').doc(widget.roomId)
        .snapshots().listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() as Map<String, dynamic>;
      setState(() => _roomData = data);
    });
  }

  @override
  void dispose() {
    _leaveRoom();
    _roomSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  bool get _isHost => _roomData['hostUid'] == _uid;

  Future<void> _joinRoom() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('sound_rooms').doc(widget.roomId).update({
      'listeners': FieldValue.arrayUnion([uid]),
      'listenerCount': FieldValue.increment(1),
    });
  }

  Future<void> _leaveRoom() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('sound_rooms').doc(widget.roomId).update({
      'listeners': FieldValue.arrayRemove([uid]),
      'listenerCount': FieldValue.increment(-1),
    });
    // If host leaves, close the room
    if (_isHost) {
      await _db.collection('sound_rooms').doc(widget.roomId)
          .update({'isLive': false});
    }
    await _player.stop();
  }

  Future<void> _playPreview(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _player.setUrl(url);
      await _player.play();
      setState(() => _isPlaying = true);
    } catch (_) {}
  }

  Future<void> _stopPreview() async {
    await _player.stop();
    setState(() => _isPlaying = false);
  }

  Future<void> _sendChatMessage(String text) async {
    if (text.isEmpty) return;
    await _db
        .collection('sound_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'uid': _uid,
      'name': _state.displayName,
      'text': text,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _roomData['name'] as String? ?? 'Sound Room';
    final hostName = _roomData['hostName'] as String? ?? 'Host';
    final currentSong = _roomData['currentSong'] as String? ?? '';
    final currentArtist = _roomData['currentArtist'] as String? ?? '';
    final artUrl = _roomData['currentArtUrl'] as String?;
    final count = _roomData['listenerCount'] as int? ?? 1;
    final vibe = _roomData['vibe'] as String? ?? '🎵';
    final queue = List<Map<String, dynamic>>.from(
        (_roomData['queue'] as List? ?? []).map((e) => e as Map<String, dynamic>));

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$vibe $name',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text('$count listening',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ]),
        actions: [
          if (_isHost)
            TextButton(
              onPressed: () async {
                await _db.collection('sound_rooms').doc(widget.roomId)
                    .update({'isLive': false});
                if (mounted) Navigator.pop(context);
              },
              child: const Text('end room',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(children: [
        // Now Playing
        _NowPlayingCard(
          song: currentSong,
          artist: currentArtist,
          artUrl: artUrl,
          isHost: _isHost,
          isPlaying: _isPlaying,
          onPlayPause: () => _isPlaying ? _stopPreview() : _playPreview(null),
          onChangeSong: _isHost
              ? () => _showSongPicker(context, queue)
              : null,
        ),

        // Queue
        if (queue.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('up next',
                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              ...queue.take(3).map((song) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Text('▸', style: TextStyle(
                      color: AuraTheme.accent, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                      '${song['song']} — ${song['artist']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis)),
                ]),
              )),
            ]),
          ),

        const Divider(color: Colors.white12, height: 1),

        // Chat
        Expanded(child: _RoomChat(roomId: widget.roomId,
            myUid: _uid ?? '', myName: _state.displayName)),

        // Input
        _ChatInput(
          onSend: _sendChatMessage,
          onAddSong: _isHost ? () => _showSongPicker(context, queue) : null,
        ),
      ]),
    );
  }

  void _showSongPicker(
      BuildContext context, List<Map<String, dynamic>> queue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HostSongPicker(
        roomId: widget.roomId,
        queue: queue,
      ),
    );
  }
}

// ──────────────── Now Playing Card ──────────────────────────────────────────

class _NowPlayingCard extends StatelessWidget {
  final String song;
  final String artist;
  final String? artUrl;
  final bool isHost;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onChangeSong;

  const _NowPlayingCard({
    required this.song,
    required this.artist,
    this.artUrl,
    required this.isHost,
    required this.isPlaying,
    required this.onPlayPause,
    this.onChangeSong,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AuraTheme.accent.withOpacity(0.2), width: 1),
      ),
      child: Row(children: [
        if (artUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
                imageUrl: artUrl!, width: 64, height: 64, fit: BoxFit.cover),
          )
        else
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('🎵', style: TextStyle(fontSize: 28))),
          ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(song.isEmpty ? 'no song playing' : song,
              style: TextStyle(
                  color: song.isEmpty
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
              overflow: TextOverflow.ellipsis),
          if (artist.isNotEmpty)
            Text(artist,
                style: TextStyle(color: Colors.white.withOpacity(0.4),
                    fontSize: 12)),
          if (isHost && song.isNotEmpty)
            GestureDetector(
              onTap: onChangeSong,
              child: Text('change song',
                  style: TextStyle(color: AuraTheme.accent,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ])),
        if (isHost)
          IconButton(
            icon: Icon(
                song.isEmpty
                    ? Icons.add_circle_rounded
                    : Icons.skip_next_rounded,
                color: AuraTheme.accent, size: 32),
            onPressed: onChangeSong,
          ),
      ]),
    );
  }
}

// ──────────────── Room Chat ──────────────────────────────────────────────────

class _RoomChat extends StatelessWidget {
  final String roomId;
  final String myUid;
  final String myName;
  const _RoomChat(
      {required this.roomId, required this.myUid, required this.myName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sound_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('say hi to the room 👋',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.2), fontSize: 13)));
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isMe = data['uid'] == myUid;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AuraTheme.accent.withOpacity(0.3),
                      child: Text(
                          (data['name'] as String? ?? 'O')[0].toUpperCase(),
                          style: const TextStyle(color: AuraTheme.accent,
                              fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 2),
                          child: Text(data['name'] as String? ?? 'Orbiter',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 10)),
                        ),
                      Container(
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.65),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AuraTheme.accent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(data['text'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ──────────────── Chat Input ─────────────────────────────────────────────────

class _ChatInput extends StatefulWidget {
  final Future<void> Function(String) onSend;
  final VoidCallback? onAddSong;
  const _ChatInput({required this.onSend, this.onAddSong});

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AuraTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(children: [
        if (widget.onAddSong != null)
          IconButton(
            icon: const Icon(Icons.music_note_rounded,
                color: AuraTheme.accent, size: 22),
            onPressed: widget.onAddSong,
          ),
        Expanded(
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _hasText = v.isNotEmpty),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'say something...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedOpacity(
          opacity: _hasText ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTap: _hasText ? _send : null,
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                  color: AuraTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ]),
    );
  }
}

// ──────────────── Host Song Picker ──────────────────────────────────────────

class _HostSongPicker extends StatefulWidget {
  final String roomId;
  final List<Map<String, dynamic>> queue;
  const _HostSongPicker({required this.roomId, required this.queue});

  @override
  State<_HostSongPicker> createState() => _HostSongPickerState();
}

class _HostSongPickerState extends State<_HostSongPicker> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _playSong(Map<String, dynamic> t) async {
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('sound_rooms').doc(widget.roomId)
        .update({
      'currentSong': t['song'],
      'currentArtist': t['artist'],
      'currentArtUrl': t['artUrl'],
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addToQueue(Map<String, dynamic> t) async {
    HapticFeedback.lightImpact();
    final newQueue = [...widget.queue, t];
    await FirebaseFirestore.instance
        .collection('sound_rooms').doc(widget.roomId)
        .update({'queue': newQueue});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('added ${t['song']} to queue'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const Text('you have the aux 🎛️',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              onChanged: _search,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'search for a song...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(
                  color: AuraTheme.accent, strokeWidth: 2))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final t = _results[i];
                    return ListTile(
                      leading: t['artUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                  imageUrl: t['artUrl'] as String,
                                  width: 40, height: 40, fit: BoxFit.cover))
                          : const Icon(Icons.music_note_rounded,
                              color: AuraTheme.accent),
                      title: Text(t['song'] as String,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(t['artist'] as String,
                          style: TextStyle(color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.queue_music_rounded,
                              color: Colors.white38, size: 20),
                          onPressed: () => _addToQueue(t),
                        ),
                        TextButton(
                          onPressed: () => _playSong(t),
                          child: const Text('play now',
                              style: TextStyle(color: AuraTheme.accent,
                                  fontWeight: FontWeight.w700, fontSize: 12)),
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
