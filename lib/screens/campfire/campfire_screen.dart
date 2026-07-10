import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';
import 'campfire_chat_screen.dart';
import 'collab_playlist_screen.dart';
import 'song_battle_screen.dart';

class CampfireGroup {
  final String id;
  final String name;
  final String emoji;
  final String lastMessage;
  final String lastSender;
  final String timeAgo;
  final int unreadCount;
  final bool isLive;
  final bool isSecret;
  final Color bgColor;

  const CampfireGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lastMessage,
    required this.lastSender,
    required this.timeAgo,
    this.unreadCount = 0,
    this.isLive = false,
    this.isSecret = false,
    required this.bgColor,
  });
}

class CampfireScreen extends StatelessWidget {
  const CampfireScreen({super.key});

  static const List<CampfireGroup> _groups = [
    CampfireGroup(
      id: '1',
      name: 'late night sessions',
      emoji: '🌙',
      lastMessage: 'this song is sending me rn',
      lastSender: 'maya',
      timeAgo: '2m',
      unreadCount: 5,
      isLive: true,
      bgColor: Color(0xFF6C63FF),
    ),
    CampfireGroup(
      id: '2',
      name: 'sunday chill squad',
      emoji: '☀️',
      lastMessage: 'dropped a playlist for y\'all',
      lastSender: 'zoe',
      timeAgo: '14m',
      unreadCount: 2,
      bgColor: Color(0xFFFF7A50),
    ),
    CampfireGroup(
      id: '3',
      name: 'deep focus 🎧',
      emoji: '🎧',
      lastMessage: 'lofi + lo-key vibing',
      lastSender: 'alex',
      timeAgo: '1h',
      bgColor: Color(0xFF00BCD4),
    ),
    CampfireGroup(
      id: '4',
      name: 'college crew',
      emoji: '🎓',
      lastMessage: 'anyone on for tonight?',
      lastSender: 'sam',
      timeAgo: '3h',
      unreadCount: 12,
      bgColor: Color(0xFF4CAF50),
    ),
    CampfireGroup(
      id: '5',
      name: 'hype house',
      emoji: '⚡',
      lastMessage: 'NEW DROP 🔥🔥🔥',
      lastSender: 'leo',
      timeAgo: '5h',
      bgColor: Color(0xFFFF4500),
    ),
    CampfireGroup(
      id: '6',
      name: 'no one can find this 🔒',
      emoji: '🤫',
      lastMessage: 'invite only — shhh',
      lastSender: 'maya',
      timeAgo: '10m',
      unreadCount: 3,
      isSecret: true,
      bgColor: Color(0xFF2D3436),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        title: const Text('campfire',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewGroupSheet(context),
        backgroundColor: AuraTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('new',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groups.length,
        itemBuilder: (context, i) => _GroupTile(group: _groups[i]),
      ),
    );
  }

  void _showNewGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('start a campfire',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('bring your people together around the same vibe',
                style: TextStyle(color: AuraTheme.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'campfire name...',
                prefixIcon: const Icon(Icons.local_fire_department_rounded,
                    color: AuraTheme.accent),
                filled: true,
                fillColor: AuraTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('create',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final CampfireGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CampfireChatScreen(group: group)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: group.isSecret
            ? BoxDecoration(
                color: const Color(0xFF2D3436).withOpacity(0.05),
                border: Border(
                    left: BorderSide(
                        color: const Color(0xFF2D3436).withOpacity(0.3),
                        width: 3)),
              )
            : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: group.bgColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  if (group.isSecret)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_rounded,
                          size: 13, color: AuraTheme.textMuted),
                    ),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (group.isLive)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AuraTheme.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('● live',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(
                  '${group.lastSender}: ${group.lastMessage}',
                  style: TextStyle(
                    color: group.unreadCount > 0
                        ? AuraTheme.textPrimary
                        : AuraTheme.textMuted,
                    fontSize: 13,
                    fontWeight: group.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            // Badge + time
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(group.timeAgo,
                  style: const TextStyle(
                      color: AuraTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              if (group.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.unreadCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ]),
          ]),
          // Collab playlist button
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) =>
                        CollabPlaylistScreen(group: group))),
            child: Row(children: [
              const Icon(Icons.queue_music_rounded,
                  size: 14, color: AuraTheme.accent),
              const SizedBox(width: 5),
              const Text('collab playlist',
                  style: TextStyle(
                      color: AuraTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}
