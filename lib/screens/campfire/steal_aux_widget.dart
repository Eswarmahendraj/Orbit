import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Steal the Aux — Campfire DJ mechanic
//
// One person holds the aux for 30 min. Others vote to steal.
// 3 votes in 30 seconds = aux stolen. New DJ picks a song.
// Embed StealAuxBar in any Campfire screen.
// ─────────────────────────────────────────────────────────────────────────────

/// Embed at the top of a Campfire chat screen.
/// [campfireId] — the Firestore doc ID for this campfire session.
class StealAuxBar extends StatelessWidget {
  final String campfireId;
  const StealAuxBar({super.key, required this.campfireId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campfire_aux')
          .doc(campfireId)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return _NoAuxBar(campfireId: campfireId);
        }
        final data = snap.data!.data() as Map<String, dynamic>;
        return _AuxBar(campfireId: campfireId, data: data);
      },
    );
  }
}

class _NoAuxBar extends StatelessWidget {
  final String campfireId;
  const _NoAuxBar({required this.campfireId});

  Future<void> _claimAux(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final state = OrbitState();
    if (uid == null) return;
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('campfire_aux')
        .doc(campfireId)
        .set({
      'djUid': uid,
      'djName': state.displayName,
      'song': state.vibeSong.isNotEmpty ? state.vibeSong : 'picking now...',
      'artist': state.vibeArtist,
      'claimedAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 30))),
      'stealVotes': <String>[],
      'stealStartedAt': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AuraTheme.surface,
      child: Row(children: [
        const Text('🎛️', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('no one has the aux',
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 13)),
        ),
        TextButton(
          onPressed: () => _claimAux(context),
          child: const Text('grab it',
              style: TextStyle(color: AuraTheme.accent,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _AuxBar extends StatefulWidget {
  final String campfireId;
  final Map<String, dynamic> data;
  const _AuxBar({required this.campfireId, required this.data});

  @override
  State<_AuxBar> createState() => _AuxBarState();
}

class _AuxBarState extends State<_AuxBar> {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  Timer? _voteTimer;

  @override
  void dispose() {
    _voteTimer?.cancel();
    super.dispose();
  }

  bool get _iAmDJ => widget.data['djUid'] == _uid;

  Future<void> _voteSteal() async {
    final uid = _uid;
    if (uid == null || _iAmDJ) return;
    HapticFeedback.mediumImpact();

    final votes = List<String>.from(widget.data['stealVotes'] ?? []);
    if (votes.contains(uid)) return; // already voted

    votes.add(uid);
    final stealStarted = widget.data['stealStartedAt'] as Timestamp?;
    final now = Timestamp.now();

    await _db.collection('campfire_aux').doc(widget.campfireId).update({
      'stealVotes': votes,
      'stealStartedAt': stealStarted ?? now,
    });

    // Check if steal succeeds: 3+ votes within 30s
    if (stealStarted != null) {
      final elapsed = now.toDate().difference(stealStarted.toDate()).inSeconds;
      if (votes.length >= 3 && elapsed <= 30) {
        await _executeSteal(uid);
      }
    }
  }

  Future<void> _executeSteal(String newDjUid) async {
    HapticFeedback.heavyImpact();
    final state = OrbitState();
    await _db.collection('campfire_aux').doc(widget.campfireId).update({
      'djUid': newDjUid,
      'djName': state.displayName,
      'song': 'picking now...',
      'artist': '',
      'claimedAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 30))),
      'stealVotes': <String>[],
      'stealStartedAt': null,
    });
  }

  Future<void> _changeSong(BuildContext context) async {
    if (!_iAmDJ) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DjSongPicker(
        campfireId: widget.campfireId,
        djUid: _uid ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final djName = widget.data['djName'] as String? ?? 'DJ';
    final song = widget.data['song'] as String? ?? '...';
    final votes = List<String>.from(widget.data['stealVotes'] ?? []);
    final myVoted = votes.contains(_uid);
    final stealPct = votes.length / 3.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AuraTheme.surface, AuraTheme.card],
        ),
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(children: [
        // DJ indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AuraTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎛️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(_iAmDJ ? 'you' : djName,
                style: TextStyle(
                    color: _iAmDJ ? AuraTheme.accent : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(song,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13),
                overflow: TextOverflow.ellipsis),
            if (_iAmDJ)
              GestureDetector(
                onTap: () => _changeSong(context),
                child: Text('tap to change song',
                    style: TextStyle(color: AuraTheme.accent, fontSize: 10)),
              ),
          ]),
        ),

        // Steal button (non-DJs)
        if (!_iAmDJ)
          Column(children: [
            GestureDetector(
              onTap: myVoted ? null : _voteSteal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: myVoted
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: myVoted
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.white.withOpacity(0.15),
                      width: 1),
                ),
                child: Text(
                    myVoted ? 'voted 🔥' : 'steal aux 🎛️',
                    style: TextStyle(
                        color: myVoted ? Colors.orange : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (votes.isNotEmpty) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: 70,
                child: LinearProgressIndicator(
                  value: stealPct.clamp(0, 1),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(Colors.orange),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('${votes.length}/3 votes',
                  style: TextStyle(color: Colors.orange.withOpacity(0.7),
                      fontSize: 9)),
            ],
          ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DJ Song Picker
// ─────────────────────────────────────────────────────────────────────────────

class _DjSongPicker extends StatefulWidget {
  final String campfireId;
  final String djUid;
  const _DjSongPicker({required this.campfireId, required this.djUid});

  @override
  State<_DjSongPicker> createState() => _DjSongPickerState();
}

class _DjSongPickerState extends State<_DjSongPicker> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _pick(Map<String, dynamic> t) async {
    await FirebaseFirestore.instance
        .collection('campfire_aux')
        .doc(widget.campfireId)
        .update({
      'song': t['song'],
      'artist': t['artist'],
      'artUrl': t['artUrl'],
      'stealVotes': <String>[],
      'stealStartedAt': null,
    });
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
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
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        const Text('you have the aux 🎛️',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text('pick a song for the campfire',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          onChanged: _search,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search for a song...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4)),
            suffixIcon: _searching
                ? const Padding(padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AuraTheme.accent)))
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ListView.builder(
              itemCount: _results.take(6).length,
              itemBuilder: (_, i) {
                final t = _results[i];
                return ListTile(
                  leading: t['artUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                              imageUrl: t['artUrl'] as String,
                              width: 40, height: 40, fit: BoxFit.cover))
                      : const Icon(Icons.music_note_rounded,
                          color: AuraTheme.accent),
                  title: Text(t['song'] as String,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(t['artist'] as String,
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontSize: 11)),
                  onTap: () => _pick(t),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }
}
