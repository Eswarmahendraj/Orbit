import 'package:cloud_firestore/cloud_firestore.dart';

class MusicMoment {
  final String id;
  final String uid;
  final String username;
  final String displayName;
  final String avatarEmoji;
  final String song;
  final String artist;
  final String? previewUrl;
  final String? artUrl;
  final String? clipUrl;   // Firebase Storage URL (video or photo)
  final bool isPhoto;      // true = still image, false = video clip
  final String mood;
  final String moodEmoji;
  final String caption;
  final int fires;
  final String songKey;    // used to group all moments for the same song
  final DateTime createdAt;

  const MusicMoment({
    required this.id,
    required this.uid,
    required this.username,
    required this.displayName,
    required this.avatarEmoji,
    required this.song,
    required this.artist,
    this.previewUrl,
    this.artUrl,
    this.clipUrl,
    this.isPhoto = false,
    required this.mood,
    required this.moodEmoji,
    required this.caption,
    required this.fires,
    required this.songKey,
    required this.createdAt,
  });

  /// Stable key used to group moments by song
  static String makeSongKey(String song, String artist) =>
      '${song.trim().toLowerCase()}_${artist.trim().toLowerCase()}';

  factory MusicMoment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MusicMoment(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      username: d['username'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      avatarEmoji: d['avatarEmoji'] as String? ?? '🎵',
      song: d['song'] as String? ?? '',
      artist: d['artist'] as String? ?? '',
      previewUrl: d['previewUrl'] as String?,
      artUrl: d['artUrl'] as String?,
      clipUrl: d['clipUrl'] as String?,
      isPhoto: d['isPhoto'] as bool? ?? false,
      mood: d['mood'] as String? ?? '',
      moodEmoji: d['moodEmoji'] as String? ?? '🎵',
      caption: d['caption'] as String? ?? '',
      fires: (d['fires'] as num?)?.toInt() ?? 0,
      songKey: d['songKey'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'song': song,
        'artist': artist,
        'previewUrl': previewUrl,
        'artUrl': artUrl,
        'clipUrl': clipUrl,
        'isPhoto': isPhoto,
        'mood': mood,
        'moodEmoji': moodEmoji,
        'caption': caption,
        'fires': fires,
        'songKey': songKey,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
