import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../home/dm_screen.dart';
import '../../widgets/orb_skeleton.dart';
import '../../widgets/orb_empty_state.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Sample data — replace with Firestore streams
  final _dms = [
    _DMData('Silver Tide', '🌿', AuraColors.moodCalm, 'energy'),
    _DMData('Amber Wisp', '🌸', AuraColors.moodHappy, 'calm'),
    _DMData('Velvet Storm', '🌟', AuraColors.moodEnergy, 'love'),
    _DMData('Cosmic Shore', '🔥', AuraColors.moodFocus, 'focus'),
    _DMData('Pale Ember', '💫', AuraColors.moodSad, 'sad'),
  ];

  final _circles = [
    _CircleData('Late Night Crew', ['Silver', 'Amber', 'Vel'], 3),
    _CircleData('Study Buddies', ['Cosmic', 'Pale', 'Gold'], 3),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Messages'),
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AuraColors.accent,
        labelColor: AuraColors.accent,
        unselectedLabelColor: AuraColors.textSecondary,
        tabs: const [
          Tab(text: 'Direct'),
          Tab(text: 'Circle Threads'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        // Direct messages — Firestore + local
        _FirestoreConvList(localDms: _dms),

        // Circle threads
        ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _circles.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Circle Thread'),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuraColors.accent,
                    side: const BorderSide(color: AuraColors.accent),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              );
            }
            return _CircleTile(data: _circles[i - 1])
                .animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05);
          },
        ),
      ],
    ),
  );
}

// ── Firestore conversation list (real users) + local fallback ─────────────────

class _FirestoreConvList extends StatelessWidget {
  final List<_DMData> localDms;
  const _FirestoreConvList({required this.localDms});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Not logged in — show local only
      return _LocalDmList(dms: localDms);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        // Loading skeleton
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonList(skeleton: MessageTileSkeleton(), count: 5);
        }
        final firestoreChats = snap.data?.docs ?? [];
        // Show empty state when no Firestore chats and no local DMs
        if (firestoreChats.isEmpty && localDms.isEmpty) {
          return EmptyDMsState(
            onFind: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Real Firestore conversations
            if (firestoreChats.isNotEmpty) ...[
              const Text('recent',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AuraColors.textSecondary)),
              const SizedBox(height: 8),
              ...firestoreChats.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final participants = List<String>.from(data['participants'] ?? []);
                final otherUid = participants.firstWhere(
                    (p) => p != uid, orElse: () => '');
                final names =
                    Map<String, dynamic>.from(data['participantNames'] ?? {});
                final otherName = names[otherUid]?.toString() ?? 'User';
                final lastMsg = data['lastMessage']?.toString() ?? '';
                // Load other user's pfpUrl from Firestore in real time
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users').doc(otherUid).get(),
                  builder: (_, userSnap) {
                    final pfpUrl = (userSnap.data?.data() as Map<String, dynamic>?)?['pfpUrl'] as String?;
                    return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AuraColors.accent.withOpacity(0.15),
                    backgroundImage: pfpUrl != null
                        ? CachedNetworkImageProvider(pfpUrl)
                        : null,
                    child: pfpUrl == null
                        ? Text(
                            otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                color: AuraColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
                          )
                        : null,
                  ),
                  title: Text(otherName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AuraColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AuraColors.textSecondary, size: 18),
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => DMScreen(
                      username: '@${otherName.toLowerCase().replaceAll(' ', '.')}',
                      displayName: otherName,
                      targetUid: otherUid,
                    ),
                  )),
                );
                  }, // FutureBuilder builder
                ); // FutureBuilder
              }),
              const Divider(height: 24),
            ],
            // Local/demo conversations
            ..._buildLocalDms(context),
          ],
        );
      },
    );
  }

  List<Widget> _buildLocalDms(BuildContext context) {
    return localDms.asMap().entries.map((e) {
      final i = e.key;
      final d = e.value;
      return _DMTile(
        data: d,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => DMScreen(
            username: '@${d.name.toLowerCase().replaceAll(' ', '.')}',
            displayName: d.name,
          ),
        )),
      ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05);
    }).toList();
  }
}

class _LocalDmList extends StatelessWidget {
  final List<_DMData> dms;
  const _LocalDmList({required this.dms});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: dms.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _DMTile(
        data: dms[i],
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => DMScreen(
            username: '@${dms[i].name.toLowerCase().replaceAll(' ', '.')}',
            displayName: dms[i].name,
          ),
        )),
      ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}

class _DMData {
  final String name, emoji, mood;
  final Color color;
  const _DMData(this.name, this.emoji, this.color, this.mood);
}

class _CircleData {
  final String name;
  final List<String> previewNames;
  final int memberCount;
  const _CircleData(this.name, this.previewNames, this.memberCount);
}

class _DMTile extends StatelessWidget {
  final _DMData data;
  final VoidCallback onTap;
  const _DMTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    onTap: onTap,
    leading: Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: data.color.withOpacity(0.2),
          child: Text(data.name[0],
              style: TextStyle(color: data.color,
                  fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AuraColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(data.emoji, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    ),
    title: Text(data.name,
        style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: data.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(data.mood,
              style: TextStyle(color: data.color, fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    ),
    trailing: const Icon(Icons.chevron_right,
        color: AuraColors.textSecondary, size: 18),
  );
}

class _CircleTile extends StatelessWidget {
  final _CircleData data;
  const _CircleTile({required this.data});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    onTap: () {},
    leading: SizedBox(
      width: 52, height: 52,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AuraColors.accent.withOpacity(0.15),
            child: const Icon(Icons.group_outlined,
                color: AuraColors.accent, size: 22),
          ),
        ],
      ),
    ),
    title: Text(data.name,
        style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text('${data.memberCount} members',
        style: const TextStyle(
            color: AuraColors.textSecondary, fontSize: 12)),
    trailing: const Icon(Icons.chevron_right,
        color: AuraColors.textSecondary, size: 18),
  );
}
