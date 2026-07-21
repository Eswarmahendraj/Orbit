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
// Music Time Capsule — lock a song + message for a future date
// When it opens, you get notified: "Past you wanted you to hear this."
// Friends can send capsules to each other too.
// ─────────────────────────────────────────────────────────────────────────────

enum _CapsuleTab { mine, send }

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});
  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen>
    with SingleTickerProviderStateMixin {
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
        title: const Text('time capsule ⏳',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'my capsules'),
            Tab(text: 'create one'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyCapsules(uid: _uid ?? '', state: _state),
          _CreateCapsule(uid: _uid ?? '', state: _state,
              onCreated: () => _tabs.animateTo(0)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Capsules List
// ─────────────────────────────────────────────────────────────────────────────

class _MyCapsules extends StatelessWidget {
  final String uid;
  final OrbitState state;
  const _MyCapsules({required this.uid, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('time_capsules')
          .where('toUid', isEqualTo: uid)
          .orderBy('opensAt')
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏳', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('no capsules yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text('send one to yourself or a friend',
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 13)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _CapsuleCard(docId: docs[i].id, data: data, myUid: uid);
          },
        );
      },
    );
  }
}

class _CapsuleCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  const _CapsuleCard({required this.docId, required this.data, required this.myUid});

  Duration get _timeLeft {
    final opensAt = (data['opensAt'] as Timestamp).toDate();
    final diff = opensAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get _isOpen => _timeLeft == Duration.zero;
  bool get _isFromSelf => data['fromUid'] == myUid;

  String _formatCountdown(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return 'opening now...';
  }

  @override
  Widget build(BuildContext context) {
    final song = data['song'] as String? ?? '';
    final artist = data['artist'] as String? ?? '';
    final artUrl = data['artUrl'] as String?;
    final message = data['message'] as String? ?? '';
    final fromName = data['fromName'] as String? ?? 'you';
    final tl = _timeLeft;
    final opened = _isOpen;

    return Container(
      decoration: BoxDecoration(
        gradient: opened
            ? const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: opened ? null : AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: opened ? [
          BoxShadow(
              color: const Color(0xFF11998e).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ] : [],
      ),
      padding: const EdgeInsets.all(16),
      child: opened
          ? _OpenedView(song: song, artist: artist, artUrl: artUrl,
              message: message, fromName: fromName, isFromSelf: _isFromSelf)
          : _LockedView(song: song, countdown: _formatCountdown(tl),
              isFromSelf: _isFromSelf, fromName: fromName),
    );
  }
}

class _LockedView extends StatelessWidget {
  final String song;
  final String countdown;
  final bool isFromSelf;
  final String fromName;
  const _LockedView({required this.song, required this.countdown,
      required this.isFromSelf, required this.fromName});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.lock_rounded, color: AuraTheme.accent, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(isFromSelf ? 'from: past you' : 'from: $fromName',
            style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 11)),
        const SizedBox(height: 2),
        Text('a song is waiting...',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AuraTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(countdown,
              style: const TextStyle(color: AuraTheme.accent,
                  fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ])),
    ]);
  }
}

class _OpenedView extends StatelessWidget {
  final String song;
  final String artist;
  final String? artUrl;
  final String message;
  final String fromName;
  final bool isFromSelf;

