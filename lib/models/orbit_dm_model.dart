import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORBIT DM Models
// Supports: text, clip, voiceNote, guessSong, poll, songCard, lyric,
//           gif, sticker, location, viewOnce, doodle + thread replies, pinning,
//           read receipts w/ song context, disappearing msgs, scheduled send
// ─────────────────────────────────────────────────────────────────────────────

enum DmMsgType {
  text,
  clip,         // 15-second song clip
  voiceNote,    // voice recording
  guessSong,    // 3-second mystery clip game
  poll,         // music poll with song options
  songCard,     // full song share card
  lyric,        // lyric quote card
  gif,          // GIPHY gif
  sticker,      // GIPHY sticker
  location,     // live location share
  viewOnce,     // disappears after first view
  doodle,       // freehand drawing — music-themed, in conversation accent colour
  whiteboard,   // full whiteboard — write, draw, paint in any colour
}

// ── Read receipt ───────────────────────────────────────────────────
class DmReadReceipt {
  final String uid;
  final DateTime at;
  final String? songPlaying; // song they were listening to when they read it

  const DmReadReceipt({
    required this.uid,
    required this.at,
    this.songPlaying,
  });

  factory DmReadReceipt.fromMap(Map<String, dynamic> m) => DmReadReceipt(
        uid: m['uid'] as String,
        at: (m['at'] as Timestamp).toDate(),
        songPlaying: m['songPlaying'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'at': Timestamp.fromDate(at),
        if (songPlaying != null) 'songPlaying': songPlaying,
      };
}

// ── Poll option ────────────────────────────────────────────────────
class DmPollOption {
  final String id;
  final String label;       // song title or custom text
  final String? artist;
  final String? artUrl;
  final List<String> voterUids;

  const DmPollOption({
    required this.id,
    required this.label,
    this.artist,
    this.artUrl,
    this.voterUids = const [],
  });

