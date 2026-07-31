import 'package:cloud_firestore/cloud_firestore.dart';

/// Computes a music taste compatibility score (0–100) between two users
/// based on overlapping top artists and genres stored in Firestore.
class VibeMatchService {
  static final VibeMatchService _instance = VibeMatchService._internal();
  factory VibeMatchService() => _instance;
  VibeMatchService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Fetch user music profile ───────────────────────────────────────────────
  Future<Map<String, dynamic>> _getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return {};
    return doc.data() ?? {};
  }

  // ── Compute match ──────────────────────────────────────────────────────────
  Future<VibeMatchResult> computeMatch(String myUid, String theirUid) async {
    final results = await Future.wait([
      _getUserProfile(myUid),
      _getUserProfile(theirUid),
    ]);

    final me = results[0];
    final them = results[1];

    final myArtists = Set<String>.from(
        (me['topArtists'] as List? ?? []).map((a) => a.toString().toLowerCase()));
    final theirArtists = Set<String>.from(
        (them['topArtists'] as List? ?? []).map((a) => a.toString().toLowerCase()));

    final myGenres = Set<String>.from(
        (me['topGenres'] as List? ?? []).map((g) => g.toString().toLowerCase()));
    final theirGenres = Set<String>.from(
        (them['topGenres'] as List? ?? []).map((g) => g.toString().toLowerCase()));

    final myMoods = Set<String>.from(
        (me['moodHistory'] as List? ?? []).map((m) => m.toString().toLowerCase()));
    final theirMoods = Set<String>.from(
        (them['moodHistory'] as List? ?? []).map((m) => m.toString().toLowerCase()));

    // Jaccard similarity for each dimension
    double _jaccard(Set<String> a, Set<String> b) {
      if (a.isEmpty && b.isEmpty) return 0.5;
      if (a.isEmpty || b.isEmpty) return 0.0;
      final intersection = a.intersection(b).length;
      final union = a.union(b).length;
      return union == 0 ? 0 : intersection / union;
    }

    final artistScore = _jaccard(myArtists, theirArtists);
    final genreScore = _jaccard(myGenres, theirGenres);
    final moodScore = _jaccard(myMoods, theirMoods);

    // Weighted total (artists = 50%, genres = 35%, moods = 15%)
    final raw = (artistScore * 0.50) + (genreScore * 0.35) + (moodScore * 0.15);
    final percent = (raw * 100).round().clamp(0, 100);

    final commonArtists = myArtists.intersection(theirArtists).take(3).toList();
    final commonGenres = myGenres.intersection(theirGenres).take(3).toList();

    return VibeMatchResult(
      score: percent,
      label: _label(percent),
      emoji: _emoji(percent),
      commonArtists: commonArtists,
      commonGenres: commonGenres,
    );
  }

  String _label(int score) {
    if (score >= 85) return 'Twin Flames';
    if (score >= 70) return 'High Vibe';
    if (score >= 55) return 'In Sync';
    if (score >= 40) return 'Some Overlap';
    if (score >= 25) return 'Different Worlds';
    return 'Opposites';
  }

  String _emoji(int score) {
    if (score >= 85) return '🔥';
    if (score >= 70) return '💜';
    if (score >= 55) return '🎵';
    if (score >= 40) return '✨';
    if (score >= 25) return '🌙';
    return '🌍';
  }

  // ── Cache in Firestore for quick reads ────────────────────────────────────
  Future<void> cacheMatch(
      String myUid, String theirUid, VibeMatchResult result) async {
    final key = [myUid, theirUid]..sort();
    await _db.collection('vibe_matches').doc('${key[0]}_${key[1]}').set({
      'uids': key,
      'score': result.score,
      'label': result.label,
      'commonArtists': result.commonArtists,
      'commonGenres': result.commonGenres,
      'computedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<VibeMatchResult?> getCachedMatch(
      String myUid, String theirUid) async {
    final key = [myUid, theirUid]..sort();
    final doc = await _db
        .collection('vibe_matches')
        .doc('${key[0]}_${key[1]}')
        .get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    // Invalidate if older than 24h
    final computed = (d['computedAt'] as Timestamp?)?.toDate();
    if (computed != null &&
        DateTime.now().difference(computed).inHours > 24) return null;
    return VibeMatchResult(
      score: d['score'] as int,
      label: d['label'] as String,
      emoji: _emoji(d['score'] as int),
      commonArtists: List<String>.from(d['commonArtists'] ?? []),
      commonGenres: List<String>.from(d['commonGenres'] ?? []),
    );
  }
}

class VibeMatchResult {
  final int score; // 0–100
  final String label;
  final String emoji;
  final List<String> commonArtists;
  final List<String> commonGenres;

  VibeMatchResult({
    required this.score,
    required this.label,
    required this.emoji,
    required this.commonArtists,
    required this.commonGenres,
  });
}
