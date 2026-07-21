import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Song Dares — dare a friend to listen to a full song without skipping
// Accept → mark complete or admit you skipped. Dare streak tracked.
// ─────────────────────────────────────────────────────────────────────────────

class SongDareScreen extends StatefulWidget {
  const SongDareScreen({super.key});
  @override
  State<SongDareScreen> createState() => _SongDareScreenState();
}

class _SongDareScreenState extends State<SongDareScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('song dares 🎯',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'incoming'),
            Tab(text: 'sent'),
            Tab(text: 'dare someone'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DareInbox(uid: _uid ?? ''),
          _DareSent(uid: _uid ?? ''),
          _SendDare(uid: _uid ?? '', state: _state,
              onSent: () => _tabs.animateTo(1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incoming Dares
// ─────────────────────────────────────────────────────────────────────────────

class _DareInbox extends StatelessWidget {
  final String uid;
  const _DareInbox({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('song_dares')
          .where('toUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _empty('no dares incoming 😌',
              'your friends haven\'t dared you yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _IncomingDareCard(
              docId: docs[i].id,
              data: docs[i].data() as Map<String, dynamic>,
              myUid: uid),
        );
      },
    );
  }
}

class _IncomingDareCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  const _IncomingDareCard({required this.docId, required this.data, required this.myUid});

  Future<void> _respond(BuildContext ctx, String status) async {
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('song_dares').doc(docId)
        .update({'status': status, 'respondedAt': Timestamp.now()});
    if (ctx.mounted && status == 'completed') {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('dare completed! 🎯 streak +1'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = data['song'] as String? ?? '';
    final artist = data['artist'] as String? ?? '';
    final artUrl = data['artUrl'] as String?;
    final fromName = data['fromName'] as String? ?? 'someone';
    final status = data['status'] as String? ?? 'pending';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'completed': statusColor = Colors.green; statusText = '✅ completed';
      case 'skipped': statusColor = Colors.red; statusText = '💀 skipped';
      case 'accepted': statusColor = Colors.orange; statusText = '⏳ in progress';
      default: statusColor = AuraTheme.accent; statusText = '🎯 new dare';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: status == 'pending'
            ? Border.all(color: AuraTheme.accent.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🎯 $fromName dares you',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusText,
                style: TextStyle(color: statusColor,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                  imageUrl: artUrl, width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            Container(width: 48, height: 48,
                decoration: BoxDecoration(
                    color: AuraTheme.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.music_note_rounded,
                    color: AuraTheme.accent, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(song, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 15)),
            Text(artist, style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12)),
          ])),
        ]),
        if (status == 'pending') ...[
          const SizedBox(height: 14),
          Text('listen to the full song without skipping',
              style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respond(context, 'completed'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: BorderSide(color: Colors.green.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('listened ✅'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _respond(context, 'skipped'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('i skipped 💀'),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent Dares
// ─────────────────────────────────────────────────────────────────────────────

class _DareSent extends StatelessWidget {
  final String uid;
  const _DareSent({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('song_dares')
          .where('fromUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _empty('no dares sent yet',
              'dare someone to listen to a song');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final song = data['song'] as String? ?? '';
            final artist = data['artist'] as String? ?? '';
            final toName = data['toName'] as String? ?? 'someone';
            final status = data['status'] as String? ?? 'pending';

            Color statusColor;
            String statusText;
            switch (status) {
              case 'completed': statusColor = Colors.green; statusText = '✅ they did it!';
              case 'skipped': statusColor = Colors.red; statusText = '💀 they skipped';
              default: statusColor = Colors.orange; statusText = '⏳ waiting...';
            }

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuraTheme.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('dared $toName',
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontSize: 11)),
                  Text(song, style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(artist, style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText,
                      style: TextStyle(color: statusColor,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send a Dare
// ─────────────────────────────────────────────────────────────────────────────

class _SendDare extends StatefulWidget {
  final String uid;
  final OrbitState state;
  final VoidCallback onSent;
  const _SendDare({required this.uid, required this.state, required this.onSent});

  @override
  State<_SendDare> createState() => _SendDareState();
}

class _SendDareState extends State<_SendDare> {
  final _songCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _picked;
  bool _searching = false;
  bool _sending = false;
  Map<String, dynamic>? _pickedFriend;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() { _songCtrl.dispose(); super.dispose(); }

  Future<void> _loadFriends() async {
    if (widget.uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: widget.uid)
          .limit(30)
          .get();
      final uids = snap.docs.map((d) => d.data()['targetId'] as String? ?? '').toList();
      if (uids.isEmpty) return;
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids.take(30).toList())
          .get();
      if (mounted) {
        setState(() {
          _friends = userSnap.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {'uid': d.id, 'name': data['displayName'] ?? 'Orbiter',
                    'photo': data['photoUrl']};
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _send() async {
    final s = _picked;
    final f = _pickedFriend;
    if (s == null || f == null) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('song_dares').add({
      'fromUid': widget.uid,
      'fromName': widget.state.displayName,
      'toUid': f['uid'],
      'toName': f['name'],
      'song': s['song'],
      'artist': s['artist'],
      'artUrl': s['artUrl'],
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
    HapticFeedback.mediumImpact();
    setState(() { _sending = false; _picked = null; _pickedFriend = null; });
    _songCtrl.clear();
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('pick a song they HAVE to listen to fully',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 20),

        _sectionLabel('pick a song'),
        TextField(
          controller: _songCtrl,
          onChanged: _search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('${_picked!['song']} — ${_picked!['artist']}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600))),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                onPressed: () => setState(() { _picked = null; _results = []; }),
              ),
            ]),
          ),
        ] else if (_results.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...(_results.take(4).map((t) => ListTile(
            dense: true,
            title: Text(t['song'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(t['artist'] as String,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () => setState(() { _picked = t; _results = [];
                _songCtrl.text = t['song'] as String; }),
          ))),
        ],

        const SizedBox(height: 20),
        _sectionLabel('dare who?'),
        if (_friends.isEmpty)
          Text('follow someone first!',
              style: TextStyle(color: Colors.white.withOpacity(0.3)))
        else
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _friends.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final f = _friends[i];
                final selected = _pickedFriend?['uid'] == f['uid'];
                return GestureDetector(
                  onTap: () => setState(() => _pickedFriend = f),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: selected ? AuraTheme.accent : Colors.transparent,
                            width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundImage: f['photo'] != null
                            ? CachedNetworkImageProvider(f['photo'] as String)
                            : null,
                        backgroundColor: AuraTheme.accent.withOpacity(0.3),
                        child: f['photo'] == null
                            ? Text((f['name'] as String)[0].toUpperCase(),
                                style: const TextStyle(color: AuraTheme.accent,
                                    fontWeight: FontWeight.w900))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text((f['name'] as String).split(' ').first,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white54,
                            fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ]),
                );
              },
            ),
          ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_picked != null && _pickedFriend != null && !_sending)
                ? _send : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              disabledBackgroundColor: Colors.white.withOpacity(0.07),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _sending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('send the dare 🎯',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: TextStyle(color: Colors.white.withOpacity(0.5),
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

Widget _empty(String title, String sub) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🎯', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    Text(title, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15)),
    const SizedBox(height: 4),
    Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
  ]),
);
