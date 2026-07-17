import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import '../home/dm_screen.dart';
import 'campfire_screen.dart';

enum MessageType { text, songShare, photo, voiceNote, listeningParty }

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
  final String? photoPath;
  final String timeAgo;
  // emoji → list of sender names who reacted
  final Map<String, List<String>> reactions;
  // listening party
  final bool partyActive;
  final Set<String> partyJoined;

  ChatMessage({
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
    this.photoPath,
    required this.timeAgo,
    Map<String, List<String>>? reactions,
    this.partyActive = false,
    Set<String>? partyJoined,
  }) : reactions = reactions ?? {},
       partyJoined = partyJoined ?? {};
}

// ─── Sample members ────────────────────────────────────────────────────────────

class _Member {
  final String name;
  final String initial;
  final Color color;
  final bool isActive;
  const _Member(this.name, this.initial, this.color, {this.isActive = false});
}

const _groupMembers = [
  _Member('Maya', 'M', Color(0xFFFF4500), isActive: true),
  _Member('Alex', 'A', Color(0xFF6C63FF), isActive: true),
  _Member('Jordan', 'J', Color(0xFF00D2A8), isActive: false),
  _Member('Rina', 'R', Color(0xFFFF6B9D), isActive: false),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────

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
      id: '1', senderName: 'Maya', senderInitial: 'M',
      senderColor: Color(0xFFFF4500), isMe: false,
      type: MessageType.text, text: 'yo just found this track 🔥', timeAgo: '10m',
    ),
    ChatMessage(
      id: '2', senderName: 'Maya', senderInitial: 'M',
      senderColor: Color(0xFFFF4500), isMe: false,
      type: MessageType.songShare, songTitle: 'Blinding Lights',
      artistName: 'The Weeknd', timeAgo: '10m',
    ),
    ChatMessage(
      id: '3', senderName: 'Me', senderInitial: 'E',
      senderColor: AuraTheme.accent, isMe: true,
      type: MessageType.text, text: 'omg this one goes hard', timeAgo: '8m',
    ),
    ChatMessage(
      id: '4', senderName: 'Alex', senderInitial: 'A',
      senderColor: Color(0xFF6C63FF), isMe: false,
      type: MessageType.text, text: 'adding to the playlist rn', timeAgo: '5m',
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
        senderName: 'Me', senderInitial: 'E',
        senderColor: AuraTheme.accent, isMe: true,
        type: MessageType.text, text: text, timeAgo: 'now',
      ));
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
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
              senderName: 'Me', senderInitial: 'E',
              senderColor: AuraTheme.accent, isMe: true,
              type: MessageType.songShare,
              songTitle: title, artistName: artist, previewUrl: url,
              timeAgo: 'now',
            ));
          });
          _scrollToBottom();
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: 'Me', senderInitial: 'E',
        senderColor: AuraTheme.accent, isMe: true,
        type: MessageType.photo, photoPath: file.path, timeAgo: 'now',
      ));
    });
    _scrollToBottom();
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

  void _showGroupDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GroupDetailsSheet(group: widget.group),
    );
  }

  void _showPeopleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PeopleSheet(groupName: widget.group.name),
    );
  }

  void _startGroupCall({required bool video}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AuraTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(video ? Icons.videocam_rounded : Icons.call_rounded,
              color: AuraTheme.accent),
          const SizedBox(width: 8),
          Text(video ? 'Group Video Call' : 'Group Voice Call',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Text(
          'Starting ${video ? 'video' : 'voice'} call with everyone in ${widget.group.name}...',
          style: const TextStyle(color: AuraTheme.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AuraTheme.accent),
            child: Text(video ? 'Join Video' : 'Join Call',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('locked', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: AuraTheme.accent, size: 30),
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
                  color: i < _pinInput.length ? AuraTheme.accent : AuraTheme.surface,
                  border: Border.all(color: AuraTheme.accent.withOpacity(0.4)),
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
                          if (_pinInput == code) _passcodeUnlocked = true;
                          else _pinInput = '';
                        }
                      }
                    });
                  },
                  child: Center(
                    child: Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
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
        title: GestureDetector(
          onTap: _showGroupDetails,
          child: Row(
            children: [
              Text(widget.group.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.group.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: AuraTheme.textMuted),
                    ],
                  ),
                  const Text('4 in orbit',
                      style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _startGroupCall(video: false),
            tooltip: 'Voice call',
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () => _startGroupCall(video: true),
            tooltip: 'Video call',
          ),
          IconButton(
            icon: const Icon(Icons.group_outlined),
            onPressed: _showPeopleSheet,
          ),
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
                Widget bubble;
                if (msg.type == MessageType.listeningParty) {
                  bubble = _PartyBubble(
                    message: msg,
                    isPlaying: _playingId == msg.id,
                    onTogglePlay: () => _togglePlay(msg.id, msg.previewUrl),
                    onJoin: () => _joinParty(i),
                  );
                } else if (msg.type == MessageType.songShare) {
                  bubble = _SongShareBubble(
                    message: msg,
                    isPlaying: _playingId == msg.id,
                    onTogglePlay: () => _togglePlay(msg.id, msg.previewUrl),
                  );
                } else if (msg.type == MessageType.photo) {
                  bubble = _PhotoBubble(message: msg);
                } else {
                  bubble = _TextBubble(message: msg);
                }
                return GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showReactionPicker(i);
                  },
                  child: Column(
                    crossAxisAlignment: msg.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      bubble,
                      if (msg.reactions.isNotEmpty)
                        _ReactionRow(
                          reactions: msg.reactions,
                          isMe: msg.isMe,
                          onTap: (emoji) => _addReaction(i, emoji),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _InputBar(
            controller: _controller,
            onSend: _sendMessage,
            onSongTap: _openSongPicker,
            onPhotoTap: _pickPhoto,
            onVoiceNoteTap: () => _showSnack('🎙️ Voice note coming soon'),
            onVoiceCallTap: () => _startGroupCall(video: false),
            onVideoCallTap: () => _startGroupCall(video: true),
            onDMTap: () => _showPeopleDMPicker(),
            onPartyTap: _openListeningParty,
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating,
          backgroundColor: AuraTheme.card));
  }

  void _openListeningParty() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongPickerSheet(
        onSongPicked: (title, artist, url) {
          setState(() {
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              senderName: 'Me', senderInitial: 'E',
              senderColor: AuraTheme.accent, isMe: true,
              type: MessageType.listeningParty,
              songTitle: title, artistName: artist, previewUrl: url,
              timeAgo: 'now',
              partyActive: true,
              partyJoined: {'Me'},
            ));
          });
          _scrollToBottom();
          // Auto-play for host
          if (url != null) _togglePlay(_messages.last.id, url);
        },
      ),
    );
  }

  void _joinParty(int msgIndex) {
    final msg = _messages[msgIndex];
    final joined = Set<String>.from(msg.partyJoined)..add('Me');
    setState(() {
      _messages[msgIndex] = ChatMessage(
        id: msg.id, senderName: msg.senderName,
        senderInitial: msg.senderInitial, senderColor: msg.senderColor,
        isMe: msg.isMe, type: msg.type,
        songTitle: msg.songTitle, artistName: msg.artistName,
        previewUrl: msg.previewUrl, timeAgo: msg.timeAgo,
        reactions: msg.reactions, partyActive: msg.partyActive,
        partyJoined: joined,
      );
    });
    _togglePlay(msg.id, msg.previewUrl);
  }

  void _showPeopleDMPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DMPickerSheet(members: _groupMembers),
    );
  }

  void _addReaction(int msgIndex, String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      final msg = _messages[msgIndex];
      final existing = Map<String, List<String>>.from(
          msg.reactions.map((k, v) => MapEntry(k, List<String>.from(v))));
      final senders = existing[emoji] ?? [];
      if (senders.contains('Me')) {
        senders.remove('Me');
        if (senders.isEmpty) existing.remove(emoji);
        else existing[emoji] = senders;
      } else {
        senders.add('Me');
        existing[emoji] = senders;
      }
      _messages[msgIndex] = ChatMessage(
        id: msg.id, senderName: msg.senderName,
        senderInitial: msg.senderInitial, senderColor: msg.senderColor,
        isMe: msg.isMe, type: msg.type,
        text: msg.text, songTitle: msg.songTitle, artistName: msg.artistName,
        previewUrl: msg.previewUrl, photoPath: msg.photoPath,
        timeAgo: msg.timeAgo, reactions: existing,
      );
    });
  }

  void _showReactionPicker(int msgIndex) {
    const emojis = ['🔥', '💫', '😂', '❤️', '😮', '👑', '🎵', '⚡', '💜', '✨'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis.map((e) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addReaction(msgIndex, e);
              },
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── Group Details Sheet ──────────────────────────────────────────────────────

class _GroupDetailsSheet extends StatelessWidget {
  final CampfireGroup group;
  const _GroupDetailsSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Group avatar
            Center(
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: group.bgColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(group.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(group.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('${_groupMembers.length} members · ${_groupMembers.where((m) => m.isActive).length} active',
                  style: const TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
            ),
            if (group.isSecret) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_rounded, size: 12, color: AuraTheme.accent),
                    SizedBox(width: 4),
                    Text('secret campfire', style: TextStyle(color: AuraTheme.accent, fontSize: 12)),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Members preview
            const Text('members', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: _groupMembers.map((m) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: m.color.withOpacity(0.15),
                        child: Text(m.initial,
                            style: TextStyle(color: m.color, fontWeight: FontWeight.w700)),
                      ),
                      if (m.isActive) Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C42),
                            shape: BoxShape.circle,
                            border: Border.all(color: AuraTheme.card, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(m.name, style: const TextStyle(fontSize: 11)),
                ]),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Options
            _optionRow(Icons.notifications_outlined, 'Mute notifications', () => Navigator.pop(context)),
            _optionRow(Icons.search_rounded, 'Search in chat', () => Navigator.pop(context)),
            _optionRow(Icons.color_lens_outlined, 'Change theme', () => Navigator.pop(context)),
            _optionRow(Icons.person_add_outlined, 'Add member', () => Navigator.pop(context)),
            _optionRow(Icons.exit_to_app_rounded, 'Leave campfire',
                () => Navigator.pop(context), color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? AuraTheme.textPrimary, size: 22),
      title: Text(label, style: TextStyle(color: color ?? AuraTheme.textPrimary, fontSize: 14)),
      onTap: onTap,
    );
  }
}

// ─── People Sheet ─────────────────────────────────────────────────────────────

class _PeopleSheet extends StatelessWidget {
  final String groupName;
  const _PeopleSheet({required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AuraTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Text('people in campfire',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF8C42), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('${_groupMembers.where((m) => m.isActive).length} active',
                    style: const TextStyle(color: Color(0xFFFF8C42), fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          ..._groupMembers.map((m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: m.color.withOpacity(0.15),
                  child: Text(m.initial,
                      style: TextStyle(color: m.color, fontWeight: FontWeight.w700)),
                ),
                if (m.isActive) Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42),
                      shape: BoxShape.circle,
                      border: Border.all(color: AuraTheme.card, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(m.isActive ? 'active now' : 'offline',
                style: TextStyle(
                    color: m.isActive ? const Color(0xFFFF8C42) : AuraTheme.textMuted,
                    fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.message_outlined, size: 18, color: AuraTheme.textMuted),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DMScreen(
                    username: '@${m.name.toLowerCase()}',
                    displayName: m.name,
                  ),
                ));
              },
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── DM Picker Sheet ──────────────────────────────────────────────────────────

class _DMPickerSheet extends StatelessWidget {
  final List<_Member> members;
  const _DMPickerSheet({required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AuraTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('send a private DM',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...members.map((m) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: m.color.withOpacity(0.15),
              child: Text(m.initial,
                  style: TextStyle(color: m.color, fontWeight: FontWeight.w700)),
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(m.isActive ? 'active now' : 'offline',
                style: TextStyle(
                    color: m.isActive ? const Color(0xFFFF8C42) : AuraTheme.textMuted,
                    fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => DMScreen(
                  username: '@${m.name.toLowerCase()}',
                  displayName: m.name,
                ),
              ));
            },
          )),
          const SizedBox(height: 8),
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
                  style: TextStyle(color: message.senderColor,
                      fontSize: 11, fontWeight: FontWeight.w700)),
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
                bottomRight: message.isMe ? const Radius.circular(4) : const Radius.circular(18),
                bottomLeft: message.isMe ? const Radius.circular(18) : const Radius.circular(4),
              ),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(
                  color: message.isMe ? Colors.white : AuraTheme.textPrimary,
                  fontSize: 14),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Photo Bubble ─────────────────────────────────────────────────────────────

class _PhotoBubble extends StatelessWidget {
  final ChatMessage message;
  const _PhotoBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final path = message.photoPath;
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
                  style: TextStyle(color: message.senderColor,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: path != null && File(path).existsSync()
                ? Image.file(File(path), width: 200, height: 200, fit: BoxFit.cover)
                : Container(
                    width: 200, height: 200,
                    color: AuraTheme.surface,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AuraTheme.textMuted)),
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
                  style: TextStyle(color: message.senderColor,
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AuraTheme.accent, width: 3)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AuraTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note, color: AuraTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.songTitle ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(message.artistName ?? '',
                                style: const TextStyle(
                                    color: AuraTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onTogglePlay,
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                              color: AuraTheme.accent, shape: BoxShape.circle),
                          child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(13),
                        bottomRight: Radius.circular(13)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: AuraTheme.accent, size: 12),
                      const SizedBox(width: 4),
                      const Text('sharing vibe',
                          style: TextStyle(color: AuraTheme.accent,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.local_fire_department_rounded,
                          color: AuraTheme.textMuted, size: 12),
                      const SizedBox(width: 2),
                      const Text('fire',
                          style: TextStyle(color: AuraTheme.textMuted, fontSize: 10)),
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

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSongTap;
  final VoidCallback onPhotoTap;
  final VoidCallback onVoiceNoteTap;
  final VoidCallback onVoiceCallTap;
  final VoidCallback onVideoCallTap;
  final VoidCallback onDMTap;
  final VoidCallback onPartyTap;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onSongTap,
    required this.onPhotoTap,
    required this.onVoiceNoteTap,
    required this.onVoiceCallTap,
    required this.onVideoCallTap,
    required this.onDMTap,
    required this.onPartyTap,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuraTheme.card,
      padding: EdgeInsets.only(
        left: 8, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachBtn(icon: Icons.headphones_rounded, label: 'Party',
                      color: const Color(0xFFFF8C42), onTap: widget.onPartyTap),
                  _AttachBtn(icon: Icons.music_note_rounded, label: 'Music',
                      color: const Color(0xFFA18CD1), onTap: widget.onSongTap),
                  _AttachBtn(icon: Icons.photo_rounded, label: 'Photo',
                      color: const Color(0xFF6C63FF), onTap: widget.onPhotoTap),
                  _AttachBtn(icon: Icons.mic_rounded, label: 'Voice',
                      color: const Color(0xFF00D2A8), onTap: widget.onVoiceNoteTap),
                  _AttachBtn(icon: Icons.call_rounded, label: 'Call',
                      color: const Color(0xFF4CAF50), onTap: widget.onVoiceCallTap),
                  _AttachBtn(icon: Icons.person_rounded, label: 'DM',
                      color: const Color(0xFFFF6B9D), onTap: widget.onDMTap),
                ],
              ),
            ),
          ],
          Row(
            children: [
              IconButton(
                icon: AnimatedRotation(
                  turns: _expanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: AuraTheme.accent),
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
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
                  onSubmitted: (_) => widget.onSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onSend,
                child: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: AuraTheme.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AuraTheme.textMuted)),
        ],
      ),
    );
  }
}

