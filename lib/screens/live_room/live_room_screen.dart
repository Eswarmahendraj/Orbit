import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../../services/audio_player_service.dart';
import 'live_room_service.dart';
import 'live_room_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Live Rooms Discovery Screen
// ─────────────────────────────────────────────────────────────────────────────
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
    final theme = AuraTheme.current;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Rooms',
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            onTap: () => _showCreateRoomSheet(context, state),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.accent, theme.accentSecondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text('Start Room',
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
            return Center(
                child: CircularProgressIndicator(color: theme.accent));
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return _EmptyRoomsView(
              theme: theme,
              onStart: () => _showCreateRoomSheet(context, state),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, i) => _RoomCard(
              room: rooms[i],
              theme: theme,
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
          isHost: room.hostUid == state.uid,
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

// ─────────────────────────────────────────────────────────────────────────────
// Room Card
// ─────────────────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final LiveRoom room;
  final AuraTheme theme;
  final VoidCallback onTap;

  const _RoomCard(
      {required this.room, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.divider.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Live indicator
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
                    color: theme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(room.genre,
                      style: TextStyle(
                          color: theme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Icon(Icons.people_rounded, color: theme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('${room.listenerCount}',
                    style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(room.title,
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${room.hostEmoji} ${room.hostName}',
                    style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('·', style: TextStyle(color: theme.textMuted)),
                const SizedBox(width: 8),
                Icon(Icons.music_note_rounded, color: theme.accent, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${room.currentSongTitle} — ${room.currentArtist}',
                    style: TextStyle(color: theme.accent, fontSize: 13),
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

// ─────────────────────────────────────────────────────────────────────────────
// Active Room Screen
// ─────────────────────────────────────────────────────────────────────────────
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
  Timer? _cleanupTimer;

  final List<String> _reactionEmojis = ['🔥', '💜', '🎵', '⚡', '😭', '🙌'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Join room
    final state =
        Provider.of<OrbitState>(context, listen: false);
    _service.joinRoom(widget.room.id, state.uid ?? '');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _cleanupTimer?.cancel();
    final state =
        Provider.of<OrbitState>(context, listen: false);
    _service.leaveRoom(widget.room.id, state.uid ?? '');
    if (widget.isHost) _service.closeRoom(widget.room.id);
    super.dispose();
  }

  void _sendReaction(String emoji) {
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.sendReaction(
      roomId: widget.room.id,
      uid: state.uid ?? '',
      displayName: state.displayName,
      userEmoji: state.moodEmoji,
      reactionEmoji: emoji,
    );
    // Add floating reaction locally
    setState(() {
      _floatingReactions.add(_FloatingReaction(
        emoji: emoji,
        x: Random().nextDouble(),
        id: DateTime.now().millisecondsSinceEpoch,
      ));
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _floatingReactions.removeWhere(
              (r) => r.id == _floatingReactions.first.id);
        });
      }
    });
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    final state = Provider.of<OrbitState>(context, listen: false);
    _service.sendMessage(
      roomId: widget.room.id,
      uid: state.uid ?? '',
      displayName: state.displayName,
      userEmoji: state.moodEmoji,
      text: _msgController.text.trim(),
    );
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;

    return StreamBuilder<LiveRoom?>(
      stream: _service.roomStream(widget.room.id),
      builder: (context, roomSnap) {
        final room = roomSnap.data ?? widget.room;

        return Scaffold(
          backgroundColor: theme.background,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.accent.withOpacity(0.15),
                      theme.background,
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ── Header ───────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: theme.textPrimary, size: 28),
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
                          Icon(Icons.people_rounded,
                              color: theme.textMuted, size: 16),
                          const SizedBox(width: 4),
                          Text('${room.listenerCount}',
                              style: TextStyle(
                                  color: theme.textMuted, fontSize: 13)),
                          const SizedBox(width: 8),
                          if (widget.isHost)
                            GestureDetector(
                              onTap: () async {
                                await _service.closeRoom(widget.room.id);
                                if (mounted) Navigator.pop(context);
                              },
                              child: Icon(Icons.stop_circle_rounded,
                                  color: Colors.red, size: 24),
                            ),
                        ],
                      ),
                    ),

                    // ── Now Playing ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Album art circle with pulse
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
                                gradient: LinearGradient(
                                  colors: [theme.accent, theme.accentSecondary],
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
                              style: TextStyle(
                                  color: theme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${room.hostEmoji} ${room.hostName} is DJing',
                              style: TextStyle(
                                  color: theme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.music_note_rounded,
                                    color: theme.accent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                    '${room.currentSongTitle} — ${room.currentArtist}',
                                    style: TextStyle(
                                        color: theme.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Reaction bar ─────────────────────────────────────────
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
                                    decoration: BoxDecoration(
                                      color: theme.cardBackground,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: theme.divider.withOpacity(0.4)),
                                    ),
                                    child: Center(
                                      child: Text(e,
                                          style:
                                              const TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Messages ─────────────────────────────────────────────
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
                            itemBuilder: (_, i) => _MessageBubble(
                                msg: msgs[i], theme: theme),
                          );
                        },
                      ),
                    ),

                    // ── Chat input ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      color: theme.background,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.cardBackground,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: theme.divider.withOpacity(0.4)),
                              ),
                              child: TextField(
                                controller: _msgController,
                                style: TextStyle(
                                    color: theme.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Say something...',
                                  hintStyle:
                                      TextStyle(color: theme.textMuted),
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
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  theme.accent,
                                  theme.accentSecondary
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

              // ── Floating reactions ────────────────────────────────────────
              ..._floatingReactions.map((r) => _FloatingReactionWidget(r: r)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final LiveRoomMessage msg;
  final AuraTheme theme;

  const _MessageBubble({required this.msg, required this.theme});

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
                style:
                    TextStyle(color: theme.textMuted, fontSize: 11)),
            const SizedBox(width: 4),
            Text('reacted ${msg.text}',
                style:
                    TextStyle(color: theme.textMuted, fontSize: 11)),
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
                    style: TextStyle(
                        color: theme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: msg.text,
                    style: TextStyle(
                        color: theme.textPrimary, fontSize: 13),
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

// ─────────────────────────────────────────────────────────────────────────────
// Create Room Sheet
// ─────────────────────────────────────────────────────────────────────────────
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
    final theme = AuraTheme.current;
    final audio = AudioPlayerService();

    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Start a Live Room',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          // Title
          TextField(
            controller: _titleController,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Room name (e.g. "Sunday Morning Feels")',
              hintStyle: TextStyle(color: theme.textMuted),
              filled: true,
              fillColor: theme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Genre chips
          Text('Vibe',
              style: TextStyle(
                  color: theme.textSecondary,
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
                              : theme.textSecondary,
                          fontSize: 12,
                        ),
                        backgroundColor: _selectedGenre == g
                            ? theme.accent
                            : theme.cardBackground,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          // Current song info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.music_note_rounded, color: theme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    audio.currentTitle != null
                        ? '${audio.currentTitle} — ${audio.currentArtist}'
                        : 'No song playing — start one first',
                    style: TextStyle(
                        color: theme.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Create button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _loading ? null : () => _createRoom(context, audio),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [theme.accent, theme.accentSecondary]),
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

  Future<void> _createRoom(
      BuildContext context, AudioPlayerService audio) async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final roomId = await _service.createRoom(
        hostUid: widget.state.uid ?? '',
        hostName: widget.state.displayName,
        hostEmoji: widget.state.moodEmoji,
        title: _titleController.text.trim(),
        currentSongTitle: audio.currentTitle ?? 'No song',
        currentArtist: audio.currentArtist ?? '',
        artUrl: audio.currentArtUrl,
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
              hostUid: widget.state.uid ?? '',
              hostName: widget.state.displayName,
              hostEmoji: widget.state.moodEmoji,
              title: _titleController.text.trim(),
              currentSongTitle: audio.currentTitle ?? 'No song',
              currentArtist: audio.currentArtist ?? '',
              artUrl: audio.currentArtUrl,
              listenerUids: [widget.state.uid ?? ''],
              reactions: {},
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyRoomsView extends StatelessWidget {
  final AuraTheme theme;
  final VoidCallback onStart;

  const _EmptyRoomsView({required this.theme, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎙️', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No live rooms right now',
              style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Be the first to start one!',
              style: TextStyle(color: theme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [theme.accent, theme.accentSecondary]),
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

// ─────────────────────────────────────────────────────────────────────────────
// Floating reaction
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingReaction {
  final String emoji;
  final double x; // 0.0–1.0 horizontal position
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
