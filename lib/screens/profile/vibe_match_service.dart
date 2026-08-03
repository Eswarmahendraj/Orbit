import 'package:cloud_firestore/cloud_firestore.dart';

class VibeMatchResult {
  final int score;
  final String emoji;
  final String label;
  final List<String> commonArtists;
  final List<String> commonGenres;

  const VibeMatchResult({
    required this.score,
    required this.emoji,
    required this.label,
    required this.commonArtists,
    required this.commonGenres,
  });
}

class VibeMatchService {
  final _db = FirebaseFirestore.instance;

  Future<VibeMatchResult?> getCachedMatch(String myUid, String theirUid) async {
    final key = _cacheKey(myUid, theirUid);
    final doc = await _db.collection('vibe_matches').doc(key).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return VibeMatchResult(
      score: (d['score'] as num).toInt(),
      emoji: d['emoji'] as String? ?? '🎵',
      label: d['label'] as String? ?? '',
      commonArtists: List<String>.from(d['commonArtists'] ?? []),
      commonGenres: List<String>.from(d['commonGenres'] ?? []),
    );
  }

  Future<VibeMatchResult> computeMatch(String myUid, String theirUid) async {
    final myDoc = await _db.collection('users').doc(myUid).get();
    final theirDoc = await _db.collection('users').doc(theirUid).get();

    final myData = myDoc.data() ?? {};
    final theirData = theirDoc.data() ?? {};

    final myArtists = Set<String>.from(List<String>.from(myData['topArtists'] ?? []));
    final theirArtists = Set<String>.from(List<String>.from(theirData['topArtists'] ?? []));
    final myGenres = Set<String>.from(List<String>.from(myData['topGenres'] ?? []));
    final theirGenres = Set<String>.from(List<String>.from(theirData['topGenres'] ?? []));

    final commonArtists = myArtists.intersection(theirArtists).toList();
    final commonGenres = myGenres.intersection(theirGenres).toList();

    final artistScore = myArtists.isEmpty ? 0 : (commonArtists.length / myArtists.length * 50).round();
    final genreScore = myGenres.isEmpty ? 0 : (commonGenres.length / myGenres.length * 50).round();
    final score = (artistScore + genreScore).clamp(0, 100);

    final sl = _scoreLabel(score);

    return VibeMatchResult(
      score: score,
      emoji: sl[0],
      label: sl[1],
      commonArtists: commonArtists.take(5).toList(),
      commonGenres: commonGenres.take(5).toList(),
    );
  }

  Future<void> cacheMatch(String myUid, String theirUid, VibeMatchResult result) async {
    final key = _cacheKey(myUid, theirUid);
    await _db.collection('vibe_matches').doc(key).set({
      'score': result.score,
      'emoji': result.emoji,
      'label': result.label,
      'commonArtists': result.commonArtists,
      'commonGenres': result.commonGenres,
      'cachedAt': FieldValue.serverTimestamp(),
    });
  }

  String _cacheKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  List<String> _scoreLabel(int score) {
    if (score >= 80) return ['🔥', 'Sonic Twins'];
    if (score >= 60) return ['💜', 'Vibe Aligned'];
    if (score >= 40) return ['🎵', 'Groove Compatible'];
    if (score >= 20) return ['🌊', 'Different Waves'];
    return ['🌍', 'Musical Strangers'];
  }
}
