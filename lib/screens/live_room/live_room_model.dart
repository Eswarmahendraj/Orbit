import 'package:cloud_firestore/cloud_firestore.dart';

class LiveRoom {
  final String id;
  final String hostUid;
  final String hostName;
  final String hostEmoji;
  final String title;
  final String currentSongTitle;
  final String currentArtist;
  final String? artUrl;
  final List<String> listenerUids;
  final Map<String, dynamic> reactions;
  final bool isActive;
  final DateTime createdAt;
  final String genre;

  const LiveRoom({
    required this.id,
    required this.hostUid,
    required this.hostName,
    required this.hostEmoji,
    required this.title,
    required this.currentSongTitle,
    required this.currentArtist,
    this.artUrl,
    required this.listenerUids,
    required this.reactions,
    required this.isActive,
    required this.createdAt,
    required this.genre,
  });

  int get listenerCount => listenerUids.length;

  factory LiveRoom.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LiveRoom(
      id: doc.id,
      hostUid: d['hostUid'] as String? ?? '',
      hostName: d['hostName'] as String? ?? 'Unknown',
      hostEmoji: d['hostEmoji'] as String? ?? '🎵',
      title: d['title'] as String? ?? 'Live Room',
      currentSongTitle: d['currentSongTitle'] as String? ?? '',
      currentArtist: d['currentArtist'] as String? ?? '',
      artUrl: d['artUrl'] as String?,
      listenerUids: List<String>.from(d['listenerUids'] ?? []),
      reactions: Map<String, dynamic>.from(d['reactions'] ?? {}),
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genre: d['genre'] as String? ?? 'vibes',
    );
  }

  Map<String, dynamic> toMap() => {
    'hostUid': hostUid,
    'hostName': hostName,
    'hostEmoji': hostEmoji,
    'title': title,
    'currentSongTitle': currentSongTitle,
    'currentArtist': currentArtist,
    'artUrl': artUrl,
    'listenerUids': listenerUids,
    'reactions': reactions,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'genre': genre,
  };
}

class LiveRoomMessage {
  final String uid;
  final String displayName;
  final String emoji;
  final String text;
  final bool isReaction;
  final DateTime timestamp;

  const LiveRoomMessage({
    required this.uid,
    required this.displayName,
    required this.emoji,
    required this.text,
    required this.isReaction,
    required this.timestamp,
  });

  factory LiveRoomMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LiveRoomMessage(
      uid: d['uid'] as String? ?? '',
      displayName: d['displayName'] as String? ?? 'User',
      emoji: d['emoji'] as String? ?? '🎵',
      text: d['text'] as String? ?? '',
      isReaction: d['isReaction'] as bool? ?? false,
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
