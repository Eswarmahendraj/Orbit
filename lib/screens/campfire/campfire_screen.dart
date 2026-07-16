import 'package:flutter/material.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'campfire_chat_screen.dart';
import 'collab_playlist_screen.dart';
import 'song_battle_screen.dart';
import 'create_campfire_screen.dart';

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
  final bool isOwn;
  final String? pin;

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
    this.isOwn = false,
    this.pin,
  });
}

class CampfireScreen extends StatefulWidget {
  const CampfireScreen({super.key});

  @override
  State<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends State<CampfireScreen> {
  static const _defaultGroups = [
    CampfireGroup(
      id: '1', name: 'late night sessions', emoji: '🌙',
      lastMessage: 'this song is sending me rn', lastSender: 'maya',
      timeAgo: '2m', unreadCount: 5, isLive: true,
      bgColor: Color(0xFF6C63FF),
    ),
    CampfireGroup(
      id: '2', name: 'sunday chill squad', emoji: '☀️',
      lastMessage: "dropped a playlist for y'all", lastSender: 'zoe',
      timeAgo: '14m', unreadCount: 2, bgColor: Color(0xFFFF7A50),
    ),
    CampfireGroup(
      id: '3', name: 'deep focus 🎧', emoji: '🎧',
      lastMessage: 'lofi + lo-key vibing', lastSender: 'alex',
      timeAgo: '1h', bgColor: Color(0xFF00BCD4),
    ),
    CampfireGroup(
      id: '4', name: 'college crew', emoji: '🎓',
      lastMessage: 'anyone on for tonight?', lastSender: 'sam',
      timeAgo: '3h', unreadCount: 12, bgColor: Color(0xFF4CAF50),
    ),
    CampfireGroup(
      id: '5', name: 'hype house', emoji: '⚡',
      lastMessage: 'NEW DROP 🔥🔥🔥', lastSender: 'leo',
      timeAgo: '5h', bgColor: Color(0xFFFF8C42),
    ),
    CampfireGroup(
      id: '6', name: 'no one can find this 🔒', emoji: '🤫',
      lastMessage: 'invite only — shhh', lastSender: 'maya',
      timeAgo: '10m', unreadCount: 3, isSecret: true,
      bgColor: Color(0xFF2D3436),
    ),
  ];

  List<CampfireGroup> _allGroups() {
    final userCampfires = OrbitState().myCampfires.map((c) => CampfireGroup(
      id: c['id'] ?? '',
      name: c['name'] ?? 'untitled',
      emoji: c['emoji'] ?? '🔥',
      lastMessage: 'you created this campfire',
      lastSender: 'you',
      timeAgo: 'just now',
      isLive: c['isLive'] == true,
      isSecret: c['pin'] != null,
      bgColor: AuraTheme.accent,
      isOwn: true,
      pin: c['pin'] as String?,
    )).toList();

    return [...userCampfires, ..._defaultGroups];
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const CreateCampfireScreen()));
    if (created == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final groups = _allGroups();
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('campfire',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: AuraTheme.accent),
            tooltip: 'Song Battle',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SongBattleScreen())),
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AuraTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('new campfire',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No campfires yet — start one!',
                      style: TextStyle(color: AuraTheme.textMuted, fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: groups.length,
              itemBuilder: (context, i) => _GroupTile(
                group: groups[i],
                onDeleted: groups[i].isOwn ? () => setState(() {
                  OrbitState().myCampfires.removeWhere((c) => c['id'] == groups[i].id);
                  OrbitState().save();
                }) : null,
              ),
            ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final CampfireGroup group;
  final VoidCallback? onDeleted;
  const _GroupTile({required this.group, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CampfireChatScreen(group: group))),
      onLongPress: onDeleted != null
          ? () => showModalBottomSheet(
                context: context,
                backgroundColor: AuraTheme.card,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      title: Text('Delete "${group.name}"'),
                      onTap: () {
                        Navigator.pop(ctx);
                        onDeleted!();
                      },
                    ),
                  ]),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: group.isSecret && !group.isOwn
            ? BoxDecoration(
                color: const Color(0xFF2D3436).withOpacity(0.05),
                border: Border(
                    left: BorderSide(
                        color: const Color(0xFF2D3436).withOpacity(0.3),
                        width: 3)))
            : group.isOwn
                ? BoxDecoration(
                    border: Border(
                        left: BorderSide(color: AuraTheme.accent, width: 3)))
                : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  color: group.bgColor.withOpacity(0.15),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(group.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (group.isOwn)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.star_rounded,
                          size: 13, color: AuraTheme.accent),
                    ),
                  if (group.isSecret && !group.isOwn)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock_rounded,
                          size: 13, color: AuraTheme.textMuted),
                    ),
                  Expanded(
                    child: Text(group.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (group.isLive)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AuraTheme.accent,
                          borderRadius: BorderRadius.circular(6)),
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
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(group.timeAgo,
                  style: const TextStyle(
                      color: AuraTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 4),
              if (group.unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: AuraTheme.accent,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${group.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => CollabPlaylistScreen(group: group))),
            child: const Row(children: [
              Icon(Icons.queue_music_rounded, size: 14, color: AuraTheme.accent),
              SizedBox(width: 5),
              Text('collab playlist',
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