  const _OpenedView({required this.song, required this.artist,
      required this.artUrl, required this.message, required this.fromName,
      required this.isFromSelf});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('🎊', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(isFromSelf ? 'past you wanted you to hear this' : '$fromName sent you this',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        if (artUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
                imageUrl: artUrl!, width: 56, height: 56, fit: BoxFit.cover),
          )
        else
          Container(width: 56, height: 56,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.music_note_rounded,
                  color: Colors.white, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(song, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w900, fontSize: 18)),
          Text(artist, style: const TextStyle(color: Colors.white70,
              fontSize: 13)),
        ])),
      ]),
      if (message.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('"$message"',
              style: const TextStyle(color: Colors.white,
                  fontStyle: FontStyle.italic, fontSize: 13, height: 1.5)),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Capsule
// ─────────────────────────────────────────────────────────────────────────────

class _CreateCapsule extends StatefulWidget {
  final String uid;
  final OrbitState state;
  final VoidCallback onCreated;
  const _CreateCapsule({required this.uid, required this.state, required this.onCreated});

  @override
  State<_CreateCapsule> createState() => _CreateCapsuleState();
}

class _CreateCapsuleState extends State<_CreateCapsule> {
  final _songCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _picked;
  bool _searching = false;
  bool _creating = false;
  Duration _unlockIn = const Duration(days: 7);
  bool _sendToFriend = false;
  Map<String, dynamic>? _pickedFriend;
  List<Map<String, dynamic>> _friends = [];

  static const _durations = [
    ('1 week', Duration(days: 7)),
    ('1 month', Duration(days: 30)),
    ('3 months', Duration(days: 90)),
    ('6 months', Duration(days: 180)),
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _songCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _create() async {
    final s = _picked;
    if (s == null) return;
    setState(() => _creating = true);

    final toUid = (_sendToFriend && _pickedFriend != null)
        ? _pickedFriend!['uid'] as String
        : widget.uid;
    final toName = (_sendToFriend && _pickedFriend != null)
        ? _pickedFriend!['name'] as String
        : widget.state.displayName;
    final opensAt = DateTime.now().add(_unlockIn);

    await FirebaseFirestore.instance.collection('time_capsules').add({
      'fromUid': widget.uid,
      'fromName': widget.state.displayName,
      'toUid': toUid,
      'toName': toName,
      'song': s['song'],
      'artist': s['artist'],
      'artUrl': s['artUrl'],
      'message': _msgCtrl.text.trim(),
      'opensAt': Timestamp.fromDate(opensAt),
      'createdAt': Timestamp.now(),
      'opened': false,
    });

    HapticFeedback.mediumImpact();
    setState(() { _creating = false; _picked = null; });
    _songCtrl.clear();
    _msgCtrl.clear();
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('lock a song for your future self — or send to a friend',
            style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 13)),
        const SizedBox(height: 20),

        // Song search
        _label('pick a song'),
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
          _SongChip(song: _picked!, onRemove: () => setState(() => _picked = null)),
        ] else if (_results.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...(_results.take(4).map((t) => ListTile(
            dense: true,
            leading: t['artUrl'] != null
                ? ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(imageUrl: t['artUrl'] as String,
                        width: 36, height: 36, fit: BoxFit.cover))
                : const Icon(Icons.music_note_rounded, color: AuraTheme.accent),
            title: Text(t['song'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(t['artist'] as String,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            onTap: () => setState(() { _picked = t; _results = [];
                _songCtrl.text = t['song'] as String; }),
          ))),
        ],

        const SizedBox(height: 20),

        // Unlock date
        _label('unlock in'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _durations.map((d) {
            final (label, dur) = d;
            final selected = _unlockIn == dur;
            return GestureDetector(
              onTap: () => setState(() => _unlockIn = dur),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AuraTheme.accent : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? AuraTheme.accent : Colors.white.withOpacity(0.1)),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 13)),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Message
        _label('message (optional)'),
        TextField(
          controller: _msgCtrl,
          maxLines: 3,
          maxLength: 150,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'a note to your future self or your friend...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25),
                fontSize: 13),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),

        const SizedBox(height: 16),

        // Send to friend toggle
        Row(children: [
          Switch(
            value: _sendToFriend,
            onChanged: (v) => setState(() => _sendToFriend = v),
            activeColor: AuraTheme.accent,
          ),
          const SizedBox(width: 8),
          Text('send to a friend',
              style: TextStyle(color: Colors.white.withOpacity(0.6),
                  fontSize: 13)),
        ]),

        if (_sendToFriend && _friends.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
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
                            fontSize: 10)),
                  ]),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_picked != null && !_creating &&
                (!_sendToFriend || _pickedFriend != null)) ? _create : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              disabledBackgroundColor: Colors.white.withOpacity(0.07),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _creating
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('seal the capsule ⏳',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text,
        style: TextStyle(color: Colors.white.withOpacity(0.5),
            fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 0.5)),
  );
}

class _SongChip extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onRemove;
  const _SongChip({required this.song, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AuraTheme.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuraTheme.accent.withOpacity(0.35)),
      ),
      child: Row(children: [
        const Text('🎵', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text('${song['song']} — ${song['artist']}',
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 13))),
        IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
            onPressed: onRemove),
      ]),
    );
  }
}
