import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Song Secret — send a song anonymously with one emoji
// They can reply with a song + emoji. Both can tap reveal to unmask.
// ─────────────────────────────────────────────────────────────────────────────

// Also contains: Listening Without You widget
// (shows "you both heard X today" in a quiet feed card)

class SongSecretScreen extends StatefulWidget {
  const SongSecretScreen({super.key});
  @override
  State<SongSecretScreen> createState() => _SongSecretScreenState();
}

class _SongSecretScreenState extends State<SongSecretScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('song secret 🤫',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'my secrets'), Tab(text: 'send one')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _InboxTab(uid: _uid ?? '', state: _state),
          _SendTab(uid: _uid ?? '', state: _state, onSent: () {
            _tabs.animateTo(0);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inbox — secrets I've sent and received
// ─────────────────────────────────────────────────────────────────────────────

class _InboxTab extends StatelessWidget {
  final String uid;
  final OrbitState state;
  const _InboxTab({required this.uid, required this.state});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('song_secrets')
          .where('toUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🤫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('no song secrets yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text('send one to a friend — they won\'t know it\'s you',
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 13),
                  textAlign: TextAlign.center),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _SecretCard(
              docId: docs[i].id,
              data: docs[i].data() as Map<String, dynamic>,
              myUid: uid),
        );
      },
    );
  }
}

