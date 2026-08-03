import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_room_model.dart';

class LiveRoomService {
  final _rooms = FirebaseFirestore.instance.collection('live_rooms');

  Stream<List<LiveRoom>> activeRoomsStream() {
    return _rooms
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LiveRoom.fromDoc).toList());
  }

  Stream<LiveRoom?> roomStream(String roomId) {
    return _rooms.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return LiveRoom.fromDoc(doc);
    });
  }

  Stream<List<LiveRoomMessage>> messagesStream(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .limitToLast(50)
        .snapshots()
        .map((snap) => snap.docs.map(LiveRoomMessage.fromDoc).toList());
  }

  Future<String> createRoom({
    required String hostUid,
    required String hostName,
    required String hostEmoji,
    required String title,
    required String currentSongTitle,
    required String currentArtist,
    String? artUrl,
    required String genre,
  }) async {
    final doc = await _rooms.add({
      'hostUid': hostUid,
      'hostName': hostName,
      'hostEmoji': hostEmoji,
      'title': title,
      'currentSongTitle': currentSongTitle,
      'currentArtist': currentArtist,
      'artUrl': artUrl,
      'listenerUids': [hostUid],
      'reactions': <String, dynamic>{},
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'genre': genre,
    });
    return doc.id;
  }

  Future<void> joinRoom(String roomId, String uid) async {
    await _rooms.doc(roomId).update({
      'listenerUids': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    await _rooms.doc(roomId).update({
      'listenerUids': FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> closeRoom(String roomId) async {
    await _rooms.doc(roomId).update({'isActive': false});
  }

  Future<void> sendReaction({
    required String roomId,
    required String uid,
    required String displayName,
    required String userEmoji,
    required String reactionEmoji,
  }) async {
    await _rooms.doc(roomId).collection('messages').add({
      'uid': uid,
      'displayName': displayName,
      'emoji': userEmoji,
      'text': reactionEmoji,
      'isReaction': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String uid,
    required String displayName,
    required String userEmoji,
    required String text,
  }) async {
    await _rooms.doc(roomId).collection('messages').add({
      'uid': uid,
      'displayName': displayName,
      'emoji': userEmoji,
      'text': text,
      'isReaction': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
