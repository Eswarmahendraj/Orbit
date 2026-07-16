import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'campfire_screen.dart';

enum MessageType { text, songShare }

class ChatMessage {
  final String id;
  final String senderName;
  final String senderInitial;
  final Color senderColor;
  final bool isMe;
  final MessageType type;
  final String? text;
  final String? songTitle;
  final String? artistName;
  final String? previewUrl;
  final String timeAgo;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderInitial,
    required this.senderColor,
    required this.isMe,
    required this.type,
    this.text,
    this.songTitle,
    this.artistName,
    this.previewUrl,
    required this.timeAgo,
  });
}

class CampfireChatScreen extends StatefulWidget {
  final CampfireGroup group;
  const CampfireChatScreen({super.key, required this.group});

  @override
  State<CampfireChatScreen> createState() => _CampfireChatScreenState();
}

class _CampfireChatScreenState extends State<CampfireChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _audioPlayer = AudioPlayer();
  String? _playingId;
  bool _passcodeUnlocked = false;
  String _pinInput = '';

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderName: 'Maya',
      senderInitial: 'M',
      senderColor: Color(0xFFFF4500),
      isMe: false,
      type: MessageType.text,
      text: 'yo just found this track 🔥',
      timeAgo: '10m',
    ),
    ChatMessage(
      id: '2',
      senderName: 'Maya',
      senderInitial: 'M',
      senderColor: Color(0xFFFF4500),
      isMe: false,
      type: MessageType.songShare,
      songTitle: 'Blinding Lights',
      artistName: 'The Weeknd',
      timeAgo: '10m',
    ),
    ChatMessage(
      id: '3',
      senderName: 'Me',
      senderInitial: 'E',
      senderColor: AuraTheme.accent,
      isMe: true,
      type: MessageType.text,
      text: 'omg this one goes hard',
      timeAgo: '8m',
    ),
    ChatMessage(
      id: '4',
      senderName: 'Alex',
      senderInitial: 'A',
      senderColor: Color(0xFF6C63FF),
      isMe: false,
      type: MessageType.text,
      text: 'adding to the playlist rn',
      timeAgo: '5m',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: 'Me',
        senderInitial: 'E',
        senderColor: AuraTheme.accent,
        isMe: true,
        type: MessageType.text,
        text: text,
        timeAgo: 'now',
      ));
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openSongPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongPickerSheet(
        onSongPicked: (title, artist, url) {
          setState(() {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              senderName: 'Me',
              senderInitial: 'E',
              senderColor: AuraTheme.accent,
              isMe: true,
              type: MessageType.songShare,
              songTitle: title,
              artistName: artist,
              previewUrl: url,
              timeAgo: 'now',
            ));
          });
        },
      ),
    );
  }

  Future<void> _togglePlay(String id, String? url) async {
    if (_playingId == id) {
      await _audioPlayer.pause();
      setState(() => _playingId = null);
    } else {
      setState(() => _playingId = id);
      if (url != null) {
        try {
          await _audioPlayer.setUrl(url);
          await _audioPlayer.play();
        } catch (_) {
          setState(() => _playingId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only secret campfires with a pin need a passcode gate
    final code = widget.group.pin;
    if (code != null && code.isNotEmpty && !_passcodeUnlocked) {
      return _buildPasscodeGate(code);
    }
    return _buildChat();
  }

  Widget _buildPasscodeGate(String code) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        title: const Text('locked',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded,
                  color: AuraTheme.accent, size: 30),
            ),
            const SizedBox(height: 20),
            const Text('enter passcode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                width: 16, height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pinInput.length
                      ? AuraTheme.accent
                      : AuraTheme.surface,
                  border: Border.all(
                      color: AuraTheme.accent.withOpacity(0.4)),
                ),
              )),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.0,
              children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                if (k.isEmpty) return const SizedBox();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (k == '⌫') {
                        if (_pinInput.isNotEmpty) {
                          _pinInput = _pinInput.substring(0, _pinInput.length - 1);
                        }
                      } else if (_pinInput.length < 4) {
                        _pinInput += k;
                        if (_pinInput.length == 4) {
                          if (_pinInput == code) {
                            _passcodeUnlocked = true;
                          } else {
                            _pinInput = '';
                          }
                        }
                      }
                    });
                  },
                  child: Center(
                    child: Text(k,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w300)),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.group.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const Text('4 in orbit',
                    style: TextStyle(
                        color: AuraTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.group_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return msg.type == MessageType.songShare
                    ? _SongShareBubble(
                        message: msg,
                        isPlaying: _playingId == msg.id,
                        onTogglePlay: () =>
                            _togglePlay(msg.id, msg.previewUrl),
                      )
                    : _TextBubble(message: msg);
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            onSend: _sendMessage,
            onSongTap: _openSongPicker,
          ),
        ],
      ),
    );
  }
}

// ─── Text Bubble ──────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  const _TextBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: message.senderColor.withOpacity(0.15),
              child: Text(message.senderInitial,
                  style: TextStyle(
                      color: message.senderColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? AuraTheme.accent : AuraTheme.card,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: message.isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
                bottomLeft: message.isMe
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
              ),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(
                color: message.isMe ? Colors.white : AuraTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Song Share Bubble ────────────────────────────────────────────────────────

class _SongShareBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const _SongShareBubble({
    required this.message,
    required this.isPlaying,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: message.senderColor.withOpacity(0.15),
              child: Text(message.senderInitial,
                  style: TextStyle(
                      color: message.senderColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: AuraTheme.accent, width: 3),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AuraTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note,
                            color: AuraTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.songTitle ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(message.artistName ?? '',
                                style: const TextStyle(
                                    color: AuraTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onTogglePlay,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AuraTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(13),
                      bottomRight: Radius.circular(13),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note,
                          color: AuraTheme.accent, size: 12),
                      const SizedBox(width: 4),
                      const Text('sharing vibe',
                          style: TextStyle(
                              color: AuraTheme.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: AuraTheme.textMuted, size: 12),
                          const SizedBox(width: 2),
                          const Text('fire',
                              style: TextStyle(
                                  color: AuraTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSongTap;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuraTheme.card,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.music_note, color: AuraTheme.accent),
            onPressed: onSongTap,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'say something...',
                filled: true,
                fillColor: AuraTheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AuraTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Song Picker Sheet ────────────────────────────────────────────────────────

class _SongPickerSheet extends StatefulWidget {
  final void Function(String title, String artist, String? url) onSongPicked;
  const _SongPickerSheet({required this.onSongPicked});

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=10');
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data['results']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('share a song',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'search songs...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AuraTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _search,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AuraTheme.accent),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final track = _results[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track['artworkUrl60'] != null
                            ? Image.network(track['artworkUrl60'],
                                width: 40, height: 40, fit: BoxFit.cover)
                            : Container(
                                width: 40,
                                height: 40,
                                color: AuraTheme.surface,
                                child: const Icon(Icons.music_note,
                                    color: AuraTheme.accent)),
                      ),
                      title: Text(track['trackName'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(track['artistName'] ?? '',
                          style: const TextStyle(color: AuraTheme.textMuted)),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSongPicked(
                          track['trackName'] ?? '',
                          track['artistName'] ?? '',
                          track['previewUrl'],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