class _SecretCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  const _SecretCard({required this.docId, required this.data, required this.myUid});

  @override
  State<_SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<_SecretCard> {
  bool _replying = false;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Map<String, dynamic>? _replyPick;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _reveal() async {
    HapticFeedback.mediumImpact();
    final toRevealed = widget.data['toRevealed'] == true;
    final fromRevealed = widget.data['fromRevealed'] == true;
    await FirebaseFirestore.instance
        .collection('song_secrets').doc(widget.docId)
        .update({'toRevealed': true});
    if (!fromRevealed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('you revealed yourself! waiting for them to reveal too...'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _sendReply() async {
    final r = _replyPick;
    if (r == null) return;
    await FirebaseFirestore.instance
        .collection('song_secrets').doc(widget.docId)
        .update({
      'replySong': r['song'],
      'replyArtist': r['artist'],
      'replyArtUrl': r['artUrl'],
      'replyEmoji': '🎵',
    });
    setState(() { _replying = false; _replyPick = null; _results = []; });
    _searchCtrl.clear();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.data['emoji'] as String? ?? '🎵';
    final song = widget.data['song'] as String? ?? '';
    final artist = widget.data['artist'] as String? ?? '';
    final artUrl = widget.data['artUrl'] as String?;
    final myRevealed = widget.data['toRevealed'] == true;
    final theirRevealed = widget.data['fromRevealed'] == true;
    final bothRevealed = myRevealed && theirRevealed;
    final hasReply = widget.data['replySong'] != null;
    final senderName = bothRevealed
        ? (widget.data['fromName'] as String? ?? 'an orbiter')
        : '🤫 mystery orbiter';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: bothRevealed
            ? Border.all(color: AuraTheme.accent.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(song, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 15)),
            Text(artist, style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12)),
            Text('from: $senderName',
                style: TextStyle(
                    color: bothRevealed
                        ? AuraTheme.accent
                        : Colors.white.withOpacity(0.35),
                    fontSize: 11)),
          ])),
          if (artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                  imageUrl: artUrl, width: 44, height: 44, fit: BoxFit.cover),
            ),
        ]),

        if (!myRevealed) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reveal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuraTheme.accent,
                  side: BorderSide(color: AuraTheme.accent.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('reveal yourself'),
              ),
            ),
            if (!hasReply) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _replying = !_replying),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('reply with a song'),
                ),
              ),
            ],
          ]),
        ],

        // Reply UI
        if (_replying) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _search,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'search for reply song...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          if (_replyPick != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(
                '${_replyPick!['song']} — ${_replyPick!['artist']}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              )),
              TextButton(
                onPressed: _sendReply,
                child: const Text('send 🎵',
                    style: TextStyle(color: AuraTheme.accent,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ] else if (_results.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...(_results.take(4).map((t) => ListTile(
              dense: true,
              title: Text(t['song'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              subtitle: Text(t['artist'] as String,
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 11)),
              onTap: () => setState(() {
                _replyPick = t;
                _results = [];
                _searchCtrl.text = t['song'] as String;
              }),
            ))),
          ],
        ],

        // Reply received
        if (hasReply) ...[
          const Divider(color: Colors.white12, height: 24),
          Row(children: [
            Text(widget.data['replyEmoji'] as String? ?? '🎵',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('their reply:',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text(widget.data['replySong'] as String? ?? '',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(widget.data['replyArtist'] as String? ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 11)),
            ])),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Send Tab — pick a friend + song + emoji
// ─────────────────────────────────────────────────────────────────────────────

class _SendTab extends StatefulWidget {
  final String uid;
  final OrbitState state;
  final VoidCallback onSent;
  const _SendTab({required this.uid, required this.state, required this.onSent});

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _songCtrl = TextEditingController();
  List<Map<String, dynamic>> _songResults = [];
  Map<String, dynamic>? _pickedSong;
  bool _searching = false;
  bool _sending = false;
  String _selectedEmoji = '🎵';
  Map<String, dynamic>? _pickedFriend;
  List<Map<String, dynamic>> _friends = [];

  static const _emojis = ['🎵', '💔', '🔥', '🫀', '😭', '✨', '👀', '🌙', '💀', '🖤'];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() { _songCtrl.dispose(); super.dispose(); }

  Future<void> _loadFriends() async {
    if (widget.uid.isEmpty) return;
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
  }

  Future<void> _searchSong(String q) async {
    if (q.isEmpty) { setState(() => _songResults = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _songResults = res; _searching = false; });
  }

  Future<void> _send() async {
    final s = _pickedSong;
    final f = _pickedFriend;
    if (s == null || f == null) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('song_secrets').add({
      'fromUid': widget.uid,
      'fromName': widget.state.displayName,
      'toUid': f['uid'],
      'song': s['song'],
      'artist': s['artist'],
      'artUrl': s['artUrl'],
      'emoji': _selectedEmoji,
      'fromRevealed': false,
      'toRevealed': false,
      'createdAt': Timestamp.now(),
    });
    HapticFeedback.mediumImpact();
    setState(() { _sending = false; _pickedSong = null; _pickedFriend = null; });
    _songCtrl.clear();
    widget.onSent();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('they\'ll see: "🤫 mystery orbiter sent you a song"',
            style: TextStyle(color: Colors.white.withOpacity(0.45),
                fontSize: 12),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),

        // Friend picker
        Text('who are you sending to?',
            style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        if (_friends.isEmpty)
          Text('follow some people first!',
              style: TextStyle(color: Colors.white.withOpacity(0.3),
                  fontSize: 13))
        else
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _friends.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final f = _friends[i];
                final selected = _pickedFriend?['uid'] == f['uid'];
                return GestureDetector(
                  onTap: () => setState(() => _pickedFriend = f),
                  child: Column(children: [
                    Container(
                      width: 48, height: 48,
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
                            ? Text(
                                (f['name'] as String)[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AuraTheme.accent,
                                    fontWeight: FontWeight.w900))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 48,
                      child: Text(
                        (f['name'] as String).split(' ').first,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),

        const SizedBox(height: 20),

        // Emoji picker
        Text('pick your emoji',
            style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _emojis.map((e) => GestureDetector(
            onTap: () => setState(() => _selectedEmoji = e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _selectedEmoji == e
                    ? AuraTheme.accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _selectedEmoji == e
                        ? AuraTheme.accent
                        : Colors.transparent,
                    width: 1.5),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
            ),
          )).toList(),
        ),

        const SizedBox(height: 20),

        // Song picker
        Text('pick a song',
            style: TextStyle(color: Colors.white.withOpacity(0.5),
                fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          controller: _songCtrl,
          onChanged: _searchSong,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'search...',
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
        if (_pickedSong != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(_selectedEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '${_pickedSong!['song']} — ${_pickedSong!['artist']}',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600),
              )),
            ]),
          ),
        ] else if (_songResults.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...(_songResults.take(5).map((t) => ListTile(
            dense: true,
            title: Text(t['song'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(t['artist'] as String,
                style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 11)),
            onTap: () => setState(() {
              _pickedSong = t;
              _songResults = [];
              _songCtrl.text = t['song'] as String;
            }),
          ))),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_pickedSong != null && _pickedFriend != null && !_sending)
                ? _send : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              disabledBackgroundColor: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _sending
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('send secretly $_selectedEmoji',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listening Without You widget — shows in home feed
// Call this from the home feed when two friends shared a song on the same day
// ─────────────────────────────────────────────────────────────────────────────

class ListeningWithoutYouWidget extends StatelessWidget {
  final String friendName;
  final String song;
  final String artist;

  const ListeningWithoutYouWidget({
    super.key,
    required this.friendName,
    required this.song,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(children: [
        Text('👂', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white.withOpacity(0.55),
                fontSize: 12, height: 1.5),
            children: [
              TextSpan(text: 'you and '),
              TextSpan(text: friendName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              TextSpan(text: ' both heard '),
              TextSpan(text: '"$song"',
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.white)),
              TextSpan(text: ' today'),
            ],
          ),
        )),
      ]),
    );
  }
}
