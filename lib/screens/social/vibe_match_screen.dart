import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vibe Match Swipe — Tinder-style cards showing other users' top song + vibe.
// Swipe right = orbit match. Swipe left = skip.
// Mutual right swipes = "orbit sync" connection.
// Collection: vibe_match_swipes/{uid}/swipes/{targetUid} = {direction, ts}
//             vibe_match_matches/{compositeId} = {uid1, uid2, matchedAt}
// ─────────────────────────────────────────────────────────────────────────────

class VibeMatchScreen extends StatefulWidget {
  const VibeMatchScreen({super.key});
  @override
  State<VibeMatchScreen> createState() => _VibeMatchScreenState();
}

class _VibeMatchScreenState extends State<VibeMatchScreen> {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<Map<String, dynamic>> _cards = [];
  int _currentIndex = 0;
  bool _loading = true;
  Set<String> _alreadySwiped = {};

  // Drag state
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final uid = _uid;
    if (uid == null) return;

    // Get already-swiped UIDs
    final swipeSnap = await _db
        .collection('vibe_match_swipes').doc(uid)
        .collection('swipes').get();
    _alreadySwiped = swipeSnap.docs.map((d) => d.id).toSet();

    // Get recent active users with vibe data
    final usersSnap = await _db
        .collection('users')
        .where('hasVibeData', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .limit(50)
        .get();

    final cards = <Map<String, dynamic>>[];
    for (final doc in usersSnap.docs) {
      if (doc.id == uid) continue;
      if (_alreadySwiped.contains(doc.id)) continue;
      final data = doc.data() as Map<String, dynamic>;
      cards.add({
        'uid': doc.id,
        'name': data['displayName'] ?? 'Orbiter',
        'photo': data['photoUrl'],
        'topSong': data['topSong'] ?? '',
        'topArtist': data['topArtist'] ?? '',
        'topArtUrl': data['topArtUrl'],
        'mood': data['currentMood'] ?? '✨',
        'era': data['currentEra'] ?? '',
        'bio': data['bio'] ?? '',
      });
    }

    if (mounted) setState(() { _cards = cards; _loading = false; });
  }

  Future<void> _swipe(String direction) async {
    final uid = _uid;
    if (uid == null || _currentIndex >= _cards.length) return;
    final target = _cards[_currentIndex];
    final targetUid = target['uid'] as String;

    HapticFeedback.mediumImpact();

    // Record swipe
    await _db
        .collection('vibe_match_swipes').doc(uid)
        .collection('swipes').doc(targetUid)
        .set({'direction': direction, 'ts': Timestamp.now()});

    // Check for mutual match on right swipe
    if (direction == 'right') {
      final theirSwipe = await _db
          .collection('vibe_match_swipes').doc(targetUid)
          .collection('swipes').doc(uid)
          .get();
      if (theirSwipe.exists &&
          (theirSwipe.data() as Map)['direction'] == 'right') {
        await _createMatch(uid, targetUid, target);
      }
    }

    setState(() {
      _dragX = 0;
      _dragY = 0;
      _currentIndex++;
      _isDragging = false;
    });
  }