  factory DmPollOption.fromMap(Map<String, dynamic> m) => DmPollOption(
        id: m['id'] as String,
        label: m['label'] as String,
        artist: m['artist'] as String?,
        artUrl: m['artUrl'] as String?,
        voterUids: List<String>.from(m['voterUids'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        if (artist != null) 'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        'voterUids': voterUids,
      };

  DmPollOption copyWith({List<String>? voterUids}) => DmPollOption(
        id: id,
        label: label,
        artist: artist,
        artUrl: artUrl,
        voterUids: voterUids ?? this.voterUids,
      );
}

// ── Guess-the-song state ───────────────────────────────────────────
class DmGuessSongData {
  final String songTitle;   // hidden until guessed/expired
  final String artist;
  final String? artUrl;
  final String? previewUrl;
  final double clipStart;   // 3-second window
  final double clipEnd;
  final Map<String, String> guesses;  // uid → guess text
  final Map<String, bool> correct;    // uid → isCorrect
  final bool revealed;

  const DmGuessSongData({
    required this.songTitle,
    required this.artist,
    this.artUrl,
    this.previewUrl,
    required this.clipStart,
    required this.clipEnd,
    this.guesses = const {},
    this.correct = const {},
    this.revealed = false,
  });

  factory DmGuessSongData.fromMap(Map<String, dynamic> m) => DmGuessSongData(
        songTitle: m['songTitle'] as String,
        artist: m['artist'] as String,
        artUrl: m['artUrl'] as String?,
        previewUrl: m['previewUrl'] as String?,
        clipStart: (m['clipStart'] as num).toDouble(),
        clipEnd: (m['clipEnd'] as num).toDouble(),
        guesses: Map<String, String>.from(m['guesses'] ?? {}),
        correct: Map<String, bool>.from(m['correct'] ?? {}),
        revealed: m['revealed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'songTitle': songTitle,
        'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        'clipStart': clipStart,
        'clipEnd': clipEnd,
        'guesses': guesses,
        'correct': correct,
        'revealed': revealed,
      };
}

// ── Main message model ─────────────────────────────────────────────
class DmMessage {
  final String id;
  final DmMsgType type;
  final String senderId;
  final String? senderName;
  final DateTime createdAt;

  // Delivery & scheduling
  final DateTime? scheduledAt;    // if set, hold until this time
  final DateTime? disappearsAt;   // if set, auto-delete after this time

  // Threading
  final String? replyToId;        // id of message being replied to
  final String? replyToPreview;   // short text preview of the quoted message

  // Pinning
  final bool isPinned;

  // Read receipts — uid → DmReadReceipt
  final Map<String, DmReadReceipt> readBy;

  // ── Type-specific data ──

  // text / viewOnce
  final String? text;

  // clip / guessSong
  final String? songTitle;
  final String? artist;
  final String? artUrl;
  final String? previewUrl;
  final double? clipStart;
  final double? clipEnd;

  // voiceNote
  final String? voiceUrl;        // Firebase Storage download URL
  final double? voiceDuration;   // seconds
  final List<double>? waveform;  // normalised 0–1 amplitudes

  // guessSong
  final DmGuessSongData? guessSongData;

  // poll
  final String? pollQuestion;
  final List<DmPollOption>? pollOptions;
  final bool pollClosed;

  // songCard / lyric
  final String? lyricText;
  final String? lyricSong;
  final String? lyricArtist;

  // gif / sticker
  final String? giphyId;         // GIPHY gif/sticker ID
  final bool isSticker;

  // location
  final double? lat;
  final double? lng;
  final DateTime? locationExpiresAt;

  // viewOnce
  final List<String> viewedByUids;
  final String? viewOnceImageUrl;

  // doodle — strokes stored as list of point lists: [[{x,y}, ...], ...]
  // Each stroke is a connected path; colour is stored in the message.
  final List<List<Map<String, double>>>? doodleStrokes;
  final String? doodleColor;   // hex '#RRGGBB' — conversation accent at draw time

  // whiteboard — rich canvas with per-element colour, text stamps, eraser
  // Each element: {type:'stroke'|'text', color:'#hex', width:double,
  //               points:[{x,y},...], text:String?, fontSize:double?, tx:double?, ty:double?}
  final List<Map<String, dynamic>>? whiteboardData;

  const DmMessage({
    required this.id,
    required this.type,
    required this.senderId,
    this.senderName,
    required this.createdAt,
    this.scheduledAt,
    this.disappearsAt,
    this.replyToId,
    this.replyToPreview,
    this.isPinned = false,
    this.readBy = const {},
    this.text,
    this.songTitle,
    this.artist,
    this.artUrl,
    this.previewUrl,
    this.clipStart,
    this.clipEnd,
    this.voiceUrl,
    this.voiceDuration,
    this.waveform,
    this.guessSongData,
    this.pollQuestion,
    this.pollOptions,
    this.pollClosed = false,
    this.lyricText,
    this.lyricSong,
    this.lyricArtist,
    this.giphyId,
    this.isSticker = false,
    this.lat,
    this.lng,
    this.locationExpiresAt,
    this.viewedByUids = const [],
    this.viewOnceImageUrl,
    this.doodleStrokes,
    this.doodleColor,
    this.whiteboardData,
  });

  bool get isDelivered =>
      scheduledAt == null || DateTime.now().isAfter(scheduledAt!);

  bool get isExpired =>
      disappearsAt != null && DateTime.now().isAfter(disappearsAt!);

  factory DmMessage.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    final typeStr = m['type'] as String? ?? 'text';
    final type = DmMsgType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DmMsgType.text,
    );

    // Parse readBy
    final rawReadBy = m['readBy'] as Map<String, dynamic>? ?? {};
    final readBy = <String, DmReadReceipt>{};
    rawReadBy.forEach((uid, val) {
      if (val is Map) {
        readBy[uid] = DmReadReceipt.fromMap(
            Map<String, dynamic>.from(val as Map));
      }
    });

    // Parse poll options
    List<DmPollOption>? pollOptions;
    final rawPoll = m['pollOptions'] as List<dynamic>?;
    if (rawPoll != null) {
      pollOptions = rawPoll
          .map((o) => DmPollOption.fromMap(Map<String, dynamic>.from(o as Map)))
          .toList();
    }

    // Parse waveform
    List<double>? waveform;
    final rawWave = m['waveform'] as List<dynamic>?;
    if (rawWave != null) {
      waveform = rawWave.map((v) => (v as num).toDouble()).toList();
    }

    // Parse guess song data
    DmGuessSongData? guessSongData;
    final rawGuess = m['guessSongData'] as Map<String, dynamic>?;
    if (rawGuess != null) guessSongData = DmGuessSongData.fromMap(rawGuess);

    return DmMessage(
      id: doc.id,
      type: type,
      senderId: m['senderId'] as String,
      senderName: m['senderName'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: m['scheduledAt'] != null
          ? (m['scheduledAt'] as Timestamp).toDate()
          : null,
      disappearsAt: m['disappearsAt'] != null
          ? (m['disappearsAt'] as Timestamp).toDate()
          : null,
      replyToId: m['replyToId'] as String?,
      replyToPreview: m['replyToPreview'] as String?,
      isPinned: m['isPinned'] as bool? ?? false,
      readBy: readBy,
      text: m['text'] as String?,
      songTitle: m['songTitle'] as String?,
      artist: m['artist'] as String?,
      artUrl: m['artUrl'] as String?,
      previewUrl: m['previewUrl'] as String?,
      clipStart: (m['clipStart'] as num?)?.toDouble(),
      clipEnd: (m['clipEnd'] as num?)?.toDouble(),
      voiceUrl: m['voiceUrl'] as String?,
      voiceDuration: (m['voiceDuration'] as num?)?.toDouble(),
      waveform: waveform,
      guessSongData: guessSongData,
      pollQuestion: m['pollQuestion'] as String?,
      pollOptions: pollOptions,
      pollClosed: m['pollClosed'] as bool? ?? false,
      lyricText: m['lyricText'] as String?,
      lyricSong: m['lyricSong'] as String?,
      lyricArtist: m['lyricArtist'] as String?,
      giphyId: m['giphyId'] as String?,
      isSticker: m['isSticker'] as bool? ?? false,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      locationExpiresAt: m['locationExpiresAt'] != null
          ? (m['locationExpiresAt'] as Timestamp).toDate()
          : null,
      viewedByUids: List<String>.from(m['viewedByUids'] ?? []),
      viewOnceImageUrl: m['viewOnceImageUrl'] as String?,
      doodleStrokes: (m['doodleStrokes'] as List<dynamic>?)?.map((stroke) =>
          (stroke as List<dynamic>).map((pt) {
            final p = Map<String, dynamic>.from(pt as Map);
            return {'x': (p['x'] as num).toDouble(), 'y': (p['y'] as num).toDouble()};
          }).toList()).toList(),
      doodleColor: m['doodleColor'] as String?,
      whiteboardData: (m['whiteboardData'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'senderId': senderId,
        if (senderName != null) 'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
        if (scheduledAt != null)
          'scheduledAt': Timestamp.fromDate(scheduledAt!),
        if (disappearsAt != null)
          'disappearsAt': Timestamp.fromDate(disappearsAt!),
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToPreview != null) 'replyToPreview': replyToPreview,
        'isPinned': isPinned,
        'readBy': readBy.map((k, v) => MapEntry(k, v.toMap())),
        if (text != null) 'text': text,
        if (songTitle != null) 'songTitle': songTitle,
        if (artist != null) 'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        if (clipStart != null) 'clipStart': clipStart,
        if (clipEnd != null) 'clipEnd': clipEnd,
        if (voiceUrl != null) 'voiceUrl': voiceUrl,
        if (voiceDuration != null) 'voiceDuration': voiceDuration,
        if (waveform != null) 'waveform': waveform,
        if (guessSongData != null) 'guessSongData': guessSongData!.toMap(),
        if (pollQuestion != null) 'pollQuestion': pollQuestion,
        if (pollOptions != null)
          'pollOptions': pollOptions!.map((o) => o.toMap()).toList(),
        'pollClosed': pollClosed,
        if (lyricText != null) 'lyricText': lyricText,
        if (lyricSong != null) 'lyricSong': lyricSong,
        if (lyricArtist != null) 'lyricArtist': lyricArtist,
        if (giphyId != null) 'giphyId': giphyId,
        'isSticker': isSticker,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (locationExpiresAt != null)
          'locationExpiresAt': Timestamp.fromDate(locationExpiresAt!),
        'viewedByUids': viewedByUids,
        if (viewOnceImageUrl != null) 'viewOnceImageUrl': viewOnceImageUrl,
        if (doodleStrokes != null) 'doodleStrokes': doodleStrokes,
        if (doodleColor != null) 'doodleColor': doodleColor,
        if (whiteboardData != null) 'whiteboardData': whiteboardData,
      };
}

// ── Mood board item ────────────────────────────────────────────────
enum MoodBoardItemType { song, lyric, vibe }

class MoodBoardItem {
  final String id;
  final MoodBoardItemType type;
  final String content;       // song title, lyric, or vibe label
  final String? artist;
  final String? artUrl;
  final String addedByUid;
  final DateTime addedAt;

  const MoodBoardItem({
    required this.id,
    required this.type,
    required this.content,
    this.artist,
    this.artUrl,
    required this.addedByUid,
    required this.addedAt,
  });

  factory MoodBoardItem.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MoodBoardItem(
      id: doc.id,
      type: MoodBoardItemType.values.firstWhere(
        (t) => t.name == (m['type'] as String? ?? 'vibe'),
        orElse: () => MoodBoardItemType.vibe,
      ),
      content: m['content'] as String,
      artist: m['artist'] as String?,
      artUrl: m['artUrl'] as String?,
      addedByUid: m['addedByUid'] as String,
      addedAt: (m['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'content': content,
        if (artist != null) 'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        'addedByUid': addedByUid,
        'addedAt': FieldValue.serverTimestamp(),
      };
}

// ── Conversation metadata ──────────────────────────────────────────
class DmConversation {
  final String id;
  final List<String> memberUids;
  final String? themeColor;       // hex string e.g. '#FF8C42'
  final int? disappearAfterSeconds; // null = off
  final String? collabPlaylistId;
  final List<String> pinnedMessageIds;
  final Map<String, String?> concertStatus; // uid → 'Artist · Event' or null

  const DmConversation({
    required this.id,
    required this.memberUids,
    this.themeColor,
    this.disappearAfterSeconds,
    this.collabPlaylistId,
    this.pinnedMessageIds = const [],
    this.concertStatus = const {},
  });

  factory DmConversation.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return DmConversation(
      id: doc.id,
      memberUids: List<String>.from(m['memberUids'] ?? []),
      themeColor: m['themeColor'] as String?,
      disappearAfterSeconds: m['disappearAfterSeconds'] as int?,
      collabPlaylistId: m['collabPlaylistId'] as String?,
      pinnedMessageIds:
          List<String>.from(m['pinnedMessageIds'] ?? []),
      concertStatus:
          Map<String, String?>.from(m['concertStatus'] ?? {}),
    );
  }
}

// ── Conversation theme presets ─────────────────────────────────────
class DmTheme {
  final String label;
  final String hex;
  const DmTheme(this.label, this.hex);

  static const List<DmTheme> presets = [
    DmTheme('Hype',        '#FF8C42'),
    DmTheme('Chill',       '#7F77DD'),
    DmTheme('Fresh',       '#1D9E75'),
    DmTheme('Tender',      '#D85A30'),
    DmTheme('Mysterious',  '#534AB7'),
    DmTheme('Golden',      '#BA7517'),
  ];
}
