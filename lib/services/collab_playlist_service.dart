import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collab_playlist_model.dart';

/// Firestore-backed service for collaborative playlists.
class CollabPlaylistService {
  static final CollabPlaylistService _instance =
      CollabPlaylistService._internal();
  factory CollabPlaylistService() => _instance;
  CollabPlaylistService._internal();

  final _col = FirebaseFirestore.instance.collection('collab_playlists');

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<String> createPlaylist({
    required String ownerUid,
    required String ownerName,
    required String name,
  }) async {
    final doc = await _col.add({
      'name': name,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'memberUids': [ownerUid],
      'tracks': [],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ── Members ────────────────────────────────────────────────────────────────

  Future<void> joinPlaylist(String playlistId, String uid) async {
    await _col.doc(playlistId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
  }

  // ── Tracks ─────────────────────────────────────────────────────────────────

  Future<void> addTrack({
    required String playlistId,
    required CollabTrack track,
  }) async {
    await _col.doc(playlistId).update({
      'tracks': FieldValue.arrayUnion([track.toMap()]),
    });
  }

  /// Toggle vote on a track.
  Future<void> voteTrack({
    required String playlistId,
    required String trackId,
    required String uid,
    required List<CollabTrack> currentTracks,
  }) async {
    final idx = currentTracks.indexWhere((t) => t.id == trackId);
    if (idx == -1) return;

    final track = currentTracks[idx];
    final hasVoted = track.hasVoted(uid);
    final updated = track.copyWith(
      votes: hasVoted ? track.votes - 1 : track.votes + 1,
      votedByUids: hasVoted
          ? (List<String>.from(track.votedByUids)..remove(uid))
          : (List<String>.from(track.votedByUids)..add(uid)),
    );

    final newTracks = List<CollabTrack>.from(currentTracks);
    newTracks[idx] = updated;

    await _col.doc(playlistId).update({
      'tracks': newTracks.map((t) => t.toMap()).toList(),
    });
  }

  Future<void> removeTrack({
    required String playlistId,
    required String trackId,
    required List<CollabTrack> currentTracks,
  }) async {
    final newTracks =
        currentTracks.where((t) => t.id != trackId).toList();
    await _col.doc(playlistId).update({
      'tracks': newTracks.map((t) => t.toMap()).toList(),
    });
  }

  // ── Control ────────────────────────────────────────────────────────────────

  Future<void> closePlaylist(String playlistId) async {
    await _col.doc(playlistId).update({'isActive': false});
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<CollabPlaylist>> myPlaylistsStream(String uid) {
    return _col
        .where('memberUids', arrayContains: uid)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CollabPlaylist.fromFirestore(d)).toList());
  }

  Stream<CollabPlaylist?> playlistStream(String playlistId) {
    return _col.doc(playlistId).snapshots().map(
        (d) => d.exists ? CollabPlaylist.fromFirestore(d) : null);
  }
}
