import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String mood;
  final Color color;
  const RoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.mood,
    required this.color,
  });
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _chatService = ChatService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  // Current user — replace with Provider/auth context
  static const _myId = 'me';
  static const _myAuraName = 'Midnight Echo';

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _textCtrl.clear();

    await _chatService.sendCampfireMessage(
      roomId: widget.roomId,
      senderId: _myId,
      senderAuraName: _myAuraName,
      content: text,
    );

    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Row(
              children: [
                Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('12 people glowing',
                    style: const TextStyle(
                        color: AuraColors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          // Nudge someone for pocket
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => _showMembers(context),
            tooltip: 'Members',
          ),
        ],
      ),

      body: Column(
        children: [
          // Mood banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: widget.color.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: widget.color, size: 14),
                const SizedBox(width: 6),
                Text('${widget.mood} vibe · messages clear when you leave',
                    style: TextStyle(
                        color: widget.color.withOpacity(0.8),
                        fontSize: 11)),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getCampfireMessages(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AuraColors.accent));
                }
                final msgs = snapshot.data!;
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 40))
                            .animate().fadeIn().scale(),
                        const SizedBox(height: 12),
                        const Text('You\'re in the room.',
                            style: TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text('Say something or just exist.',
                            style: TextStyle(color: AuraColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderId == _myId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      color: widget.color,
                    ).animate(delay: 0.ms).fadeIn().slideY(begin: 0.05);
                  },
                );
              },
            ),
          ),

          // Typing indicator
          StreamBuilder<Map<String, bool>>(
            stream: _chatService.getTypingStatus(widget.roomId, isCampfire: true),
            builder: (_, snap) {
              final typing = snap.data ?? {};
              final others = typing.entries
                  .where((e) => e.key != _myId && e.value)
                  .toList();
              if (others.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('Someone is typing...',
                    style: const TextStyle(
                        color: AuraColors.textSecondary, fontSize: 12,
                        fontStyle: FontStyle.italic)),
              );
            },
          ),

          // Input bar
          _ChatInput(
            controller: _textCtrl,
            onSend: _send,
            onTyping: (typing) => _chatService.setTyping(
              chatId: widget.roomId,
              userId: _myId,
              isTyping: typing,
              isCampfire: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showMembers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('People in this room',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Nudge someone to open a Pocket',
                style: TextStyle(color: AuraColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...['Silver Tide', 'Amber Wisp', 'Cosmic Shore', 'Pale Ember']
                .map((name) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AuraColors.accent.withOpacity(0.2),
                        child: Text(name[0],
                            style: const TextStyle(color: AuraColors.accent)),
                      ),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Nudge ⚡'),
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Color color;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.2),
            child: Text(message.senderAuraName[0],
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(message.senderAuraName,
                      style: const TextStyle(
                          color: AuraColors.textSecondary,
                          fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AuraColors.accent
                      : AuraColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(message.content,
                    style: TextStyle(
                        color: isMe
                            ? Colors.white : AuraColors.textPrimary,
                        fontSize: 14)),
              ),
              // No timestamp shown — by design
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(bool) onTyping;
  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.onTyping,
  });
  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.isNotEmpty;
      widget.onTyping(has);
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
    decoration: const BoxDecoration(
      color: AuraColors.surface,
      border: Border(top: BorderSide(color: AuraColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Say something...',
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedScale(
          scale: _hasText ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 150),
          child: GestureDetector(
            onTap: widget.onSend,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _hasText
                    ? AuraColors.accent
                    : AuraColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    ),
  );
}
