import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuraService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Update current mood ────────────────────────────────────
  Future<void> updateMood(String mood) async {
    if (_uid == null) return;
    final colorMap = {
      'calm':   0xFF4FC3F7,
      'energy': 0xFFFF6B6B,
      'happy':  0xFFFFD54F,
      'focus':  0xFF81C784,
      'love':   0xFFFF80AB,
      'sad':    0xFF7986CB,
    };
    await _db.collection('users').doc(_uid).update({
      'currentMood': mood,
      'auraColor': colorMap[mood] ?? 0xFF6C63FF,
    });
  }

  // ── Update Spotify track ───────────────────────────────────
  Future<void> updateSpotifyTrack(String trackName) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'spotifyTrack': trackName,
    });
  }

  // ── Set online / offline ───────────────────────────────────
  Future<void> setOnline(bool online) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({'isOnline': online});
  }

  // ── Get friends' auras (rooted connections) ────────────────
  Stream<List<Map<String, dynamic>>> getFriendsAuras(List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Send a Pulse ───────────────────────────────────────────
  Future<void> sendPulse({
    required String toUserId,
    required String fromAuraName,
    String type = 'seen', // seen | energy | vibe
  }) async {
    await _db.collection('pulses').add({
      'from': _uid,
      'fromAuraName': fromAuraName,
      'to': toUserId,
      'type': type,
      'createdAt': Timestamp.now(),
    });
  }

  // ── Campfire: find matching rooms by mood + interests ──────
  Future<List<Map<String, dynamic>>> findMatchingRooms({
    required String mood,
    required List<String> interests,
  }) async {
    final snap = await _db
        .collection('campfireRooms')
        .where('isActive', isEqualTo: true)
        .where('mood', isEqualTo: mood)
        .limit(10)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // ── Join / leave Campfire room ─────────────────────────────
  Future<void> joinRoom(String roomId) async {
    if (_uid == null) return;
    await _db.collection('campfireRooms').doc(roomId).update({
      'memberIds': FieldValue.arrayUnion([_uid]),
      'memberCount': FieldValue.increment(1),
    });
  }

  Future<void> leaveRoom(String roomId) async {
    if (_uid == null) return;
    await _db.collection('campfireRooms').doc(roomId).update({
      'memberIds': FieldValue.arrayRemove([_uid]),
      'memberCount': FieldValue.increment(-1),
    });
  }

  // ── Nudge someone in a Campfire room ──────────────────────
  Future<void> sendNudge({
    required String toUserId,
    required String fromAuraName,
    required String roomId,
  }) async {
    await _db.collection('nudges').add({
      'from': _uid,
      'fromAuraName': fromAuraName,
      'to': toUserId,
      'roomId': roomId,
      'status': 'pending', // pending | accepted | declined
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> respondNudge(String nudgeId, bool accept) async {
    await _db.collection('nudges').doc(nudgeId).update({
      'status': accept ? 'accepted' : 'declined',
    });
    // If accepted, open a Pocket between the two users
    if (accept) {
      final nudge = await _db.collection('nudges').doc(nudgeId).get();
      final data = nudge.data()!;
      await _db.collection('pockets').add({
        'participants': [data['from'], data['to']],
        'fromAuraName': data['fromAuraName'],
        'roomId': data['roomId'],
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
    }
  }

  // ── Root a connection ─────────────────────────────────────
  Future<void> rootConnection(String otherUserId) async {
    if (_uid == null) return;
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(_uid), {
      'rootedConnections': FieldValue.arrayUnion([otherUserId]),
    });
    batch.update(_db.collection('users').doc(otherUserId), {
      'rootedConnections': FieldValue.arrayUnion([_uid]),
    });
    // Save connection tenure start
    final ids = [_uid!, otherUserId]..sort();
    batch.set(_db.collection('connections').doc(ids.join('_')), {
      'users': ids,
      'rootedAt': Timestamp.now(),
      'tenureDays': 0,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // ── Unroot (soft drift / full unroot) ─────────────────────
  Future<void> unrootConnection(String otherUserId) async {
    if (_uid == null) return;
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(_uid), {
      'rootedConnections': FieldValue.arrayRemove([otherUserId]),
    });
    batch.update(_db.collection('users').doc(otherUserId), {
      'rootedConnections': FieldValue.arrayRemove([_uid]),
    });
    await batch.commit();
    // No notification sent — silent by design
  }

  // ── Update Close Circle ────────────────────────────────────
  Future<void> addToCloseCircle(String userId) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'closeCircle': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeFromCloseCircle(String userId) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'closeCircle': FieldValue.arrayRemove([userId]),
    });
    // No notification — silent by design
  }

  // ── Tenure calculation ─────────────────────────────────────
  Future<int> getTenureDays(String otherUserId) async {
    if (_uid == null) return 0;
    final ids = [_uid!, otherUserId]..sort();
    final doc = await _db.collection('connections').doc(ids.join('_')).get();
    if (!doc.exists) return 0;
    final rootedAt = (doc.data()!['rootedAt'] as Timestamp).toDate();
    return DateTime.now().difference(rootedAt).inDays;
  }
}
