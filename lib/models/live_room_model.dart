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
  final Map<String, int> reactions; // emoji -> count
  final bool isActive;
  final DateTime createdAt;
  final String genre; // vibe tag e.g. "late night", "hype", "chill"

  LiveRoom({
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

  factory LiveRoom.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LiveRoom(
      id: doc.id,
      hostUid: d['hostUid'] ?? '',
      hostName: d['hostName'] ?? '',
      hostEmoji: d['hostEmoji'] ?? '🎵',
      title: d['title'] ?? '',
      currentSongTitle: d['currentSongTitle'] ?? '',
      currentArtist: d['currentArtist'] ?? '',
      artUrl: d['artUrl'],
      listenerUids: List<String>.from(d['listenerUids'] ?? []),
      reactions: Map<String, int>.from(d['reactions'] ?? {}),
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genre: d['genre'] ?? 'vibes',
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

  LiveRoom copyWith({
    String? currentSongTitle,
    String? currentArtist,
    String? artUrl,
    List<String>? listenerUids,
    Map<String, int>? reactions,
    bool? isActive,
  }) =>
      LiveRoom(
        id: id,
        hostUid: hostUid,
        hostName: hostName,
        hostEmoji: hostEmoji,
        title: title,
        currentSongTitle: currentSongTitle ?? this.currentSongTitle,
        currentArtist: currentArtist ?? this.currentArtist,
        artUrl: artUrl ?? this.artUrl,
        listenerUids: listenerUids ?? this.listenerUids,
        reactions: reactions ?? this.reactions,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        genre: genre,
      );
}

class LiveRoomMessage {
  final String uid;
  final String displayName;
  final String emoji;
  final String text;
  final DateTime sentAt;
  final bool isReaction; // true = emoji burst, false = chat message

  LiveRoomMessage({
    required this.uid,
    required this.displayName,
    required this.emoji,
    required this.text,
    required this.sentAt,
    required this.isReaction,
  });

  factory LiveRoomMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LiveRoomMessage(
      uid: d['uid'] ?? '',
      displayName: d['displayName'] ?? '',
      emoji: d['emoji'] ?? '🎵',
      text: d['text'] ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReaction: d['isReaction'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'emoji': emoji,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'isReaction': isReaction,
      };
}
