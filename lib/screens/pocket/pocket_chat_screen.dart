import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/aura_theme.dart';
import '../../services/chat_service.dart';
import '../../services/aura_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class PocketChatScreen extends StatefulWidget {
  final String pocketId;
  final String peerAuraName;
  final String peerId;
  const PocketChatScreen({
    super.key,
    required this.pocketId,
    required this.peerAuraName,
    required this.peerId,
  });
  @override
  State<PocketChatScreen> createState() => _PocketChatScreenState();
}

class _PocketChatScreenState extends State<PocketChatScreen> {
  final _chat = ChatService();
  final _aura = AuraService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;
  int _tenureDays = 0;

  static const _myId = 'me';
  static const _myAuraName = 'Midnight Echo';

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final has = _textCtrl.text.isNotEmpty;
      _chat.setTyping(chatId: widget.pocketId, userId: _myId, isTyping: has);
      if (has != _hasText) setState(() => _hasText = has);
    });
    _loadTenure();
  }

  Future<void> _loadTenure() async {
    final days = await _aura.getTenureDays(widget.peerId);
    if (mounted) setState(() => _tenureDays = days);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _chat.setTyping(chatId: widget.pocketId, userId: _myId, isTyping: false);
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _chat.sendMessage(
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
  Widget build(BuildContext context) {
    final emoji = TenureEmoji.getEmoji(_tenureDays);
    final tenuName = TenureEmoji.getName(_tenureDays);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AuraColors.accent.withOpacity(0.2),
              child: Text(widget.peerAuraName[0],
                  style: const TextStyle(
                      color: AuraColors.accent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(widget.peerAuraName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('$emoji', style: const TextStyle(fontSize: 14)),
                ]),
                Text('$tenuName · $_tenureDays days',
                    style: const TextStyle(
                        color: AuraColors.textSecondary, fontSize: 11)),
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
          // Milestone banner
          if (_tenureDays > 0)
            Container(
              color: AuraColors.accent.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$emoji  $tenuName — $_tenureDays days together',
                      style: const TextStyle(
                          color: AuraColors.accent,
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chat.getMessages(_myId, widget.peerId),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(
                      strokeWidth: 2, color: AuraColors.accent));
                }
                final msgs = snap.data!;
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 48))
                            .animate().fadeIn().scale(),
                        const SizedBox(height: 16),
                        Text('Your Pocket with ${widget.peerAuraName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text(
                          'Say something when it feels right.\nNo pressure. No timestamps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AuraColors.textSecondary,
                              height: 1.6, fontSize: 13)),
                        const SizedBox(height: 28),
                        // Root CTA
                        OutlinedButton.icon(
                          onPressed: () => _showRootDialog(context),
                          icon: const Text('🌱', style: TextStyle(fontSize: 14)),
                          label: const Text('Root this connection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AuraColors.accent,
                            side: const BorderSide(color: AuraColors.accent),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final isMe = msgs[i].senderId == _myId;
                    return _Bubble(message: msgs[i], isMe: isMe)
                        .animate().fadeIn().slideY(begin: 0.04);
                  },
                );
              },
            ),
          ),

          // Typing indicator
          StreamBuilder<Map<String, bool>>(
            stream: _chat.getTypingStatus(widget.pocketId),
            builder: (_, snap) {
              final typing = snap.data ?? {};
              if (typing[widget.peerId] != true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Text('${widget.peerAuraName} is typing...',
                        style: const TextStyle(
                            color: AuraColors.textSecondary,
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AuraColors.surface,
              border: Border(top: BorderSide(color: AuraColors.divider)),
            ),
            child: Row(
              children: [
                // Quick Pulse button
                GestureDetector(
                  onTap: () => _sendPulse(context),
                  child: Container(
                    width: 40, height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AuraColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AuraColors.divider),
                    ),
                    child: const Center(
                        child: Text('⚡', style: TextStyle(fontSize: 18))),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
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
                    onTap: _send,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _hasText ? AuraColors.accent : AuraColors.divider,
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
  }

  void _sendPulse(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send a Pulse',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            ...{
              '⚡': 'I see you',
              '🌊': 'Same energy',
              '💜': 'Thinking of you',
              '🌙': 'Miss your vibe',
            }.entries.map((e) => ListTile(
              leading: Text(e.key, style: const TextStyle(fontSize: 24)),
              title: Text(e.value),
              onTap: () {
                _aura.sendPulse(
                    toUserId: widget.peerId,
                    fromAuraName: _myAuraName,
                    type: e.key);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${e.key} Pulse sent'),
                    backgroundColor: AuraColors.accent,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showRootDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AuraColors.card,
        title: const Text('Root this connection?'),
        content: Text(
          'Rooting makes your connection with ${widget.peerAuraName} permanent. '
          'Your origin story is saved forever.',
          style: const TextStyle(color: AuraColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not yet',
                style: TextStyle(color: AuraColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _aura.rootConnection(widget.peerId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🌱 Connection Rooted'),
                    backgroundColor: AuraColors.accent,
                  ),
                );
              }
            },
            child: const Text('Root 🌱'),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🌱', style: TextStyle(fontSize: 20)),
              title: const Text('Root this connection'),
              onTap: () { Navigator.pop(context); _showRootDialog(context); },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined,
                  color: AuraColors.accent),
              title: const Text('Add to Close Circle'),
              onTap: () {
                _aura.addToCloseCircle(widget.peerId);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off,
                  color: AuraColors.textSecondary),
              title: const Text('Soft Drift'),
              subtitle: const Text('Fade away gradually',
                  style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Block & Report',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(context),
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
  const _Bubble({required this.message, required this.isMe});

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
                    fontSize: 14, height: 1.4)),
          ),
        ),
      ],
    ),
  );
}
