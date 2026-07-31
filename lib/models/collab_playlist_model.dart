import 'package:cloud_firestore/cloud_firestore.dart';

/// A shared playlist that multiple friends can add tracks to and vote on.
class CollabPlaylist {
  final String id;
  final String name;
  final String ownerUid;
  final String ownerName;
  final List<String> memberUids;
  final List<CollabTrack> tracks;
  final bool isActive;
  final DateTime createdAt;

  CollabPlaylist({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.ownerName,
    required this.memberUids,
    required this.tracks,
    required this.isActive,
    required this.createdAt,
  });

  int get trackCount => tracks.length;

  factory CollabPlaylist.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CollabPlaylist(
      id: doc.id,
      name: d['name'] ?? 'Collab Playlist',
      ownerUid: d['ownerUid'] ?? '',
      ownerName: d['ownerName'] ?? '',
      memberUids: List<String>.from(d['memberUids'] ?? []),
      tracks: ((d['tracks'] as List?) ?? [])
          .map((t) => CollabTrack.fromMap(t as Map<String, dynamic>))
          .toList(),
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'memberUids': memberUids,
        'tracks': tracks.map((t) => t.toMap()).toList(),
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class CollabTrack {
  final String id;
  final String title;
  final String artist;
  final String? artUrl;
  final String addedByUid;
  final String addedByName;
  final int votes;
  final List<String> votedByUids;
  final DateTime addedAt;

  CollabTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.artUrl,
    required this.addedByUid,
    required this.addedByName,
    required this.votes,
    required this.votedByUids,
    required this.addedAt,
  });

  bool hasVoted(String uid) => votedByUids.contains(uid);

  factory CollabTrack.fromMap(Map<String, dynamic> d) => CollabTrack(
        id: d['id'] ?? '',
        title: d['title'] ?? '',
        artist: d['artist'] ?? '',
        artUrl: d['artUrl'],
        addedByUid: d['addedByUid'] ?? '',
        addedByName: d['addedByName'] ?? '',
        votes: d['votes'] ?? 0,
        votedByUids: List<String>.from(d['votedByUids'] ?? []),
        addedAt: (d['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        'addedByUid': addedByUid,
        'addedByName': addedByName,
        'votes': votes,
        'votedByUids': votedByUids,
        'addedAt': FieldValue.serverTimestamp(),
      };

  CollabTrack copyWith({int? votes, List<String>? votedByUids}) => CollabTrack(
        id: id,
        title: title,
        artist: artist,
        artUrl: artUrl,
        addedByUid: addedByUid,
        addedByName: addedByName,
        votes: votes ?? this.votes,
        votedByUids: votedByUids ?? this.votedByUids,
        addedAt: addedAt,
      );
}
