import 'package:cloud_firestore/cloud_firestore.dart';
import 'live_room_model.dart';

class LiveRoomService {
  static final LiveRoomService _instance = LiveRoomService._internal();
  factory LiveRoomService() => _instance;
  LiveRoomService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference get _rooms => _db.collection('live_rooms');

  // ── Create a new room ──────────────────────────────────────────────────────
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
    final room = LiveRoom(
      id: '',
      hostUid: hostUid,
      hostName: hostName,
      hostEmoji: hostEmoji,
      title: title,
      currentSongTitle: currentSongTitle,
      currentArtist: currentArtist,
      artUrl: artUrl,
      listenerUids: [hostUid],
      reactions: {},
      isActive: true,
      createdAt: DateTime.now(),
      genre: genre,
    );
    final ref = await _rooms.add(room.toMap());
    return ref.id;
  }

  // ── Join / leave ───────────────────────────────────────────────────────────
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

  // ── Update now playing (host only) ────────────────────────────────────────
  Future<void> updateNowPlaying({
    required String roomId,
    required String songTitle,
    required String artist,
    String? artUrl,
  }) async {
    await _rooms.doc(roomId).update({
      'currentSongTitle': songTitle,
      'currentArtist': artist,
      'artUrl': artUrl,
    });
  }

  // ── Send emoji reaction ────────────────────────────────────────────────────
  Future<void> sendReaction({
    required String roomId,
    required String uid,
    required String displayName,
    required String userEmoji,
    required String reactionEmoji,
  }) async {
    final batch = _db.batch();
    // increment reaction counter on room doc
    batch.update(_rooms.doc(roomId), {
      'reactions.$reactionEmoji': FieldValue.increment(1),
    });
    // add to messages subcollection
    final msgRef = _rooms.doc(roomId).collection('messages').doc();
    batch.set(msgRef, LiveRoomMessage(
      uid: uid,
      displayName: displayName,
      emoji: userEmoji,
      text: reactionEmoji,
      sentAt: DateTime.now(),
      isReaction: true,
    ).toMap());
    await batch.commit();
  }

  // ── Send chat message ──────────────────────────────────────────────────────
  Future<void> sendMessage({
    required String roomId,
    required String uid,
    required String displayName,
    required String userEmoji,
    required String text,
  }) async {
    await _rooms.doc(roomId).collection('messages').add(
          LiveRoomMessage(
            uid: uid,
            displayName: displayName,
            emoji: userEmoji,
            text: text,
            sentAt: DateTime.now(),
            isReaction: false,
          ).toMap(),
        );
  }

  // ── Close room (host only) ─────────────────────────────────────────────────
  Future<void> closeRoom(String roomId) async {
    await _rooms.doc(roomId).update({'isActive': false});
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<List<LiveRoom>> activeRoomsStream() {
    return _rooms
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => LiveRoom.fromFirestore(d)).toList());
  }

  Stream<LiveRoom?> roomStream(String roomId) {
    return _rooms.doc(roomId).snapshots().map(
          (d) => d.exists ? LiveRoom.fromFirestore(d) : null,
        );
  }

  Stream<List<LiveRoomMessage>> messagesStream(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limitToLast(50)
        .snapshots()
        .map((s) => s.docs.map((d) => LiveRoomMessage.fromFirestore(d)).toList());
  }
}
