import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../../services/chat_service.dart';
import '../../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String peerAuraName;
  final String peerId;
  final Color peerColor;
  final String tenureEmoji;
  const ChatScreen({
    super.key,
    required this.peerAuraName,
    required this.peerId,
    required this.peerColor,
    required this.tenureEmoji,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _myId = 'me';
  static const _myAuraName = 'Midnight Echo';

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final has = _textCtrl.text.isNotEmpty;
      _chatService.setTyping(
          chatId: _chatId, userId: _myId, isTyping: has);
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  String get _chatId {
    final ids = [_myId, widget.peerId]..sort();
    return ids.join('_');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _chatService.setTyping(chatId: _chatId, userId: _myId, isTyping: false);
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _chatService.sendMessage(
      senderId: _myId,
      senderAuraName: _myAuraName,
      receiverId: widget.peerId,
      content: text,
    );
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: widget.peerColor.withOpacity(0.2),
            child: Text(widget.peerAuraName[0],
                style: TextStyle(color: widget.peerColor,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.peerAuraName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(widget.tenureEmoji,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
              const Text('online',
                  style: TextStyle(
                      color: Colors.greenAccent, fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context),
        ),
      ],
    ),

    body: Column(
      children: [
        // No read receipts / no timestamps notice (shown once)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: AuraColors.surface,
          child: const Text(
            'No timestamps · No read receipts · Just vibes',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AuraColors.textSecondary, fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ),

        // Messages
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _chatService.getMessages(_myId, widget.peerId),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AuraColors.accent));
              }
              final msgs = snap.data!;
              if (msgs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.tenureEmoji,
                          style: const TextStyle(fontSize: 40))
                          .animate().fadeIn().scale(),
                      const SizedBox(height: 12),
                      Text('You\'re connected with ${widget.peerAuraName}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Say something when you feel it.',
                          style: TextStyle(
                              color: AuraColors.textSecondary)),
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
                  return _Bubble(message: msg, isMe: isMe,
                      color: widget.peerColor)
                      .animate().fadeIn().slideY(begin: 0.05);
                },
              );
            },
          ),
        ),

        // Typing indicator (receiver sees it, sender doesn't)
        StreamBuilder<Map<String, bool>>(
          stream: _chatService.getTypingStatus(_chatId),
          builder: (_, snap) {
            final typing = snap.data ?? {};
            final peerTyping = typing[widget.peerId] == true;
            if (!peerTyping) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor:
                        widget.peerColor.withOpacity(0.2),
                    child: Text(widget.peerAuraName[0],
                        style: TextStyle(
                            color: widget.peerColor, fontSize: 9)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AuraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: List.generate(3, (i) => _Dot(delay: i * 150)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Input
        Container(
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
                  controller: _textCtrl,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
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
                  onTap: _send,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _hasText
                          ? AuraColors.accent : AuraColors.divider,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link_off, color: AuraColors.textSecondary),
              title: const Text('Soft Drift'),
              subtitle: const Text('Your Aura fades for them gradually',
                  style: TextStyle(fontSize: 12)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline,
                  color: Colors.orangeAccent),
              title: const Text('Unroot'),
              subtitle: const Text('Clean break, no notification sent',
                  style: TextStyle(fontSize: 12)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Block & Report',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Color color;
  const _Bubble({required this.message, required this.isMe, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AuraColors.accent : AuraColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(message.content,
                style: TextStyle(
                    color: isMe ? Colors.white : AuraColors.textPrimary,
                    fontSize: 14,
                    height: 1.4)),
            // No timestamp — by design
          ),
        ),
      ],
    ),
  );
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 6, height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AuraColors.textSecondary
            .withOpacity(0.4 + _ctrl.value * 0.6),
        shape: BoxShape.circle,
      ),
    ),
  );
}
