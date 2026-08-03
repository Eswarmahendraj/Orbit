import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/message_model.dart';
import 'notification_service.dart';

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
    if (senderId.isEmpty || receiverId.isEmpty) return;
    final chatId = _chatId(senderId, receiverId);
    try {
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
      });
      // Update last message preview in chat metadata
      await _db.collection('chats').doc(chatId).set({
        'participants': [senderId, receiverId],
        'lastMessageAt': Timestamp.now(),
        'lastSenderId': senderId,
        'participantNames': {senderId: senderAuraName},
      }, SetOptions(merge: true));

      // Push notification to recipient
      NotificationService().sendDmNotification(
        recipientUid: receiverId,
        senderName: senderAuraName,
        messageText: content,
        dmId: chatId,
      );
    } catch (e) {
      debugPrint('ChatService.sendMessage error: $e');
    }
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
    try {
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
    } catch (e) {
      debugPrint('ChatService.sendCampfireMessage error: $e');
    }
  }

  // ── Circle Thread (Group Chat) ─────────────────────────────
  Future<String> createCircleThread({
    required String name,
    required String creatorId,
    required List<String> invitedIds,
  }) async {
    try {
      final doc = await _db.collection('circleThreads').add({
        'name': name,
        'creatorId': creatorId,
        'members': [creatorId],
        'invitedIds': invitedIds,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
      return doc.id;
    } catch (e) {
      debugPrint('ChatService.createCircleThread error: $e');
      return '';
    }
  }

  Future<void> joinCircleThread(String threadId, String userId) async {
    try {
      await _db.collection('circleThreads').doc(threadId).update({
        'members': FieldValue.arrayUnion([userId]),
        'invitedIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('ChatService.joinCircleThread error: $e');
    }
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
    try {
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
    } catch (e) {
      debugPrint('ChatService.sendCircleMessage error: $e');
    }
  }

  Future<void> leaveCircleThread(String threadId, String userId) async {
    try {
      // Silent exit — no notification sent to group
      await _db.collection('circleThreads').doc(threadId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('ChatService.leaveCircleThread error: $e');
    }
  }

  // ── Typing Indicator ───────────────────────────────────────
  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
    bool isCampfire = false,
  }) async {
    try {
      final collection = isCampfire ? 'campfireRooms' : 'chats';
      await _db.collection(collection).doc(chatId).set({
        'typing': {userId: isTyping},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ChatService.setTyping error: $e');
    }
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
