import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── 1-on-1 Chat ───────────────────────────────────────────
  String _chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Stream<List<Message>> getMessages(String uid1, String uid2) {
    return _db
        .collection('chats')
        .doc(_chatId(uid1, uid2))
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Message.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderAuraName,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final chatId = _chatId(senderId, receiverId);
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderAuraName': senderAuraName,
      'content': content,
      'type': type.name,
      'createdAt': Timestamp.now(),
      'isDeleted': false,
      // No timestamp shown to users — stored for ordering only
    });
    // Update last message preview in chat metadata
    await _db.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessageAt': Timestamp.now(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  // ── Campfire Room Chat ─────────────────────────────────────
  Stream<List<Message>> getCampfireMessages(String roomId) {
    return _db
        .collection('campfireRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limitToLast(100)
        .snapshots()
        .map((s) => s.docs.map(Message.fromFirestore).toList());
  }

  Future<void> sendCampfireMessage({
    required String roomId,
    required String senderId,
    required String senderAuraName,
    required String content,
  }) async {
    await _db
        .collection('campfireRooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderAuraName': senderAuraName,
      'content': content,
      'type': 'text',
      'createdAt': Timestamp.now(),
      'isDeleted': false,
    });
  }

  // ── Circle Thread (Group Chat) ─────────────────────────────
  Future<String> createCircleThread({
    required String name,
    required String creatorId,
    required List<String> invitedIds,
  }) async {
    final doc = await _db.collection('circleThreads').add({
      'name': name,
      'creatorId': creatorId,
      'members': [creatorId],
      'invitedIds': invitedIds,
      'createdAt': Timestamp.now(),
      'isActive': true,
    });
    return doc.id;
  }

  Future<void> joinCircleThread(String threadId, String userId) async {
    await _db.collection('circleThreads').doc(threadId).update({
      'members': FieldValue.arrayUnion([userId]),
      'invitedIds': FieldValue.arrayRemove([userId]),
    });
  }

  Stream<List<Message>> getCircleMessages(String threadId) {
    return _db
        .collection('circleThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Message.fromFirestore).toList());
  }

  Future<void> sendCircleMessage({
    required String threadId,
    required String senderId,
    required String senderAuraName,
    required String content,
  }) async {
    await _db
        .collection('circleThreads')
        .doc(threadId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'senderAuraName': senderAuraName,
      'content': content,
      'type': 'text',
      'createdAt': Timestamp.now(),
      'isDeleted': false,
    });
  }

  Future<void> leaveCircleThread(String threadId, String userId) async {
    // Silent exit — no notification sent to group
    await _db.collection('circleThreads').doc(threadId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Typing Indicator ───────────────────────────────────────
  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
    bool isCampfire = false,
  }) async {
    final collection = isCampfire ? 'campfireRooms' : 'chats';
    await _db.collection(collection).doc(chatId).set({
      'typing': {userId: isTyping},
    }, SetOptions(merge: true));
  }

  Stream<Map<String, bool>> getTypingStatus(String chatId,
      {bool isCampfire = false}) {
    final collection = isCampfire ? 'campfireRooms' : 'chats';
    return _db
        .collection(collection)
        .doc(chatId)
        .snapshots()
        .map((s) {
      final data = s.data();
      if (data == null || data['typing'] == null) return {};
      return Map<String, bool>.from(data['typing']);
    });
  }
}
