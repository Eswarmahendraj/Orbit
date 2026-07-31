import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Notification Model
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

enum OrbitNotifType {
  liveRoomInvite,
  collabPlaylistInvite,
  vibeMatchReceived,
  songShared,
  newFollower,
  mention,
  concertAlert,
}

class OrbitNotif {
  final String id;
  final String uid;           // recipient
  final String senderUid;
  final String senderName;
  final OrbitNotifType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionId;     // roomId, playlistId, etc.
  final bool isRead;
  final DateTime createdAt;

  const OrbitNotif({
    required this.id,
    required this.uid,
    required this.senderUid,
    required this.senderName,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionId,
    this.isRead = false,
    required this.createdAt,
  });

  OrbitNotif copyWith({bool? isRead}) => OrbitNotif(
        id: id,
        uid: uid,
        senderUid: senderUid,
        senderName: senderName,
        type: type,
        title: title,
        body: body,
        imageUrl: imageUrl,
        actionId: actionId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'senderUid': senderUid,
        'senderName': senderName,
        'type': type.index,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'actionId': actionId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory OrbitNotif.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrbitNotif(
      id: doc.id,
      uid: d['uid'] ?? '',
      senderUid: d['senderUid'] ?? '',
      senderName: d['senderName'] ?? 'Someone',
      type: OrbitNotifType.values[d['type'] as int? ?? 3],
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      imageUrl: d['imageUrl'] as String?,
      actionId: d['actionId'] as String?,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Notification Service
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class OrbitNotifService {
  static final OrbitNotifService _i = OrbitNotifService._();
  factory OrbitNotifService() => _i;
  OrbitNotifService._();

  final _col = FirebaseFirestore.instance.collection('orbit_notifications');

  // ââ Streams ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
  Stream<List<OrbitNotif>> myNotifsStream(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(OrbitNotif.fromFirestore).toList());
  }

  Stream<int> unreadCountStream(String uid) {
    return _col
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.size);
  }

  // ââ Actions ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
  Future<void> send(OrbitNotif n) async {
    await _col.add(n.toMap());
  }

  Future<void> markRead(String notifId) async {
    await _col.doc(notifId).update({'isRead': true});
  }

  Future<void> markAllRead(String uid) async {
    final snap = await _col
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotif(String notifId) async {
    await _col.doc(notifId).delete();
  }

  // ââ Send helpers âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
  Future<void> sendLiveRoomInvite({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String roomId,
    required String roomName,
  }) =>
      send(OrbitNotif(
        id: '',
        uid: toUid,
        senderUid: fromUid,
        senderName: fromName,
        type: OrbitNotifType.liveRoomInvite,
        title: '$fromName started a Live Room',
        body: '"$roomName" â join now ðï¸',
        actionId: roomId,
        createdAt: DateTime.now(),
      ));

  Future<void> sendCollabInvite({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String playlistId,
    required String playlistName,
  }) =>
      send(OrbitNotif(
        id: '',
        uid: toUid,
        senderUid: fromUid,
        senderName: fromName,
        type: OrbitNotifType.collabPlaylistInvite,
        title: '$fromName added you to a playlist',
        body: '"$playlistName" â add your tracks ðµ',
        actionId: playlistId,
        createdAt: DateTime.now(),
      ));

  Future<void> sendVibeMatch({
    required String toUid,
    required String fromUid,
    required String fromName,
    required int score,
  }) =>
      send(OrbitNotif(
        id: '',
        uid: toUid,
        senderUid: fromUid,
        senderName: fromName,
        type: OrbitNotifType.vibeMatchReceived,
        title: '$fromName checked your vibe',
        body: 'You two are $score% compatible ð®',
        createdAt: DateTime.now(),
      ));

  Future<void> sendFollowNotif({
    required String toUid,
    required String fromUid,
    required String fromName,
  }) =>
      send(OrbitNotif(
        id: '',
        uid: toUid,
        senderUid: fromUid,
        senderName: fromName,
        type: OrbitNotifType.newFollower,
        title: '$fromName started following you',
        body: 'Check out their profile ð¤',
        createdAt: DateTime.now(),
      ));

  Future<void> sendSongShare({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String songTitle,
    required String artist,
  }) =>
      send(OrbitNotif(
        id: '',
        uid: toUid,
        senderUid: fromUid,
        senderName: fromName,
        type: OrbitNotifType.songShared,
        title: '$fromName shared a song with you',
        body: '$songTitle â $artist ð¶',
        createdAt: DateTime.now(),
      ));
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Screen
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;
    final state = Provider.of<OrbitState>(context);
    final svc = OrbitNotifService();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => svc.markAllRead(state.uid),
            child: Text(
              'Mark all read',
              style: TextStyle(
                  color: theme.accent, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<OrbitNotif>>(
        stream: svc.myNotifsStream(state.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.accent));
          }
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) return _buildEmpty(theme);

          // Split into today vs earlier
          final now = DateTime.now();
          final today = notifs
              .where((n) =>
                  n.createdAt.year == now.year &&
                  n.createdAt.month == now.month &&
                  n.createdAt.day == now.day)
              .toList();
          final earlier = notifs
              .where((n) => !(n.createdAt.year == now.year &&
                  n.createdAt.month == now.month &&
                  n.createdAt.day == now.day))
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (today.isNotEmpty) ...[
                _SectionHeader(label: 'Today', theme: theme),
                ...today.map((n) => _NotifTile(notif: n, theme: theme, svc: svc)),
              ],
              if (earlier.isNotEmpty) ...[
                _SectionHeader(label: 'Earlier', theme: theme),
                ...earlier
                    .map((n) => _NotifTile(notif: n, theme: theme, svc: svc)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(AuraTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: theme.textMuted, size: 56),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'New activity will show up here',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Section Header
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _SectionHeader extends StatelessWidget {
  final String label;
  final AuraTheme theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Text(
        label,
        style: TextStyle(
            color: theme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6),
      ),
    );
  }
}

// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
// Notification Tile
// âââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ

class _NotifTile extends StatelessWidget {
  final OrbitNotif notif;
  final AuraTheme theme;
  final OrbitNotifService svc;
  const _NotifTile(
      {required this.notif, required this.theme, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => svc.deleteNotif(notif.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.15),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent, size: 24),
      ),
      child: InkWell(
        onTap: () {
          if (!notif.isRead) svc.markRead(notif.id);
        },
        child: Container(
          color: notif.isRead
              ? Colors.transparent
              : theme.accent.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _typeColor(notif.type).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(_typeEmoji(notif.type),
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: notif.isRead
                              ? FontWeight.w500
                              : FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notif.createdAt),
                      style:
                          TextStyle(color: theme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!notif.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(OrbitNotifType type) {
    switch (type) {
      case OrbitNotifType.liveRoomInvite:
        return Colors.redAccent;
      case OrbitNotifType.collabPlaylistInvite:
        return Colors.greenAccent;
      case OrbitNotifType.vibeMatchReceived:
        return Colors.purpleAccent;
      case OrbitNotifType.songShared:
        return Colors.blueAccent;
      case OrbitNotifType.newFollower:
        return Colors.orangeAccent;
      case OrbitNotifType.mention:
        return Colors.tealAccent;
      case OrbitNotifType.concertAlert:
        return Colors.pinkAccent;
    }
  }

  String _typeEmoji(OrbitNotifType type) {
    switch (type) {
      case OrbitNotifType.liveRoomInvite:
        return 'ðï¸';
      case OrbitNotifType.collabPlaylistInvite:
        return 'ðµ';
      case OrbitNotifType.vibeMatchReceived:
        return 'ð®';
      case OrbitNotifType.songShared:
        return 'ð¶';
      case OrbitNotifType.newFollower:
        return 'ð¤';
      case OrbitNotifType.mention:
        return 'ð¬';
      case OrbitNotifType.concertAlert:
        return 'ð«';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
