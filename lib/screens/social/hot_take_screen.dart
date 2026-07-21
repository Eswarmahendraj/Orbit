import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Hot Take Feed — anonymous music hot takes
// "Kendrick peaked in 2015, fight me." Others vote agree/disagree.
// Top take of the day gets featured. Very Gen Z energy.
// ─────────────────────────────────────────────────────────────────────────────

class HotTakeScreen extends StatefulWidget {
  const HotTakeScreen({super.key});
  @override
  State<HotTakeScreen> createState() => _HotTakeScreenState();
}

class _HotTakeScreenState extends State<HotTakeScreen>
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
        title: const Text('hot takes 🔥',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'feed'), Tab(text: 'drop a take')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FeedTab(uid: _uid ?? ''),
          _PostTakeTab(uid: _uid ?? '', state: _state, onPosted: () {
            _tabs.animateTo(0);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  final String uid;
  const _FeedTab({required this.uid});

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hot_takes')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AuraTheme.accent));
        }
        final docs = snap.data?.docs ?? [];

        // Separate today's top take
        final today = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) return false;
          final dt = ts.toDate();
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          return key == _todayKey;
        }).toList();

        DocumentSnapshot? topTake;
        if (today.isNotEmpty) {
          topTake = today.reduce((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aScore = (aData['agrees'] as List? ?? []).length -
                (aData['disagrees'] as List? ?? []).length;
            final bScore = (bData['agrees'] as List? ?? []).length -
                (bData['disagrees'] as List? ?? []).length;
            return aScore >= bScore ? a : b;
          });
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('no hot takes yet',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 15)),
              const SizedBox(height: 4),
              Text('be brave. drop the first one.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 13)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + (topTake != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (topTake != null && i == 0) {
              return _FeaturedTake(
                  docId: topTake.id,
                  data: topTake.data() as Map<String, dynamic>,
                  myUid: uid);
            }
            final idx = topTake != null ? i - 1 : i;
            if (idx >= docs.length) return const SizedBox.shrink();
            final d = docs[idx];
            if (topTake != null && d.id == topTake.id) {
              return const SizedBox.shrink();
            }
            return _TakeCard(
                docId: d.id,
                data: d.data() as Map<String, dynamic>,
                myUid: uid);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Take (top of the day)
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedTake extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  const _FeaturedTake(
      {required this.docId, required this.data, required this.myUid});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Text('⭐', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('take of the day',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.15),
                AuraTheme.card,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1.5),
        ),
        child: _TakeCard(
            docId: docId, data: data, myUid: myUid, featured: true),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Take Card
// ─────────────────────────────────────────────────────────────────────────────

class _TakeCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String myUid;
  final bool featured;
  const _TakeCard({
    required this.docId,
    required this.data,
    required this.myUid,
    this.featured = false,
  });

  Future<void> _vote(bool agree) async {
    HapticFeedback.selectionClick();
    final agrees = List<String>.from(data['agrees'] ?? []);
    final disagrees = List<String>.from(data['disagrees'] ?? []);
    agrees.remove(myUid);
    disagrees.remove(myUid);
    if (agree) agrees.add(myUid); else disagrees.add(myUid);
    await FirebaseFirestore.instance
        .collection('hot_takes').doc(docId)
        .update({'agrees': agrees, 'disagrees': disagrees});
  }

  @override
  Widget build(BuildContext context) {
    final take = data['take'] as String? ?? '';
    final agrees = List<String>.from(data['agrees'] ?? []);
    final disagrees = List<String>.from(data['disagrees'] ?? []);
    final total = agrees.length + disagrees.length;
    final myAgreed = agrees.contains(myUid);
    final myDisagreed = disagrees.contains(myUid);
    final voted = myAgreed || myDisagreed;
    final agreePct = total == 0 ? 0.5 : agrees.length / total;

    final ts = data['createdAt'] as Timestamp?;
    String timeStr = '';
    if (ts != null) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inMinutes < 60) timeStr = '${diff.inMinutes}m ago';
      else if (diff.inHours < 24) timeStr = '${diff.inHours}h ago';
      else timeStr = '${diff.inDays}d ago';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: featured ? null : BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Take text
        Text('"$take"',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 10),
        Row(children: [
          Text('anonymous orbiter',
              style: TextStyle(color: Colors.white.withOpacity(0.3),
                  fontSize: 11)),
          const Spacer(),
          Text(timeStr,
              style: TextStyle(color: Colors.white.withOpacity(0.25),
                  fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        // Vote bar (shown after voting)
        if (voted) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(children: [
              Expanded(
                flex: (agreePct * 100).round(),
                child: Container(height: 6, color: Colors.green.shade400),
              ),
              Expanded(
                flex: ((1 - agreePct) * 100).round(),
                child: Container(height: 6, color: Colors.red.shade400),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('✅ ${agrees.length} agree',
                style: TextStyle(color: Colors.green.shade300, fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('❌ ${disagrees.length} disagree',
                style: TextStyle(color: Colors.red.shade300, fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
        ],
        // Vote buttons
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _vote(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: myAgreed
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: myAgreed
                          ? Colors.green.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(myAgreed ? '✅ agreed' : '✅ agree',
                      style: TextStyle(
                          color: myAgreed ? Colors.green : Colors.white60,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _vote(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: myDisagreed
                      ? Colors.red.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: myDisagreed
                          ? Colors.red.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(myDisagreed ? '❌ disagreed' : '❌ disagree',
                      style: TextStyle(
                          color: myDisagreed ? Colors.red : Colors.white60,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Tab
// ─────────────────────────────────────────────────────────────────────────────

class _PostTakeTab extends StatefulWidget {
  final String uid;
  final OrbitState state;
  final VoidCallback onPosted;
  const _PostTakeTab({required this.uid, required this.state, required this.onPosted});

  @override
  State<_PostTakeTab> createState() => _PostTakeTabState();
}

class _PostTakeTabState extends State<_PostTakeTab> {
  final _ctrl = TextEditingController();
  bool _posting = false;

  // Prompt starters to inspire
  static const _starters = [
    '"[artist] peaked with their first album and everyone knows it."',
    '"[song] is overrated and I\'m tired of pretending it\'s not."',
    '"if [genre] is your whole personality we can\'t be friends."',
    '"[artist] fans are the most delusional fanbase in music."',
    '"[song] is objectively a red flag song. no notes."',
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || text.length < 10) return;
    setState(() => _posting = true);
    await FirebaseFirestore.instance.collection('hot_takes').add({
      'take': text,
      'authorUid': widget.uid,
      'agrees': <String>[],
      'disagrees': <String>[],
      'createdAt': Timestamp.now(),
    });
    HapticFeedback.mediumImpact();
    _ctrl.clear();
    setState(() => _posting = false);
    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('your take is anonymous.',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 4),
        Text('say what you actually think about music.',
            style: TextStyle(color: Colors.white.withOpacity(0.45),
                fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          maxLength: 200,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: 'e.g. "Kendrick peaked with GKMC and I will die on this hill"',
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 13),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Starter prompts
        Text('need inspiration?',
            style: TextStyle(color: Colors.white.withOpacity(0.35),
                fontSize: 11)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _starters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(
                  () => _ctrl.text = _starters[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(_starters[i].substring(0, 22) + '...',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_ctrl.text.trim().length >= 10 && !_posting)
                ? _post : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              disabledBackgroundColor: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _posting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('drop the take 🔥',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('100% anonymous — your orbit can\'t see it\'s you',
              style: TextStyle(color: Colors.white.withOpacity(0.25),
                  fontSize: 11)),
        ),
      ]),
    );
  }
}