  Future<void> _createMatch(
      String uid, String targetUid, Map<String, dynamic> target) async {
    final ids = [uid, targetUid]..sort();
    final compositeId = ids.join('_');
    await _db.collection('vibe_match_matches').doc(compositeId).set({
      'uid1': ids[0], 'uid2': ids[1],
      'name1': _state.displayName, 'name2': target['name'],
      'matchedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // Show match dialog
    if (mounted) _showMatchDialog(target);
  }

  void _showMatchDialog(Map<String, dynamic> target) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('orbit sync! 🪐', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 28)),
          const SizedBox(height: 8),
          Text('you and ${target['name']} have the same vibe',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _MatchAvatar(photo: null, initial: _state.displayName[0]),
            const SizedBox(width: 12),
            const Text('✨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            _MatchAvatar(
                photo: target['photo'] as String?,
                initial: (target['name'] as String)[0]),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('keep swiping',
                  style: TextStyle(color: Color(0xFF7B2FF7),
                      fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('vibe match 💫',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => _showMatches(context),
            child: const Text('matches',
                style: TextStyle(color: AuraTheme.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AuraTheme.accent, strokeWidth: 2))
          : _currentIndex >= _cards.length
              ? _emptyState()
              : Column(children: [
                  Expanded(child: _buildSwipeArea()),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ]),
    );
  }

  Widget _buildSwipeArea() {
    final card = _cards[_currentIndex];
    final angle = _dragX / 400.0;
    final swipeDir = _dragX > 60
        ? 'right'
        : _dragX < -60
            ? 'left'
            : null;

    return Stack(children: [
      // Next card (visible behind)
      if (_currentIndex + 1 < _cards.length)
        Center(child: Transform.scale(
          scale: 0.92,
          child: _VibeCard(card: _cards[_currentIndex + 1],
              swipeDir: null, opacity: 0.6),
        )),
      // Current card (draggable)
      Center(
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanUpdate: (d) => setState(() {
            _dragX += d.delta.dx;
            _dragY += d.delta.dy;
          }),
          onPanEnd: (_) {
            if (_dragX.abs() > 100) {
              _swipe(_dragX > 0 ? 'right' : 'left');
            } else {
              setState(() { _dragX = 0; _dragY = 0; _isDragging = false; });
            }
          },
          child: Transform.translate(
            offset: Offset(_dragX, _dragY),
            child: Transform.rotate(
              angle: angle,
              child: _VibeCard(card: card, swipeDir: swipeDir, opacity: 1.0),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _ActionBtn(icon: Icons.close_rounded, color: Colors.red,
            onTap: () => _swipe('left')),
        _ActionBtn(icon: Icons.favorite_rounded, color: AuraTheme.accent,
            onTap: () => _swipe('right'), large: true),
        _ActionBtn(icon: Icons.refresh_rounded, color: Colors.orange,
            onTap: () => setState(() {
              if (_currentIndex > 0) _currentIndex--;
            })),
      ]),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('💫', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 14),
      Text('you\'ve seen everyone!',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
      const SizedBox(height: 6),
      Text('check back later for new orbiters',
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          setState(() { _currentIndex = 0; });
          _loadCards();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AuraTheme.accent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('refresh',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
    ]),
  );

  void _showMatches(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchesSheet(uid: _uid ?? ''),
    );
  }
}

// ──────────────── Vibe Card ──────────────────────────────────────────────────

class _VibeCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final String? swipeDir;
  final double opacity;
  const _VibeCard({required this.card, this.swipeDir, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final name = card['name'] as String;
    final photo = card['photo'] as String?;
    final topSong = card['topSong'] as String;
    final topArtist = card['topArtist'] as String;
    final artUrl = card['topArtUrl'] as String?;
    final mood = card['mood'] as String;
    final era = card['era'] as String;
    final bio = card['bio'] as String;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: MediaQuery.of(context).size.width - 40,
        height: MediaQuery.of(context).size.height * 0.56,
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(children: [
          // Art background blur
          if (artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Opacity(
                opacity: 0.12,
                child: CachedNetworkImage(imageUrl: artUrl,
                    width: double.infinity, height: double.infinity,
                    fit: BoxFit.cover),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photo != null
                      ? CachedNetworkImageProvider(photo) : null,
                  backgroundColor: AuraTheme.accent.withOpacity(0.3),
                  child: photo == null
                      ? Text(name[0].toUpperCase(),
                          style: const TextStyle(color: AuraTheme.accent,
                              fontWeight: FontWeight.w900, fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 20)),
                  if (era.isNotEmpty)
                    Text(era, style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 12)),
                ])),
                Text(mood, style: const TextStyle(fontSize: 30)),
              ]),
              const SizedBox(height: 20),
              if (bio.isNotEmpty) ...[
                Text('"$bio"',
                    style: TextStyle(color: Colors.white.withOpacity(0.6),
                        fontSize: 13, fontStyle: FontStyle.italic, height: 1.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
              ],
              Text('🎵 top song right now',
                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(children: [
                if (artUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(imageUrl: artUrl,
                        width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: AuraTheme.surface,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.music_note_rounded,
                          color: AuraTheme.accent, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(topSong, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                  Text(topArtist, style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 12)),
                ])),
              ]),
              const Spacer(),
              Text('swipe right to orbit sync  ·  left to pass',
                  style: TextStyle(color: Colors.white.withOpacity(0.2),
                      fontSize: 10),
                  textAlign: TextAlign.center),
            ]),
          ),

          // Swipe indicators
          if (swipeDir == 'right')
            Positioned(top: 28, left: 20,
              child: _SwipeLabel(text: 'ORBIT ✨', color: AuraTheme.accent),
            ),
          if (swipeDir == 'left')
            Positioned(top: 28, right: 20,
              child: _SwipeLabel(text: 'PASS', color: Colors.red),
            ),
        ]),
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SwipeLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: text.startsWith('O') ? -0.4 : 0.4,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color,
          fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;
  const _ActionBtn({required this.icon, required this.color,
      required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: large ? [BoxShadow(color: color.withOpacity(0.2),
              blurRadius: 16, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(icon, color: color, size: large ? 32 : 24),
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  final String? photo;
  final String initial;
  const _MatchAvatar({this.photo, required this.initial});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 36,
    backgroundImage: photo != null
        ? CachedNetworkImageProvider(photo!) : null,
    backgroundColor: Colors.white.withOpacity(0.3),
    child: photo == null
        ? Text(initial.toUpperCase(), style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))
        : null,
  );
}

// ──────────────── Matches Sheet ──────────────────────────────────────────────

class _MatchesSheet extends StatelessWidget {
  final String uid;
  const _MatchesSheet({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        const Text('orbit syncs 💫',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vibe_match_matches')
                .where('uid1', isEqualTo: uid)
                .orderBy('matchedAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (ctx, snap1) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vibe_match_matches')
                    .where('uid2', isEqualTo: uid)
                    .orderBy('matchedAt', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (ctx, snap2) {
                  final docs1 = snap1.data?.docs ?? [];
                  final docs2 = snap2.data?.docs ?? [];
                  final all = [...docs1, ...docs2];
                  if (all.isEmpty) {
                    return Center(child: Text('no orbit syncs yet\nkeep swiping!',
                        style: TextStyle(color: Colors.white.withOpacity(0.3),
                            fontSize: 14), textAlign: TextAlign.center));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final data = all[i].data() as Map<String, dynamic>;
                      final otherName = data['uid1'] == uid
                          ? data['name2'] as String? ?? 'Orbiter'
                          : data['name1'] as String? ?? 'Orbiter';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AuraTheme.accent.withOpacity(0.2),
                          child: Text(otherName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AuraTheme.accent,
                                  fontWeight: FontWeight.w900)),
                        ),
                        title: Text(otherName,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        subtitle: Text('orbit sync ✨',
                            style: TextStyle(color: AuraTheme.accent,
                                fontSize: 12)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
