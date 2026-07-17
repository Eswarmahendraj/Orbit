import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/orbit_state.dart';

// ── Social Service ─────────────────────────────────────────────────────────────
// Firestore schema:
//   /users/{uid}           — public profile
//   /follows/{uid_targetUid} — follow edge

class SocialService {
  static final SocialService _i = SocialService._();
  factory SocialService() => _i;
  SocialService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Publish current user's profile to Firestore ──────────────────────────

  Future<void> upsertProfile() async {
    final uid = _uid;
    if (uid == null) return;
    final s = OrbitState();
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': s.displayName,
        'username': s.username,
        'bio': s.bio,
        'mood': s.mood,
        'moodEmoji': s.moodEmoji,
        'vibeStatus': s.vibeStatus,
        'vibeStatusEmoji': s.vibeStatusEmoji,
        'pinnedSong': s.pinnedSong,
        'pinnedArtist': s.pinnedArtist,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Search users by display name (prefix match) ───────────────────────────

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final uid = _uid;
    try {
      final lower = query.trim().toLowerCase();
      final snap = await _db
          .collection('users')
          .orderBy('displayName')
          .startAt([lower])
          .endAt(['$lower'])
          .limit(20)
          .get();
      return snap.docs
          .map((d) => d.data())
          .where((d) => d['uid'] != uid) // exclude self
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Load suggested users (most recently active, exclude self) ────────────

  Future<List<Map<String, dynamic>>> getSuggested({int limit = 10}) async {
    final uid = _uid;
    try {
      final snap = await _db
          .collection('users')
          .orderBy('updatedAt', descending: true)
          .limit(limit + 1)
          .get();
      return snap.docs
          .map((d) => d.data())
          .where((d) => d['uid'] != uid)
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────

  Future<void> follow(String targetUid) async {
    final uid = _uid;
    if (uid == null || uid == targetUid) return;
    final docId = '${uid}_$targetUid';
    try {
      await _db.collection('follows').doc(docId).set({
        'followerId': uid,
        'targetId': targetUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Bump counts (best-effort, no transaction needed for demo)
      await _db.collection('users').doc(uid).set(
          {'followingCount': FieldValue.increment(1)},
          SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set(
          {'followersCount': FieldValue.increment(1)},
          SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> unfollow(String targetUid) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('follows').doc('${uid}_$targetUid').delete();
      await _db.collection('users').doc(uid).set(
          {'followingCount': FieldValue.increment(-1)},
          SetOptions(merge: true));
      await _db.collection('users').doc(targetUid).set(
          {'followersCount': FieldValue.increment(-1)},
          SetOptions(merge: true));
    } catch (_) {}
  }

  Future<bool> isFollowing(String targetUid) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('follows').doc('${uid}_$targetUid').get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ── Get follower / following counts for a user ────────────────────────────

  Future<Map<String, int>> getFollowCounts(String targetUid) async {
    try {
      final doc = await _db.collection('users').doc(targetUid).get();
      if (!doc.exists) return {'followers': 0, 'following': 0};
      final data = doc.data()!;
      return {
        'followers': (data['followersCount'] as num?)?.toInt() ?? 0,
        'following': (data['followingCount'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {'followers': 0, 'following': 0};
    }
  }

  // ── Get list of user UIDs that current user follows ───────────────────────

  Future<List<String>> getFollowingUids() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('follows')
          .where('followerId', isEqualTo: uid)
          .get();
      return snap.docs.map((d) => d.data()['targetId'] as String).toList();
    } catch (_) {
      return [];
    }
  }
}
