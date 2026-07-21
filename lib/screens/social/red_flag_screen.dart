import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Red Flag / Green Flag — post a song, your orbit swipes it
// "If your fav song is X you're definitely a red flag" — very Gen Z
// ─────────────────────────────────────────────────────────────────────────────

class RedFlagScreen extends StatefulWidget {
  const RedFlagScreen({super.key});
  @override
  State<RedFlagScreen> createState() => _RedFlagScreenState();
}

class _RedFlagScreenState extends State<RedFlagScreen>
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
        title: const Text('🚩 red flag / green flag 🟢',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'orbit feed'), Tab(text: 'post yours')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FeedTab(uid: _uid ?? ''),
          _PostTab(uid: _uid ?? '', state: _state, onPosted: () {
            _tabs.animateTo(0);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed — browse and vote
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final String uid;
  const _FeedTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('redflag_posts')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AuraTheme.accent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🚩', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('no posts yet',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 15)),
              const SizedBox(height: 4),
              Text('be the first to post a song',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 13)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _FlagCard(
              docId: docs[i].id,
              data: data,
              myUid: uid,
            );
          },
        );
      },
    );
  }
}

class _FlagCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  const _FlagCard({required this.docId, required this.data, required this.myUid});

  @override
  State<_FlagCard> createState() => _FlagCardState();
}

class _FlagCardState extends State<_FlagCard> {
  final _db = FirebaseFirestore.instance;

  Future<void> _vote(bool isRed) async {
    HapticFeedback.mediumImpact();
    final votes = Map<String, dynamic>.from(
        widget.data['votes'] as Map<String, dynamic>? ?? {});
    votes[widget.myUid] = isRed ? 'red' : 'green';
    await _db.collection('redflag_posts').doc(widget.docId)
        .update({'votes': votes});
  }

  @override
  Widget build(BuildContext context) {
    final votes = Map<String, dynamic>.from(
        widget.data['votes'] as Map<String, dynamic>? ?? {});
    final total = votes.length;
    final reds = votes.values.where((v) => v == 'red').length;
    final greens = total - reds;
    final myVote = votes[widget.myUid] as String?;
    final voted = myVote != null;

    double redPct = total == 0 ? 0.5 : reds / total;
    double greenPct = 1 - redPct;

    final poster = widget.data['posterName'] as String? ?? 'Orbiter';
    final song = widget.data['song'] as String? ?? '';
    final artist = widget.data['artist'] as String? ?? '';
    final artUrl = widget.data['artUrl'] as String?;
    final caption = widget.data['caption'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Song header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            if (artUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                    imageUrl: artUrl, width: 52, height: 52, fit: BoxFit.cover),
              )
            else
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: AuraTheme.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.music_note_rounded,
                    color: AuraTheme.accent, size: 24),
              ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(song,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Text(artist,
                  style: TextStyle(color: Colors.white.withOpacity(0.55),
                      fontSize: 12)),
              Text('posted by $poster',
                  style: TextStyle(color: Colors.white.withOpacity(0.35),
                      fontSize: 11)),
            ])),
          ]),
        ),

        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text('"$caption"',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                    fontSize: 13)),
          ),

        // Vote bar
        if (voted) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                Expanded(
                  flex: (redPct * 100).round(),
                  child: Container(
                    height: 8,
                    color: Colors.red.shade400,
                  ),
                ),
                Expanded(
                  flex: (greenPct * 100).round(),
                  child: Container(
                    height: 8,
                    color: Colors.green.shade400,
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Row(children: [
              Text('🚩 $reds  (${(redPct * 100).round()}%)',
                  style: TextStyle(
                      color: Colors.red.shade300, fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('🟢 $greens  (${(greenPct * 100).round()}%)',
                  style: TextStyle(
                      color: Colors.green.shade300, fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text('you voted: ${myVote == 'red' ? '🚩 red flag' : '🟢 green flag'}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ),
        ] else ...[
          // Swipe buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _vote(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.4), width: 1),
                    ),
                    child: const Center(
                      child: Text('🚩  red flag',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _vote(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.4), width: 1),
                    ),
                    child: const Center(
                      child: Text('🟢  green flag',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Tab — pick a song + optional caption
// ─────────────────────────────────────────────────────────────────────────────

class _PostTab extends StatefulWidget {
  final String uid;
  final OrbitState state;
  final VoidCallback onPosted;
  const _PostTab({required this.uid, required this.state, required this.onPosted});

  @override
  State<_PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<_PostTab> {
  final _searchCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _picked;
  bool _searching = false;
  bool _posting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _post() async {
    final s = _picked;
    if (s == null) return;
    setState(() => _posting = true);
    await FirebaseFirestore.instance.collection('redflag_posts').add({
      'uid': widget.uid,
      'posterName': widget.state.displayName,
      'song': s['song'],
      'artist': s['artist'],
      'artUrl': s['artUrl'],
      'caption': _captionCtrl.text.trim(),
      'votes': <String, String>{},
      'createdAt': Timestamp.now(),
    });
    HapticFeedback.mediumImpact();
    setState(() { _posting = false; _picked = null; _results = []; });
    _searchCtrl.clear();
    _captionCtrl.clear();
    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('pick a song that reveals your personality',
            style: TextStyle(color: Colors.white.withOpacity(0.55),
                fontSize: 13)),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          onChanged: _search,
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
        // Picked song preview
        if (_picked != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AuraTheme.accent.withOpacity(0.4)),
            ),
            child: Row(children: [
              if (_picked!['artUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                      imageUrl: _picked!['artUrl'] as String,
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_picked!['song'] as String,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
                Text(_picked!['artist'] as String,
                    style: TextStyle(color: Colors.white.withOpacity(0.5),
                        fontSize: 12)),
              ])),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => setState(() => _picked = null),
              ),
            ]),
          ),
        ],
        // Search results
        if (_results.isNotEmpty && _picked == null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.take(5).length,
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
                  onTap: () => setState(() {
                    _picked = t;
                    _results = [];
                    _searchCtrl.text = t['song'] as String;
                  }),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _captionCtrl,
          maxLength: 80,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'add a caption... (optional)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_picked != null && !_posting) ? _post : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              disabledBackgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _posting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('post it 🚩',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}
