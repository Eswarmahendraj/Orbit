import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_battle_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SongBattleService
// ─────────────────────────────────────────────────────────────────────────────

class SongBattleService {
  static final SongBattleService instance = SongBattleService._();
  SongBattleService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Create a new battle (challenger sends invite) ─────────────────────────

  Future<String> createBattle({
    required String opponentId,
    required String opponentName,
    String? opponentPhoto,
    required BattleSong mySong,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final mySnap = await _db.collection('users').doc(uid).get();
    final myData = mySnap.data() as Map<String, dynamic>? ?? {};
    final myName = myData['name'] as String? ?? 'Someone';
    final myPhoto = myData['photoUrl'] as String?;

    final now = DateTime.now();
    final ref = await _db.collection('song_battles').add({
      'challengerId': uid,
      'challengerName': myName,
      'challengerPhoto': myPhoto,
      'challengerSong': mySong.toMap(),
      'opponentId': opponentId,
      'opponentName': opponentName,
      'opponentPhoto': opponentPhoto,
      'opponentSong': null,
      'status': 'pending',
      'votesChallenger': 0,
      'votesOpponent': 0,
      'editRequest': null,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });

    // Send push notification to opponent
    await _sendBattleNotification(
      recipientUid: opponentId,
      title: '⚔️ Song Battle Challenge!',
      body: '$myName challenged you to a Song Battle. Accept and pick your song!',
      data: {
        'type': 'song_battle_invite',
        'battleId': ref.id,
        'challengerName': myName,
      },
    );

    return ref.id;
  }

  // ── Opponent accepts and sets their song ──────────────────────────────────

  Future<void> acceptBattle({
    required String battleId,
    required BattleSong mySong,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _db.collection('song_battles').doc(battleId);
    await ref.update({
      'opponentSong': mySong.toMap(),
      'status': 'active',
    });

    // Notify challenger that battle is live
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final challengerId = data['challengerId'] as String? ?? '';
    final opponentName = data['opponentName'] as String? ?? 'Your opponent';

    await _sendBattleNotification(
      recipientUid: challengerId,
      title: '🥊 Battle is ON!',
      body: '$opponentName accepted your challenge and picked their song. Let the votes decide!',
      data: {
        'type': 'song_battle_active',
        'battleId': battleId,
      },
    );
  }

  // ── Decline a pending battle ──────────────────────────────────────────────

  Future<void> declineBattle(String battleId) async {
    await _db.collection('song_battles').doc(battleId).update({
      'status': 'completed',
    });
  }

  // ── Vote for a side ───────────────────────────────────────────────────────

  Future<void> vote({
    required String battleId,
    required bool forChallenger,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    // Track who voted to prevent duplicates
    final voteRef = _db
        .collection('song_battles')
        .doc(battleId)
        .collection('votes')
        .doc(uid);

    final existing = await voteRef.get();
    if (existing.exists) return; // already voted

    await voteRef.set({'forChallenger': forChallenger, 'votedAt': FieldValue.serverTimestamp()});

    await _db.collection('song_battles').doc(battleId).update({
      if (forChallenger) 'votesChallenger': FieldValue.increment(1)
      else 'votesOpponent': FieldValue.increment(1),
    });
  }

  // ── Request a song edit ───────────────────────────────────────────────────

  Future<void> requestSongEdit({
    required String battleId,
    required BattleSong newSong,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _db.collection('song_battles').doc(battleId);
    await ref.update({
      'editRequest': EditRequest(requestedBy: uid, newSong: newSong).toMap(),
    });

    // Notify the other player
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final challengerId = data['challengerId'] as String? ?? '';
    final opponentId = data['opponentId'] as String? ?? '';
    final otherUid = uid == challengerId ? opponentId : challengerId;
    final myName = uid == challengerId
        ? (data['challengerName'] as String? ?? 'Your opponent')
        : (data['opponentName'] as String? ?? 'Your opponent');

    await _sendBattleNotification(
      recipientUid: otherUid,
      title: '✏️ Song Edit Request',
      body: '$myName wants to change their song. Tap to accept or reject.',
      data: {
        'type': 'song_battle_edit_request',
        'battleId': battleId,
      },
    );
  }

  // ── Accept an edit request ────────────────────────────────────────────────

  Future<void> acceptEditRequest(String battleId) async {
    final uid = _uid;
    if (uid == null) return;

    final snap = await _db.collection('song_battles').doc(battleId).get();
    final data = snap.data() as Map<String, dynamic>? ?? {};
    final editReq = data['editRequest'] as Map<String, dynamic>?;
    if (editReq == null) return;

    final requestedBy = editReq['requestedBy'] as String;
    final challengerId = data['challengerId'] as String? ?? '';
    final isChallenger = requestedBy == challengerId;

    await _db.collection('song_battles').doc(battleId).update({
      if (isChallenger)
        'challengerSong': editReq['newSong']
      else
        'opponentSong': editReq['newSong'],
      'editRequest': null,
    });
  }

  // ── Reject an edit request ────────────────────────────────────────────────

  Future<void> rejectEditRequest(String battleId) async {
    await _db.collection('song_battles').doc(battleId).update({
      'editRequest': null,
    });
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// All battles involving the current user (challenger or opponent)
  Stream<List<SongBattle>> myBattlesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    // Merge two streams manually — battles where I'm challenger
    final asChallenger = _db
        .collection('song_battles')
        .where('challengerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'active'])
        .snapshots()
        .map((s) => s.docs.map(SongBattle.fromFirestore).toList());

    return asChallenger; // We'll also query as opponent in the UI
  }

  /// Pending invites where I'm the opponent
  Stream<List<SongBattle>> pendingInvitesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('song_battles')
        .where('opponentId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map(SongBattle.fromFirestore).toList());
  }

  /// Active battles involving me (for showing in Pulse)
  Stream<List<SongBattle>> activeBattlesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('song_battles')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(SongBattle.fromFirestore).toList());
  }

  /// Single battle stream
  Stream<SongBattle?> battleStream(String battleId) => _db
      .collection('song_battles')
      .doc(battleId)
      .snapshots()
      .map((s) => s.exists ? SongBattle.fromFirestore(s) : null);

  /// Whether current user has voted on a battle
  Future<bool?> myVote(String battleId) async {
    final uid = _uid;
    if (uid == null) return null;
    final snap = await _db
        .collection('song_battles')
        .doc(battleId)
        .collection('votes')
        .doc(uid)
        .get();
    if (!snap.exists) return null;
    return snap.data()?['forChallenger'] as bool?;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _sendBattleNotification({
    required String recipientUid,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final tokenSnap = await _db
          .collection('users')
          .doc(recipientUid)
          .collection('tokens')
          .get();
      if (tokenSnap.docs.isEmpty) return;

      await _db.collection('_notifications').add({
        'to': recipientUid,
        'tokens': tokenSnap.docs.map((d) => d['token'] as String).toList(),
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      // Silent fail — battle still works without push
    }
  }

  Future<List<Map<String, dynamic>>> getFollowing() async {
    final uid = _uid;
    if (uid == null) return [];
    try {
      final snap = await _db
          .collection('follows')
          .where('followerId', isEqualTo: uid)
          .get();
      final uids = snap.docs
          .map((d) => d.data()['targetId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (uids.isEmpty) return [];
      final userSnaps = await Future.wait(
          uids.map((id) => _db.collection('users').doc(id).get()));
      return userSnaps.where((s) => s.exists).map((s) {
        final d = s.data() as Map<String, dynamic>;
        return {
          'uid': s.id,
          'name': d['name'] as String? ?? '',
          'photoUrl': d['photoUrl'] as String?,
          'auraName': d['auraName'] as String? ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
