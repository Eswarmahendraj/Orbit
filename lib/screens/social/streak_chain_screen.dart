import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Listening Streak Chains
//
// When both you and a friend post Orbit Moments for 7 consecutive days,
// a "Sync Chain" badge appears on both profiles.
//
// Collections:
//   orbit_moments — existing, has uid + date (yyyy-MM-dd) field
//   streak_chains/{compositeId} — {uid1, uid2, streakDays, lastChecked, active}
//
// Logic:
//   On opening this screen, compute streak with each friend by querying
//   orbit_moments for the last 7 days for each pair.
// ─────────────────────────────────────────────────────────────────────────────

class StreakChainScreen extends StatefulWidget {
  const StreakChainScreen({super.key});
  @override
  State<StreakChainScreen> createState() => _StreakChainScreenState();
}

class _StreakChainScreenState extends State<StreakChainScreen> {
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool _loading = true;
  List<_FriendStreak> _streaks = [];

  @override
  void initState() {
    super.initState();
    _computeStreaks();
  }

  Future<void> _computeStreaks() async {
    final uid = _uid;
    if (uid == null) { setState(() => _loading = false); return; }

    // Get friends
    final followSnap = await FirebaseFirestore.instance
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .limit(30)
        .get();
    final friendUids = followSnap.docs
        .map((d) => d.data()['targetId'] as String? ?? '').toList();

    if (friendUids.isEmpty) {
      setState(() { _streaks = []; _loading = false; });
      return;
    }

    // Get user details for friends
    final userChunks = _chunks(friendUids, 30);
    final friendMap = <String, Map<String, dynamic>>{};
    for (final chunk in userChunks) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        friendMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }

    // Build last 7 date strings
    final today = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = today.subtract(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    // Get MY moments for last 7 days
    final myMomentSnap = await FirebaseFirestore.instance
        .collection('orbit_moments')
        .where('uid', isEqualTo: uid)
        .where('date', whereIn: last7)
        .get();
    final myDates = myMomentSnap.docs
        .map((d) => d.data()['date'] as String? ?? '').toSet();

    // Compute streak with each friend
    final streaks = <_FriendStreak>[];
    for (final fuid in friendUids.take(30)) {
      final friendMomentSnap = await FirebaseFirestore.instance
          .collection('orbit_moments')
          .where('uid', isEqualTo: fuid)
          .where('date', whereIn: last7)
          .get();
      final friendDates = friendMomentSnap.docs
          .map((d) => d.data()['date'] as String? ?? '').toSet();

      // Consecutive mutual days from today backwards
      int streak = 0;
      for (final dateStr in last7) {
        if (myDates.contains(dateStr) && friendDates.contains(dateStr)) {
          streak++;
        } else {
          break;
        }
      }

      final fdata = friendMap[fuid] ?? {};
      streaks.add(_FriendStreak(
        uid: fuid,
        name: fdata['displayName'] as String? ?? 'Orbiter',
        photo: fdata['photoUrl'] as String?,
        streakDays: streak,
        myDates: myDates,
        friendDates: friendDates,
        last7: last7,
      ));

      // Write/update streak_chain doc if streak >= 1
      if (streak > 0) {
        final ids = [uid, fuid]..sort();
        await FirebaseFirestore.instance
            .collection('streak_chains')
            .doc(ids.join('_'))
            .set({
          'uid1': ids[0], 'uid2': ids[1],
          'streakDays': streak,
          'active': streak >= 7,
          'lastChecked': Timestamp.now(),
        }, SetOptions(merge: true));
      }
    }

    streaks.sort((a, b) => b.streakDays.compareTo(a.streakDays));

    if (mounted) setState(() { _streaks = streaks; _loading = false; });
  }

