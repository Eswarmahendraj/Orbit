import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'live_room_service.dart';
import 'live_room_model.dart';

class LiveRoomsScreen extends StatefulWidget {
  const LiveRoomsScreen({super.key});

  @override
  State<LiveRoomsScreen> createState() => _LiveRoomsScreenState();
}

class _LiveRoomsScreenState extends State<LiveRoomsScreen> {
  final _service = LiveRoomService();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrbitState>();

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AuraTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live Rooms',
            style: TextStyle(
                color: AuraTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            onTap: () => _showCreateRoomSheet(context, state),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AuraTheme.accent, AuraTheme.purple],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Start Room',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<LiveRoom>>(
        stream: _service.activeRoomsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AuraTheme.accent));
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return _EmptyRoomsView(
              onStart: () => _showCreateRoomSheet(context, state),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, i) => _RoomCard(
              room: rooms[i],
              onTap: () => _joinRoom(context, rooms[i], state),
            ),
          );
        },
      ),
    );
  }

  void _joinRoom(BuildContext context, LiveRoom room, OrbitState state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRoomActiveScreen(
          room: room,
          isHost: room.hostUid == (FirebaseAuth.instance.currentUser?.uid ?? ''),
        ),
      ),
    );
  }

  void _showCreateRoomSheet(BuildContext context, OrbitState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateRoomSheet(state: state),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final LiveRoom room;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1E1E30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 6),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0x26FF6B00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(room.genre,
                      style: const TextStyle(
                          color: AuraTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                const Icon(Icons.people_rounded,
                    color: AuraTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('${room.listenerCount}',
                    style: const TextStyle(
                        color: AuraTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(room.title,
                style: const TextStyle(
                    color: AuraTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${room.hostEmoji} ${room.hostName}',
                    style: const TextStyle(
                        color: AuraTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                const Text('·',
                    style: TextStyle(color: AuraTheme.textMuted)),
                const SizedBox(width: 8),
                const Icon(Icons.music_note_rounded,
                    color: AuraTheme.accent, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${room.currentSongTitle} — ${room.currentArtist}',
                    style: const TextStyle(
                        color: AuraTheme.accent, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
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

class LiveRoomActiveScreen extends StatefulWidget {
  final LiveRoom room;
  final bool isHost;

  const LiveRoomActiveScreen(
      {super.key, required this.room, required this.isHost});

  @override
  State<LiveRoomActiveScreen> createState() => _LiveRoomActiveScreenState();
}

class _LiveRoomActiveScreenState extends State<LiveRoomActiveScreen>
    with TickerProviderStateMixin {
  final _service = LiveRoomService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _pulseController;
  final List<_FloatingReaction> _floatingReactions = [];

  final List<String> _reactionEmojis = ['🔥', '💜', '🎵', '⚡', '😭', '🙌'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.joinRoom(widget.room.id, FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.leaveRoom(widget.room.id, FirebaseAuth.instance.currentUser?.uid ?? '');
    if (widget.isHost) _service.closeRoom(widget.room.id);
    super.dispose();
  }

  void _sendReaction(String emoji) {
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.sendReaction(
      roomId: widget.room.id,
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      displayName: state.displayName,
      userEmoji: state.moodEmoji,
      reactionEmoji: emoji,
    );
    setState(() {
      _floatingReactions.add(_FloatingReaction(
        emoji: emoji,
        x: Random().nextDouble(),
        id: DateTime.now().millisecondsSinceEpoch,
      ));
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _floatingReactions.isNotEmpty) {
        setState(() => _floatingReactions.removeAt(0));
      }
    });
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.sendMessage(
      roomId: widget.room.id,
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      displayName: state.displayName,
      userEmoji: state.moodEmoji,
      text: _msgController.text.trim(),
    );
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LiveRoom?>(
      stream: _service.roomStream(widget.room.id),
      builder: (context, roomSnap) {
        final room = roomSnap.data ?? widget.room;

        return Scaffold(
          backgroundColor: AuraTheme.background,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x26FF6B00), AuraTheme.background],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AuraTheme.textPrimary,
                                size: 28),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    color: Colors.white, size: 6),
                                SizedBox(width: 4),
                                Text('LIVE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.people_rounded,
                              color: AuraTheme.textMuted, size: 16),
                          const SizedBox(width: 4),
                          Text('${room.listenerCount}',
                              style: const TextStyle(
                                  color: AuraTheme.textMuted, fontSize: 13)),
                          const SizedBox(width: 8),
                          if (widget.isHost)
                            GestureDetector(
                              onTap: () async {
                                await _service.closeRoom(widget.room.id);
                                if (mounted) Navigator.pop(context);
                              },
                              child: const Icon(Icons.stop_circle_rounded,
                                  color: Colors.red, size: 24),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, child) {
                              final scale = 1.0 +
                                  0.04 *
                                      sin(_pulseController.value * 2 * pi);
                              return Transform.scale(
                                  scale: scale, child: child);
                            },
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AuraTheme.accent, AuraTheme.purple],
                                ),
                                image: room.artUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(room.artUrl!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: room.artUrl == null
                                  ? const Center(
                                      child: Text('🎵',
                                          style: TextStyle(fontSize: 48)))
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(room.title,
                              style: const TextStyle(
                                  color: AuraTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${room.hostEmoji} ${room.hostName} is DJing',
                              style: const TextStyle(
                                  color: AuraTheme.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AuraTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.music_note_rounded,
                                    color: AuraTheme.accent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                    '${room.currentSongTitle} — ${room.currentArtist}',
                                    style: const TextStyle(
                                        color: AuraTheme.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _reactionEmojis
                            .map((e) => GestureDetector(
                                  onTap: () => _sendReaction(e),
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: AuraTheme.card,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(e,
                                          style: const TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<List<LiveRoomMessage>>(
                        stream: _service.messagesStream(widget.room.id),
                        builder: (context, msgSnap) {
                          final msgs = msgSnap.data ?? [];
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: msgs.length,
                            itemBuilder: (_, i) =>
                                _MessageBubble(msg: msgs[i]),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      color: AuraTheme.background,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AuraTheme.card,
                                borderRadius: BorderRadius.circular(24),
                                border: const Border.fromBorderSide(
                                  BorderSide(color: Color(0xFF1E1E30)),
                                ),
                              ),
                              child: TextField(
                                controller: _msgController,
                                style: const TextStyle(
                                    color: AuraTheme.textPrimary,
                                    fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Say something...',
                                  hintStyle: TextStyle(
                                      color: AuraTheme.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  AuraTheme.accent,
                                  AuraTheme.purple,
                                ]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ..._floatingReactions
                  .map((r) => _FloatingReactionWidget(r: r)),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final LiveRoomMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isReaction) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(msg.displayName,
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 11)),
            const SizedBox(width: 4),
            Text('reacted ${msg.text}',
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 11)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${msg.displayName}  ',
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: msg.text,
                    style: const TextStyle(
                        color: AuraTheme.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateRoomSheet extends StatefulWidget {
  final OrbitState state;
  const _CreateRoomSheet({required this.state});

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final _service = LiveRoomService();
  final _titleController = TextEditingController();
  String _selectedGenre = 'vibes';
  bool _loading = false;

  final _genres = ['vibes', 'late night', 'hype', 'chill', 'study', 'workout'];

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24),
      decoration: const BoxDecoration(
        color: AuraTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E30),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Start a Live Room',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AuraTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Room name (e.g. "Sunday Morning Feels")',
              hintStyle: const TextStyle(color: AuraTheme.textMuted),
              filled: true,
              fillColor: AuraTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Vibe',
              style: TextStyle(
                  color: AuraTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _genres
                .map((g) => GestureDetector(
                      onTap: () => setState(() => _selectedGenre = g),
                      child: Chip(
                        label: Text(g),
                        labelStyle: TextStyle(
                          color: _selectedGenre == g
                              ? Colors.white
                              : AuraTheme.textSecondary,
                          fontSize: 12,
                        ),
                        backgroundColor: _selectedGenre == g
                            ? AuraTheme.accent
                            : AuraTheme.card,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_rounded,
                    color: AuraTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.state.vibeSong.isNotEmpty
                        ? '${widget.state.vibeSong} — ${widget.state.vibeArtist}'
                        : 'No song playing — start one first',
                    style: const TextStyle(
                        color: AuraTheme.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _loading ? null : () => _createRoom(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AuraTheme.accent, AuraTheme.purple]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Go Live 🎙️',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final roomId = await _service.createRoom(
        hostUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        hostName: widget.state.displayName,
        hostEmoji: widget.state.moodEmoji,
        title: _titleController.text.trim(),
        currentSongTitle: widget.state.vibeSong.isNotEmpty ? widget.state.vibeSong : 'No song',
        currentArtist: widget.state.vibeArtist,
        artUrl: widget.state.vibeArtUrl,
        genre: _selectedGenre,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveRoomActiveScreen(
            room: LiveRoom(
              id: roomId,
              hostUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              hostName: widget.state.displayName,
              hostEmoji: widget.state.moodEmoji,
              title: _titleController.text.trim(),
              currentSongTitle: widget.state.vibeSong.isNotEmpty ? widget.state.vibeSong : 'No song',
              currentArtist: widget.state.vibeArtist,
              artUrl: widget.state.vibeArtUrl,
              listenerUids: [FirebaseAuth.instance.currentUser?.uid ?? ''],
              reactions: <String, dynamic>{},
              isActive: true,
              createdAt: DateTime.now(),
              genre: _selectedGenre,
            ),
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
    }
  }
}

class _EmptyRoomsView extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyRoomsView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎙️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No live rooms right now',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Be the first to start one!',
              style: TextStyle(
                  color: AuraTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AuraTheme.accent, AuraTheme.purple]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Start a Room',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  final double x;
  final int id;
  _FloatingReaction({required this.emoji, required this.x, required this.id});
}

class _FloatingReactionWidget extends StatefulWidget {
  final _FloatingReaction r;
  const _FloatingReactionWidget({required this.r});

  @override
  State<_FloatingReactionWidget> createState() =>
      _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<_FloatingReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    _opacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _offset = Tween(begin: 0.0, end: -120.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        bottom: 120 + _offset.value,
        left: widget.r.x * (MediaQuery.of(context).size.width - 40),
        child: Opacity(
          opacity: _opacity.value,
          child: Text(widget.r.emoji,
              style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
