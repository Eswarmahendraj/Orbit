import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Orbit Moment — BeReal-style daily music check-in
//
// Once a day, a notification fires. User has 5 minutes to log what they're
// listening to right now. Miss it → "missed the moment" badge.
// Friends can see each other's moments in real time.
// ─────────────────────────────────────────────────────────────────────────────

class OrbitMomentScreen extends StatefulWidget {
  const OrbitMomentScreen({super.key});

  @override
  State<OrbitMomentScreen> createState() => _OrbitMomentScreenState();
}

class _OrbitMomentScreenState extends State<OrbitMomentScreen> {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool _capturing = false;
  List<Map<String, dynamic>> _friendMoments = [];
  Map<String, dynamic>? _myTodayMoment;
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMoments() async {
    final uid = _uid;
    if (uid == null) return;

    // Check my moment for today
    final mySnap = await _db
        .collection('orbit_moments')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: _todayKey)
        .limit(1)
        .get();

    if (mySnap.docs.isNotEmpty) {
      _myTodayMoment =
          mySnap.docs.first.data() as Map<String, dynamic>;
    }

    // Get friends' moments for today
    try {
      final followSnap = await _db
          .collection('follows')
          .where('followerId', isEqualTo: uid)
          .get();
      final friendUids = followSnap.docs
          .map((d) => d.data()['targetId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (friendUids.isNotEmpty) {
        // Firestore whereIn limit = 30
        final chunks = <List<String>>[];
        for (var i = 0; i < friendUids.length; i += 30) {
          chunks.add(friendUids.sublist(
              i, i + 30 > friendUids.length ? friendUids.length : i + 30));
        }
        final moments = <Map<String, dynamic>>[];
        for (final chunk in chunks) {
          final snap = await _db
              .collection('orbit_moments')
              .where('uid', whereIn: chunk)
              .where('date', isEqualTo: _todayKey)
              .orderBy('createdAt', descending: true)
              .get();
          moments.addAll(snap.docs.map((d) => d.data() as Map<String, dynamic>));
        }
        _friendMoments = moments;
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingFriends = false);
  }

  Future<void> _captureMoment() async {
    setState(() => _capturing = true);
    // Show song picker bottom sheet
    final song = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MomentSongPicker(),
    );
    if (song == null || !mounted) {
      setState(() => _capturing = false);
      return;
    }

    final uid = _uid;
    if (uid == null) { setState(() => _capturing = false); return; }

    final myName = _state.displayName;
    final myPhoto = _state.pfpUrl;
    final now = DateTime.now();
    final doc = {
      'uid': uid,
      'name': myName,
      'photoUrl': myPhoto,
      'song': song['song'],
      'artist': song['artist'],
      'artUrl': song['artUrl'],
      'date': _todayKey,
      'createdAt': Timestamp.fromDate(now),
      'missedMoment': false,
    };

    await _db.collection('orbit_moments').add(doc);
    setState(() {
      _myTodayMoment = doc;
      _capturing = false;
    });

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Moment captured! 📸 Your orbit can see it now.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('orbit moment',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(_todayKey,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() { _loadingFriends = true; _friendMoments = []; });
              _loadMoments();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // My moment card
          _MyMomentCard(
            moment: _myTodayMoment,
            capturing: _capturing,
            onCapture: _captureMoment,
          ),
          const SizedBox(height: 24),
          // Friends' moments
          Text("your orbit's moment",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          if (_loadingFriends)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AuraTheme.accent),
            ))
          else if (_friendMoments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Text('🌑', style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('no moments yet today',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('check back later or share yours first',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12)),
                ]),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _friendMoments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FriendMomentCard(
                  moment: _friendMoments[i]),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Moment Card
// ─────────────────────────────────────────────────────────────────────────────

class _MyMomentCard extends StatelessWidget {
  final Map<String, dynamic>? moment;
  final bool capturing;
  final VoidCallback onCapture;

  const _MyMomentCard({
    required this.moment,
    required this.capturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    if (moment != null) {
      // Already captured today
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AuraTheme.accent, AuraTheme.accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AuraTheme.accent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          if (moment!['artUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                  imageUrl: moment!['artUrl'] as String,
                  width: 60, height: 60, fit: BoxFit.cover),
            )
          else
            Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('your moment',
                style: TextStyle(color: Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(moment!['song'] as String? ?? '',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 16)),
            Text(moment!['artist'] as String? ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          const Text('✅', style: TextStyle(fontSize: 24)),
        ]),
      );
    }

    // Not captured yet
    return GestureDetector(
      onTap: capturing ? null : onCapture,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AuraTheme.accent.withOpacity(0.4),
              width: 1.5),
        ),
        child: Column(children: [
          const Text('📸', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('capture your moment',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 4),
          Text('what are you listening to right now?',
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: capturing ? null : onCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: capturing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('capture now ⚡',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend Moment Card
// ─────────────────────────────────────────────────────────────────────────────

class _FriendMomentCard extends StatelessWidget {
  final Map<String, dynamic> moment;
  const _FriendMomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    final ts = moment['createdAt'];
    String timeStr = '';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) timeStr = '${diff.inMinutes}m ago';
      else timeStr = '${diff.inHours}h ago';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundImage: moment['photoUrl'] != null
              ? CachedNetworkImageProvider(moment['photoUrl'] as String)
              : null,
          backgroundColor: AuraTheme.accent.withOpacity(0.3),
          child: moment['photoUrl'] == null
              ? Text(
                  (moment['name'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AuraTheme.accent, fontWeight: FontWeight.w900),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Text(moment['name'] as String? ?? '',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text(timeStr,
                style: TextStyle(color: Colors.white.withOpacity(0.35),
                    fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            if (moment['artUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                    imageUrl: moment['artUrl'] as String,
                    width: 32, height: 32, fit: BoxFit.cover),
              )
            else
              Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: AuraTheme.surface,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.music_note_rounded,
                      color: AuraTheme.accent, size: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(moment['song'] as String? ?? '',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              Text(moment['artist'] as String? ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Song Picker for moment capture
// ─────────────────────────────────────────────────────────────────────────────

class _MomentSongPicker extends StatefulWidget {
  const _MomentSongPicker();

  @override
  State<_MomentSongPicker> createState() => _MomentSongPickerState();
}

class _MomentSongPickerState extends State<_MomentSongPicker> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        const Text("what's playing?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          onChanged: _search,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search for the song...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4)),
            suffixIcon: _searching
                ? const Padding(padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AuraTheme.accent)))
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_results.isNotEmpty)
          SizedBox(
            height: 280,
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final t = _results[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: t['artUrl'] != null
                        ? CachedNetworkImage(
                            imageUrl: t['artUrl'] as String,
                            width: 44, height: 44, fit: BoxFit.cover)
                        : Container(width: 44, height: 44,
                            color: AuraTheme.surface,
                            child: const Icon(Icons.music_note_rounded,
                                color: AuraTheme.accent)),
                  ),
                  title: Text(t['song'] as String,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(t['artist'] as String,
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontSize: 12)),
                  onTap: () => Navigator.pop(context, t),
                );
              },
            ),
          ),
      ]),
    );
  }
}
