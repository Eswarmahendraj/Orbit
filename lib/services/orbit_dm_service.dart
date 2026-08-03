import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orbit_dm_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ORBIT DM Service
// Firestore structure:
//   dms/{convId}/                     — DmConversation doc
//   dms/{convId}/messages/{msgId}     — DmMessage docs
//   dms/{convId}/moodboard/{itemId}   — MoodBoardItem docs
//
// convId = sorted(uid1, uid2).join('_')
// ─────────────────────────────────────────────────────────────────────────────

class OrbitDmService {
  static final OrbitDmService _i = OrbitDmService._();
  factory OrbitDmService() => _i;
  OrbitDmService._();

  final _db = FirebaseFirestore.instance;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // ── Conversation ID ────────────────────────────────────────────────
  static String convId(String uidA, String uidB) {
    final parts = [uidA, uidB]..sort();
    return parts.join('_');
  }

  DocumentReference _convRef(String id) => _db.collection('dms').doc(id);
  CollectionReference _msgs(String convId) =>
      _convRef(convId).collection('messages');
  CollectionReference _board(String convId) =>
      _convRef(convId).collection('moodboard');

  // ── Ensure conversation doc exists ────────────────────────────────
  Future<void> ensureConversation(
      String myUid, String otherUid, String convId) async {
    final ref = _convRef(convId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'memberUids': [myUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'pinnedMessageIds': [],
        'concertStatus': {},
      });
    }
  }

  // ── Streams ────────────────────────────────────────────────────────

  Stream<DmConversation?> conversationStream(String cid) => _convRef(cid)
      .snapshots()
      .map((s) => s.exists ? DmConversation.fromFirestore(s) : null)
      .handleError((_) => null);

  Stream<List<DmMessage>> messagesStream(String cid) => _msgs(cid)
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => DmMessage.fromFirestore(d))
          .where((m) =>
              m.isDelivered &&   // don't show scheduled-future messages
              !m.isExpired)      // don't show expired disappearing messages
          .toList())
      .handleError((_) => <DmMessage>[]);

  Stream<List<MoodBoardItem>> moodBoardStream(String cid) => _board(cid)
      .orderBy('addedAt')
      .snapshots()
      .map((s) => s.docs.map(MoodBoardItem.fromFirestore).toList())
      .handleError((_) => <MoodBoardItem>[]);

  // ── Send messages ──────────────────────────────────────────────────

  Future<String> _send(String cid, Map<String, dynamic> data) async {
    final doc = await _msgs(cid).add(data);
    // Update conversation lastActivity
    _convRef(cid).update({'lastActivity': FieldValue.serverTimestamp()});
    return doc.id;
  }

  Future<String> sendText(
    String cid, {
    required String text,
    String? replyToId,
    String? replyToPreview,
    DateTime? disappearsAt,
    DateTime? scheduledAt,
  }) {
    final uid = _myUid!;
    return _send(cid, {
      'type': DmMsgType.text.name,
      'senderId': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      if (disappearsAt != null)
        'disappearsAt': Timestamp.fromDate(disappearsAt),
      if (scheduledAt != null)
        'scheduledAt': Timestamp.fromDate(scheduledAt),
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendClip(
    String cid, {
    required String songTitle,
    required String artist,
    String? artUrl,
    String? previewUrl,
    required double clipStart,
    required double clipEnd,
    String? replyToId,
    String? replyToPreview,
    DateTime? disappearsAt,
  }) {
    return _send(cid, {
      'type': DmMsgType.clip.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'songTitle': songTitle,
      'artist': artist,
      if (artUrl != null) 'artUrl': artUrl,
      if (previewUrl != null) 'previewUrl': previewUrl,
      'clipStart': clipStart,
      'clipEnd': clipEnd,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      if (disappearsAt != null)
        'disappearsAt': Timestamp.fromDate(disappearsAt),
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendVoiceNote(
    String cid, {
    required String voiceUrl,
    required double duration,
    required List<double> waveform,
    String? replyToId,
    String? replyToPreview,
    DateTime? disappearsAt,
  }) {
    return _send(cid, {
      'type': DmMsgType.voiceNote.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'voiceUrl': voiceUrl,
      'voiceDuration': duration,
      'waveform': waveform,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      if (disappearsAt != null)
        'disappearsAt': Timestamp.fromDate(disappearsAt),
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendGuessSong(
    String cid, {
    required String songTitle,
    required String artist,
    String? artUrl,
    String? previewUrl,
    required double clipStart,
    required double clipEnd,
  }) {
    return _send(cid, {
      'type': DmMsgType.guessSong.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'guessSongData': {
        'songTitle': songTitle,
        'artist': artist,
        if (artUrl != null) 'artUrl': artUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        'clipStart': clipStart,
        'clipEnd': clipEnd,
        'guesses': {},
        'correct': {},
        'revealed': false,
      },
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendPoll(
    String cid, {
    required String question,
    required List<DmPollOption> options,
  }) {
    return _send(cid, {
      'type': DmMsgType.poll.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'pollQuestion': question,
      'pollOptions': options.map((o) => o.toMap()).toList(),
      'pollClosed': false,
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendLyric(
    String cid, {
    required String lyricText,
    required String lyricSong,
    required String lyricArtist,
    String? artUrl,
    String? replyToId,
    String? replyToPreview,
  }) {
    return _send(cid, {
      'type': DmMsgType.lyric.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'lyricText': lyricText,
      'lyricSong': lyricSong,
      'lyricArtist': lyricArtist,
      if (artUrl != null) 'artUrl': artUrl,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendGif(
    String cid, {
    required String giphyId,
    bool isSticker = false,
    String? replyToId,
    String? replyToPreview,
  }) {
    return _send(cid, {
      'type': isSticker ? DmMsgType.sticker.name : DmMsgType.gif.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'giphyId': giphyId,
      'isSticker': isSticker,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendLocation(
    String cid, {
    required double lat,
    required double lng,
    required DateTime expiresAt,
  }) {
    return _send(cid, {
      'type': DmMsgType.location.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'lat': lat,
      'lng': lng,
      'locationExpiresAt': Timestamp.fromDate(expiresAt),
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  Future<String> sendViewOnce(
    String cid, {
    String? text,
    String? imageUrl,
  }) {
    return _send(cid, {
      'type': DmMsgType.viewOnce.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      if (text != null) 'text': text,
      if (imageUrl != null) 'viewOnceImageUrl': imageUrl,
      'readBy': {},
      'isPinned': false,
      'viewedByUids': [],
    });
  }

  /// Send a freehand doodle message.
  /// [strokes] is a list of point-lists from the canvas;
  /// [color] is the hex accent colour of the conversation at draw time.
  Future<String> sendDoodle(
    String cid, {
    required List<List<Map<String, double>>> strokes,
    required String color,
    String? replyToId,
    String? replyToPreview,
  }) {
    return _send(cid, {
      'type': DmMsgType.doodle.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'doodleStrokes': strokes,
      'doodleColor': color,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      'readBy': {},
      'isPinned': false,
    });
  }

  /// Send a whiteboard message (write/draw/paint, any colour, with text stamps).
  /// [data] is a list of elements — each element is a Map with keys:
  ///   type: 'stroke' | 'text' | 'erase'
  ///   color: '#RRGGBB'
  ///   width: double
  ///   points: List<Map<String,double>> (normalised 0–1 coords, for strokes/eraser)
  ///   text: String (for text elements)
  ///   tx/ty: double (normalised position of text element)
  ///   fontSize: double
  Future<String> sendWhiteboard(
    String cid, {
    required List<Map<String, dynamic>> data,
    String? replyToId,
    String? replyToPreview,
  }) {
    return _send(cid, {
      'type': DmMsgType.whiteboard.name,
      'senderId': _myUid!,
      'createdAt': FieldValue.serverTimestamp(),
      'whiteboardData': data,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToPreview != null) 'replyToPreview': replyToPreview,
      'readBy': {},
      'isPinned': false,
    });
  }

  // ── Poll voting ────────────────────────────────────────────────────
  Future<void> votePoll({
    required String cid,
    required String msgId,
    required String optionId,
    required DmMessage currentMsg,
  }) async {
    final uid = _myUid!;
    final options = currentMsg.pollOptions ?? [];

    // Toggle: remove from all options first, then add to selected
    final updated = options.map((o) {
      final voters = List<String>.from(o.voterUids)..remove(uid);
      if (o.id == optionId && !o.voterUids.contains(uid)) {
        voters.add(uid);
      }
      return o.copyWith(voterUids: voters);
    }).toList();

    await _msgs(cid).doc(msgId).update({
      'pollOptions': updated.map((o) => o.toMap()).toList(),
    });
  }

  // ── Guess the song ─────────────────────────────────────────────────
  Future<void> submitGuess({
    required String cid,
    required String msgId,
    required DmGuessSongData data,
    required String guess,
  }) async {
    final uid = _myUid!;
    final isCorrect = guess.trim().toLowerCase() ==
        data.songTitle.trim().toLowerCase();
    final newGuesses = Map<String, String>.from(data.guesses)..[uid] = guess;
    final newCorrect = Map<String, bool>.from(data.correct)..[uid] = isCorrect;

    await _msgs(cid).doc(msgId).update({
      'guessSongData.guesses': newGuesses,
      'guessSongData.correct': newCorrect,
      if (isCorrect) 'guessSongData.revealed': true,
    });
  }

  Future<void> revealGuessSong(String cid, String msgId) async {
    await _msgs(cid)
        .doc(msgId)
        .update({'guessSongData.revealed': true});
  }

  // ── Pinning ────────────────────────────────────────────────────────
  Future<void> togglePin(String cid, String msgId, bool currentlyPinned) async {
    await _msgs(cid).doc(msgId).update({'isPinned': !currentlyPinned});
    if (!currentlyPinned) {
      await _convRef(cid).update({
        'pinnedMessageIds': FieldValue.arrayUnion([msgId]),
      });
    } else {
      await _convRef(cid).update({
        'pinnedMessageIds': FieldValue.arrayRemove([msgId]),
      });
    }
  }

  // ── Read receipts ──────────────────────────────────────────────────
  Future<void> markRead(
    String cid,
    String msgId, {
    String? nowPlayingSong,
  }) async {
    final uid = _myUid!;
    await _msgs(cid).doc(msgId).update({
      'readBy.$uid': {
        'uid': uid,
        'at': Timestamp.now(),
        if (nowPlayingSong != null) 'songPlaying': nowPlayingSong,
      }
    });
  }

  /// Mark all unread messages in a conversation as read at once.
  Future<void> markAllRead(
    String cid,
    List<DmMessage> messages, {
    String? nowPlayingSong,
  }) async {
    final uid = _myUid!;
    final batch = _db.batch();
    for (final msg in messages) {
      if (!msg.readBy.containsKey(uid) && msg.senderId != uid) {
        batch.update(_msgs(cid).doc(msg.id), {
          'readBy.$uid': {
            'uid': uid,
            'at': Timestamp.now(),
            if (nowPlayingSong != null) 'songPlaying': nowPlayingSong,
          }
        });
      }
    }
    await batch.commit();
  }

  // ── View once ─────────────────────────────────────────────────────
  Future<void> markViewOnceViewed(String cid, String msgId) async {
    await _msgs(cid).doc(msgId).update({
      'viewedByUids': FieldValue.arrayUnion([_myUid!]),
    });
  }

  // ── Conversation settings ──────────────────────────────────────────
  Future<void> setTheme(String cid, String? hexColor) async {
    await _convRef(cid).update({'themeColor': hexColor});
  }

  Future<void> setDisappearTimer(String cid, int? seconds) async {
    await _convRef(cid).update({'disappearAfterSeconds': seconds});
  }

  Future<void> setConcertStatus(String cid, String uid, String? status) async {
    await _convRef(cid).update({'concertStatus.$uid': status});
  }

  Future<void> linkCollabPlaylist(String cid, String playlistId) async {
    await _convRef(cid).update({'collabPlaylistId': playlistId});
  }

  // ── Mood board ─────────────────────────────────────────────────────
  Future<void> addMoodBoardItem(String cid, MoodBoardItem item) async {
    await _board(cid).add(item.toFirestore());
  }

  Future<void> removeMoodBoardItem(String cid, String itemId) async {
    await _board(cid).doc(itemId).delete();
  }

  // ── Message deletion ───────────────────────────────────────────────
  Future<void> deleteMessage(String cid, String msgId) async {
    await _msgs(cid).doc(msgId).delete();
  }

  /// Delete all expired disappearing messages (call periodically).
  Future<void> pruneExpiredMessages(String cid) async {
    final now = Timestamp.now();
    final snap = await _msgs(cid)
        .where('disappearsAt', isLessThanOrEqualTo: now)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Deliver any scheduled messages whose time has passed.
  Future<void> deliverScheduledMessages(String cid) async {
    // Scheduled messages are stored with a scheduledAt timestamp.
    // The messagesStream filter already hides them before delivery time;
    // we don't need to do anything here — the stream naturally reveals them
    // once scheduledAt passes. This method can be called to pre-warm.
  }

  // ── Fetch pinned messages ──────────────────────────────────────────
  Future<List<DmMessage>> fetchPinnedMessages(
      String cid, List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures =
        ids.map((id) => _msgs(cid).doc(id).get()).toList();
    final snaps = await Future.wait(futures);
    return snaps
        .where((s) => s.exists)
        .map((s) => DmMessage.fromFirestore(s))
        .toList();
  }

  // ── AI recap helper ────────────────────────────────────────────────
  /// Returns the last [limit] messages as a text summary for AI recap.
  Future<String> buildRecapContext(String cid,
      {int limit = 60, String myName = 'you', String theirName = 'them'}) async {
    final snap = await _msgs(cid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    final msgs = snap.docs
        .map((d) => DmMessage.fromFirestore(d))
        .toList()
        .reversed
        .toList();

    final myUid = _myUid ?? '';
    final buf = StringBuffer();
    for (final m in msgs) {
      final who = m.senderId == myUid ? myName : theirName;
      switch (m.type) {
        case DmMsgType.text:
          buf.writeln('$who: ${m.text}');
        case DmMsgType.clip:
          buf.writeln('$who: [sent clip — ${m.songTitle} by ${m.artist}]');
        case DmMsgType.voiceNote:
          buf.writeln('$who: [voice note, ${m.voiceDuration?.round()}s]');
        case DmMsgType.poll:
          buf.writeln('$who: [poll — ${m.pollQuestion}]');
        case DmMsgType.guessSong:
          buf.writeln('$who: [guess the song game]');
        case DmMsgType.lyric:
          buf.writeln('$who: [lyric — "${m.lyricText}"]');
        case DmMsgType.songCard:
          buf.writeln('$who: [shared song — ${m.songTitle}]');
        default:
          buf.writeln('$who: [${m.type.name}]');
      }
    }
    return buf.toString();
  }
}