  List<List<T>> _chunks<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(i, i + size < list.length ? i + size : list.length));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('streak chains 🔗',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AuraTheme.accent, strokeWidth: 2))
          : _streaks.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    ..._streaks.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StreakCard(streak: s),
                    )),
                  ],
                ),
    );
  }

  Widget _header() {
    final best = _streaks.isEmpty ? 0 : _streaks.first.streakDays;
    final chains = _streaks.where((s) => s.streakDays >= 7).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141e30), Color(0xFF4286f4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('your best streak',
              style: TextStyle(color: Colors.white60,
                  fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('$best days 🔥',
              style: const TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.w900)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('sync chains',
              style: TextStyle(color: Colors.white60,
                  fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text('$chains 🔗',
              style: const TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔗', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      Text('no streak data yet',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
      const SizedBox(height: 6),
      Text('post orbit moments daily to build a chain\nwith your friends',
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}

// ──────────────── Streak Card ────────────────────────────────────────────────

class _FriendStreak {
  final String uid;
  final String name;
  final String? photo;
  final int streakDays;
  final Set<String> myDates;
  final Set<String> friendDates;
  final List<String> last7;

  const _FriendStreak({
    required this.uid,
    required this.name,
    this.photo,
    required this.streakDays,
    required this.myDates,
    required this.friendDates,
    required this.last7,
  });

  bool get isSyncChain => streakDays >= 7;
}

class _StreakCard extends StatelessWidget {
  final _FriendStreak streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: streak.isSyncChain
            ? Border.all(
                color: const Color(0xFF4286f4).withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: streak.photo != null
                ? CachedNetworkImageProvider(streak.photo!) : null,
            backgroundColor: AuraTheme.accent.withOpacity(0.3),
            child: streak.photo == null
                ? Text(streak.name[0].toUpperCase(),
                    style: const TextStyle(color: AuraTheme.accent,
                        fontWeight: FontWeight.w900, fontSize: 16))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(streak.name, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15)),
            if (streak.isSyncChain)
              Row(children: [
                const Text('🔗', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('sync chain unlocked!',
                    style: const TextStyle(color: Color(0xFF4286f4),
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${streak.streakDays}',
                style: TextStyle(
                    color: streak.streakDays > 0 ? Colors.orange : Colors.white38,
                    fontWeight: FontWeight.w900, fontSize: 24)),
            Text('day${streak.streakDays == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.white.withOpacity(0.35),
                    fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 14),
        // 7-dot visual chain
        Row(children: List.generate(7, (i) {
          final dateStr = streak.last7[6 - i]; // oldest first
          final iMutual = streak.myDates.contains(dateStr) &&
              streak.friendDates.contains(dateStr);
          final iMe = streak.myDates.contains(dateStr);
          final iFriend = streak.friendDates.contains(dateStr);
          final isToday = i == 6;

          Color dotColor;
          if (iMutual) dotColor = Colors.orange;
          else if (iMe || iFriend) dotColor = AuraTheme.accent.withOpacity(0.4);
          else dotColor = Colors.white.withOpacity(0.08);

          return Expanded(child: Column(children: [
            Container(
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: iMutual
                  ? const Center(child: Text('🔥',
                      style: TextStyle(fontSize: 12)))
                  : null,
            ),
            const SizedBox(height: 4),
            Text(['M','T','W','T','F','S','S'][
                (DateTime.now().subtract(Duration(days: 6 - i)).weekday - 1) % 7],
                style: TextStyle(color: Colors.white.withOpacity(0.2),
                    fontSize: 9)),
          ]));
        })),
        const SizedBox(height: 8),
        Row(children: [
          _Dot(color: Colors.orange),
          const SizedBox(width: 4),
          Text('mutual', style: _legendStyle),
          const SizedBox(width: 12),
          _Dot(color: AuraTheme.accent.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text('one of you', style: _legendStyle),
        ]),
        if (streak.isSyncChain) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF141e30), Color(0xFF4286f4)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔗', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text('sync chain badge earned!',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget get _Dot => const SizedBox();
  TextStyle get _legendStyle =>
      TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10);
}

// Fix the _Dot usage — make it a proper widget
class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ──────────────── Sync Chain Badge (for profile) ─────────────────────────────

class SyncChainBadge extends StatelessWidget {
  final String friendName;
  final int days;
  const SyncChainBadge({super.key, required this.friendName, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141e30), Color(0xFF4286f4)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4286f4).withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔗', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('sync chain with $friendName',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 11)),
          Text('$days day streak 🔥',
              style: TextStyle(color: Colors.white.withOpacity(0.6),
                  fontSize: 10)),
        ]),
      ]),
    );
  }
}
