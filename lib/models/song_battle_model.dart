import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SongBattle — Firestore model
// /song_battles/{battleId}
// ─────────────────────────────────────────────────────────────────────────────

enum BattleStatus { pending, active, completed }

class BattleSong {
  final String title;
  final String artist;
  final String? artUrl;
  final String? previewUrl;

  const BattleSong({
    required this.title,
    required this.artist,
    this.artUrl,
    this.previewUrl,
  });

  factory BattleSong.fromMap(Map<String, dynamic> m) => BattleSong(
        title: m['title'] as String? ?? '',
        artist: m['artist'] as String? ?? '',
        artUrl: m['artUrl'] as String?,
        previewUrl: m['previewUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'artist': artist,
        'artUrl': artUrl,
        'previewUrl': previewUrl,
      };
}

class EditRequest {
  final String requestedBy; // uid
  final BattleSong newSong;

  const EditRequest({required this.requestedBy, required this.newSong});

  factory EditRequest.fromMap(Map<String, dynamic> m) => EditRequest(
        requestedBy: m['requestedBy'] as String,
        newSong: BattleSong.fromMap(
            Map<String, dynamic>.from(m['newSong'] as Map)),
      );

  Map<String, dynamic> toMap() => {
        'requestedBy': requestedBy,
        'newSong': newSong.toMap(),
      };
}

class SongBattle {
  final String id;
  final String challengerId;
  final String challengerName;
  final String? challengerPhoto;
  final BattleSong challengerSong;
  final String opponentId;
  final String opponentName;
  final String? opponentPhoto;
  final BattleSong? opponentSong;
  final BattleStatus status;
  final int votesChallenger;
  final int votesOpponent;
  final EditRequest? editRequest;
  final DateTime createdAt;
  final DateTime expiresAt;

  const SongBattle({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    this.challengerPhoto,
    required this.challengerSong,
    required this.opponentId,
    required this.opponentName,
    this.opponentPhoto,
    this.opponentSong,
    required this.status,
    this.votesChallenger = 0,
    this.votesOpponent = 0,
    this.editRequest,
    required this.createdAt,
    required this.expiresAt,
  });

  factory SongBattle.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SongBattle(
      id: doc.id,
      challengerId: d['challengerId'] as String,
      challengerName: d['challengerName'] as String? ?? '',
      challengerPhoto: d['challengerPhoto'] as String?,
      challengerSong: BattleSong.fromMap(
          Map<String, dynamic>.from(d['challengerSong'] as Map)),
      opponentId: d['opponentId'] as String,
      opponentName: d['opponentName'] as String? ?? '',
      opponentPhoto: d['opponentPhoto'] as String?,
      opponentSong: d['opponentSong'] != null
          ? BattleSong.fromMap(
              Map<String, dynamic>.from(d['opponentSong'] as Map))
          : null,
      status: _parseStatus(d['status'] as String? ?? 'pending'),
      votesChallenger: (d['votesChallenger'] as num?)?.toInt() ?? 0,
      votesOpponent: (d['votesOpponent'] as num?)?.toInt() ?? 0,
      editRequest: d['editRequest'] != null
          ? EditRequest.fromMap(
              Map<String, dynamic>.from(d['editRequest'] as Map))
          : null,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }

  static BattleStatus _parseStatus(String s) {
    switch (s) {
      case 'active':
        return BattleStatus.active;
      case 'completed':
        return BattleStatus.completed;
      default:
        return BattleStatus.pending;
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// true if the current user has a pending edit request they need to review
  bool hasEditRequestFor(String uid) =>
      editRequest != null && editRequest!.requestedBy != uid;

  int get totalVotes => votesChallenger + votesOpponent;

  double get challengerPct =>
      totalVotes == 0 ? 0.5 : votesChallenger / totalVotes;
}