// ─── Listening Party Bubble ───────────────────────────────────────────────────

class _PartyBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onJoin;

  const _PartyBubble({
    required this.message,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final joined = message.partyJoined;
    final iJoined = joined.contains('Me');
    final others = joined.where((n) => n != 'Me').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A2E), Color(0xFF2A1050)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.accent.withOpacity(0.5), width: 1.5),
          boxShadow: [BoxShadow(
            color: AuraTheme.accent.withOpacity(0.2),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🎧', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text('LISTENING PARTY',
                    style: TextStyle(color: AuraTheme.accent, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              ]),
            ),
            const Spacer(),
            Text('${joined.length} listening',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
          const SizedBox(height: 12),

          // Song info + play
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  isPlaying ? '🎵' : '🎶',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.songTitle ?? '',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(message.artistName ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            )),
            GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iJoined ? AuraTheme.accent : Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 22,
                ),
              ),
            ),
          ]),

          // Who's listening
          if (others.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              ...others.take(4).map((name) => Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              )),
              if (others.length > 4)
                Text('+${others.length - 4} more',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ],

          const SizedBox(height: 12),

          // Join button
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: iJoined
                    ? Colors.white.withOpacity(0.08)
                    : AuraTheme.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: iJoined ? onTogglePlay : onJoin,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(
                        iJoined
                            ? (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded)
                            : Icons.headphones_rounded,
                        color: Colors.white, size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        iJoined
                            ? (isPlaying ? 'pause' : 'resume')
                            : 'join the party 🔥',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Reaction Row ─────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final bool isMe;
  final ValueChanged<String> onTap;
  const _ReactionRow({required this.reactions, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sorted = reactions.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 36,
        right: isMe ? 8 : 0,
        bottom: 6,
        top: 2,
      ),
      child: Wrap(
        spacing: 4,
        children: sorted.map((e) {
          final iMine = e.value.contains('Me');
          return GestureDetector(
            onTap: () => onTap(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: iMine
                    ? AuraTheme.accent.withOpacity(0.15)
                    : AuraTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iMine
                      ? AuraTheme.accent.withOpacity(0.5)
                      : AuraTheme.textMuted.withOpacity(0.2),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e.key, style: const TextStyle(fontSize: 13)),
                if (e.value.length > 1) ...[
                  const SizedBox(width: 3),
                  Text('${e.value.length}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: iMine ? AuraTheme.accent : AuraTheme.textMuted)),
                ],
              ]),
            ),
          );
        }).toList(),
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
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
                      borderSide: BorderSide.none),
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
                                width: 40, height: 40,
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
