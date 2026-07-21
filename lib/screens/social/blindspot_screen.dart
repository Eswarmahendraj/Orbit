import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Blindspot — anonymous listener discovery
// Pulsing anonymous dots → send an anonymous song → mutual reveal unmasks
// ─────────────────────────────────────────────────────────────────────────────

class BlindspotScreen extends StatefulWidget {
  const BlindspotScreen({super.key});
  @override
  State<BlindspotScreen> createState() => _BlindspotScreenState();
}

class _BlindspotScreenState extends State<BlindspotScreen>
    with TickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Pulse animations for the anonymous dots
  final List<AnimationController> _dotCtrl = [];
  final List<Animation<double>> _dotAnim = [];

  // Random dot positions (seeded by time so they don't jump)
  late List<Offset> _dotPositions;
  late List<String> _dotIds; // anonymous session IDs

  @override
  void initState() {
    super.initState();
    _generateDots();
    _registerPresence();
  }

  @override
  void dispose() {
    for (final c in _dotCtrl) c.dispose();
    _unregisterPresence();
    super.dispose();
  }

  void _generateDots() {
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 60000);
    const count = 7;
    _dotPositions = List.generate(
        count,
        (_) => Offset(0.1 + rng.nextDouble() * 0.8,
            0.1 + rng.nextDouble() * 0.8));
    _dotIds = List.generate(count, (i) => 'anon_${i}_${rng.nextInt(9999)}');

    for (int i = 0; i < count; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200 + rng.nextInt(800)),
        lowerBound: 0.85,
        upperBound: 1.15,
      )..repeat(reverse: true);
      _dotCtrl.add(ctrl);
      _dotAnim.add(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }
  }

  Future<void> _registerPresence() async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('blindspot_presence').doc(uid).set({
      'uid': uid,
      'anonId': 'listener_${uid.substring(0, 6)}',
      'song': _state.vibeSong.isNotEmpty ? _state.vibeSong : 'something good',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _unregisterPresence() async {
    final uid = _uid;
    if (uid == null) return;
    _db.collection('blindspot_presence').doc(uid).delete().catchError((_) {});
  }

  void _tapDot(int index) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendSongSheet(
        anonId: _dotIds[index],
        senderUid: _uid ?? '',
        senderState: _state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('blindspot 👁️',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          // Show my incoming blind messages
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded),
            tooltip: 'My blind messages',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _InboxSheet(uid: _uid ?? '', state: _state),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'there are listeners nearby. tap a dot to send an anonymous song.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        // Dot field
        Expanded(
          child: LayoutBuilder(builder: (ctx, box) {
            return Stack(
              children: [
                // Ambient glow
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AuraTheme.accent.withOpacity(0.08),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // "You" dot in center
                Positioned(
                  left: box.maxWidth / 2 - 20,
                  top: box.maxHeight / 2 - 20,
                  child: Column(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AuraTheme.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AuraTheme.accent.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 4),
                    Text('you',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10)),
                  ]),
                ),
                // Anonymous listener dots
                ..._dotPositions.asMap().entries.map((e) {
                  final i = e.key;
                  final pos = e.value;
                  return Positioned(
                    left: pos.dx * box.maxWidth - 16,
                    top: pos.dy * box.maxHeight - 16,
                    child: GestureDetector(
                      onTap: () => _tapDot(i),
                      child: ScaleTransition(
                        scale: _dotAnim[i],
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 12,
                                  spreadRadius: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
        // Active presence count from Firestore
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('blindspot_presence')
              .where('updatedAt', isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(minutes: 10))))
              .snapshots(),
          builder: (ctx, snap) {
            final count = (snap.data?.docs.length ?? 1) - 1; // exclude self
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '$count ${count == 1 ? 'listener' : 'listeners'} nearby right now',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send song sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SendSongSheet extends StatefulWidget {
  final String anonId;
  final String senderUid;
  final OrbitState senderState;
  const _SendSongSheet({
    required this.anonId,
    required this.senderUid,
    required this.senderState,
  });

  @override
  State<_SendSongSheet> createState() => _SendSongSheetState();
}

class _SendSongSheetState extends State<_SendSongSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _picked;
  bool _searching = false;
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _send() async {
    final s = _picked;
    if (s == null) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('blindspot_messages').add({
      'toAnonId': widget.anonId,
      'fromUid': widget.senderUid,
      'song': s['song'],
      'artist': s['artist'],
      'artUrl': s['artUrl'],
      'revealed': false,
      'fromRevealed': false,
      'toRevealed': false,
      'createdAt': Timestamp.now(),
    });
    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('song sent anonymously 👁️'),
        behavior: SnackBarBehavior.floating,
      ));
    }
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
        const Text('send an anonymous song 👁️',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text('they won\'t know it\'s from you unless you both reveal',
            style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          onChanged: _search,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search for a song to send...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        if (_picked != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('🎵', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${_picked!['song']} — ${_picked!['artist']}',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600),
              )),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('send anonymously',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ] else if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _results.take(5).length,
              itemBuilder: (_, i) {
                final t = _results[i];
                return ListTile(
                  leading: t['artUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                              imageUrl: t['artUrl'] as String,
                              width: 36, height: 36, fit: BoxFit.cover))
                      : const Icon(Icons.music_note_rounded,
                          color: AuraTheme.accent),
                  title: Text(t['song'] as String,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(t['artist'] as String,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11)),
                  onTap: () => setState(() {
                    _picked = t;
                    _results = [];
                    _ctrl.text = t['song'] as String;
                  }),
                );
              },
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox — my received blind songs
// ─────────────────────────────────────────────────────────────────────────────

class _InboxSheet extends StatelessWidget {
  final String uid;
  final OrbitState state;
  const _InboxSheet({required this.uid, required this.state});

  String get _myAnonId => 'listener_${uid.substring(0, 6)}';

  Future<void> _reveal(BuildContext ctx, String docId) async {
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('blindspot_messages').doc(docId)
        .update({'toRevealed': true});
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('you revealed yourself! if they do too, you both unmask 👁️'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2)))),
        const Text('blind songs received 👁️',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blindspot_messages')
                .where('toAnonId', isEqualTo: _myAnonId)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (ctx, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('no blind songs yet',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35))));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final bothRevealed =
                      data['fromRevealed'] == true &&
                          data['toRevealed'] == true;
                  final iRevealed = data['toRevealed'] == true;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bothRevealed
                          ? AuraTheme.accent.withOpacity(0.12)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Text('🎵', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(data['song'] as String? ?? '',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        Text(data['artist'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        if (bothRevealed)
                          Text('from: ${data['fromName'] ?? 'an orbiter'}',
                              style: TextStyle(
                                  color: AuraTheme.accent, fontSize: 11))
                        else
                          Text('from: anonymous 👁️',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 11)),
                      ])),
                      if (!iRevealed)
                        TextButton(
                          onPressed: () => _reveal(context, docs[i].id),
                          child: const Text('reveal',
                              style: TextStyle(color: AuraTheme.accent,
                                  fontSize: 12)),
                        ),
                    ]),
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
