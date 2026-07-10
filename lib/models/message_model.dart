import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, pulse, song, image, video }
enum PostVisibility { public, closeCircle, private }

class Message {
  final String id;
  final String senderId;
  final String senderAuraName;
  final String content;
  final MessageType type;
  final DateTime createdAt; // stored internally, never shown to users
  final bool isDeleted;

  Message({
    required this.id,
    required this.senderId,
    required this.senderAuraName,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      senderAuraName: d['senderAuraName'] ?? '',
      content: d['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isDeleted: d['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderAuraName': senderAuraName,
    'content': content,
    'type': type.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'isDeleted': isDeleted,
  };
}

class CampfireRoom {
  final String id;
  final String mood;
  final List<String> interests;
  final List<String> memberIds;
  final int memberCount;
  final DateTime createdAt;
  final bool isActive;

  CampfireRoom({
    required this.id,
    required this.mood,
    required this.interests,
    required this.memberIds,
    required this.memberCount,
    required this.createdAt,
    this.isActive = true,
  });

  factory CampfireRoom.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CampfireRoom(
      id: doc.id,
      mood: d['mood'] ?? 'calm',
      interests: List<String>.from(d['interests'] ?? []),
      memberIds: List<String>.from(d['memberIds'] ?? []),
      memberCount: d['memberCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isActive: d['isActive'] ?? true,
    );
  }
}

class AuraPost {
  final String id;
  final String authorId;
  final String authorAuraName;
  final String content;
  final String? mediaUrl;
  final String postType; // story, song, video, reel, momentCard
  final PostVisibility visibility;
  final int pulseCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime expiresAt;

  AuraPost({
    required this.id,
    required this.authorId,
    required this.authorAuraName,
    required this.content,
    this.mediaUrl,
    required this.postType,
    required this.visibility,
    this.pulseCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AuraPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuraPost(
      id: doc.id,
      authorId: d['authorId'] ?? '',
      authorAuraName: d['authorAuraName'] ?? '',
      content: d['content'] ?? '',
      mediaUrl: d['mediaUrl'],
      postType: d['postType'] ?? 'story',
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == (d['visibility'] ?? 'closeCircle'),
        orElse: () => PostVisibility.closeCircle,
      ),
      pulseCount: d['pulseCount'] ?? 0,
      viewCount: d['viewCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      expiresAt: (d['expiresAt'] as Timestamp).toDate(),
    );
  }
}
