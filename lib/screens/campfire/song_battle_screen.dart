import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/song_battle_model.dart';
import '../../services/song_battle_service.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SongBattleScreen — full Firestore-backed battle hub
// ─────────────────────────────────────────────────────────────────────────────

class SongBattleScreen extends StatefulWidget {
  const SongBattleScreen({super.key});
  @override
  State<SongBattleScreen> createState() => _SongBattleScreenState();
}

class _SongBattleScreenState extends State<SongBattleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        title: const Text('⚔️ Song Battle',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context)),
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AuraTheme.accent,
          labelColor: AuraTheme.accent,
          unselectedLabelColor: AuraTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Live Battles'),
            Tab(text: 'My Battles'),
            Tab(text: 'Inbox'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _LiveBattlesTab(),
          _MyBattlesTab(),
          _InboxTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AuraTheme.accent,
        onPressed: () => _showStartBattleSheet(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Start Battle',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  void _showStartBattleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _StartBattleSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Live Battles (all active — anyone can vote)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveBattlesTab extends StatelessWidget {
  const _LiveBattlesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SongBattle>>(
      stream: SongBattleService.instance.activeBattlesStream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AuraTheme.accent));
        }
        final battles = (snap.data ?? [])
            .where((b) => !b.isExpired)
            .toList();
        if (battles.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🥊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('No live battles right now',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Start one and challenge a friend!',
                  style: TextStyle(
                      color: AuraTheme.textMuted, fontSize: 13)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: battles.length,
          itemBuilder: (_, i) => _BattleCard(battle: battles[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: My Battles
// ─────────────────────────────────────────────────────────────────────────────

class _MyBattlesTab extends StatelessWidget {
  const _MyBattlesTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Combine challenger + active-opponent streams
    return StreamBuilder<List<SongBattle>>(
      stream: SongBattleService.instance.myBattlesStream(),
      builder: (_, snapA) {
        return StreamBuilder<List<SongBattle>>(
          stream: SongBattleService.instance.myBattlesAsOpponentStream(),
          builder: (_, snapB) {
            final all = <String, SongBattle>{};
            for (final b in (snapA.data ?? [])) all[b.id] = b;
            for (final b in (snapB.data ?? [])) all[b.id] = b;
            final battles = all.values.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (battles.isEmpty &&
                snapA.connectionState != ConnectionState.waiting) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🎵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('No battles yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Challenge a friend to settle the score!',
                      style: TextStyle(
                          color: AuraTheme.textMuted, fontSize: 13)),
                ]),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: battles.length,
              itemBuilder: (_, i) =>
                  _MyBattleCard(battle: battles[i], myUid: uid),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Inbox (pending invites for me)
// ─────────────────────────────────────────────────────────────────────────────

class _InboxTab extends StatelessWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SongBattle>>(
      stream: SongBattleService.instance.pendingInvitesStream(),
      builder: (_, snap) {
        final invites = snap.data ?? [];
        if (invites.isEmpty && snap.connectionState != ConnectionState.waiting) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('No pending challenges',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text('When someone invites you, it shows up here',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invites.length,
          itemBuilder: (_, i) => _InviteCard(battle: invites[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BattleCard — live battle with real-time votes, 1 vote/account, countdown
// ─────────────────────────────────────────────────────────────────────────────

class _BattleCard extends StatefulWidget {
  final SongBattle battle;
  const _BattleCard({required this.battle});
  @override
  State<_BattleCard> createState() => _BattleCardState();
}

class _BattleCardState extends State<_BattleCard> {
  bool? _myVotedSide; // true = challenger, false = opponent
  bool _loadingVote = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.battle.expiresAt.difference(DateTime.now());
    _startTimer();
    _loadMyVote();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final rem = widget.battle.expiresAt.difference(DateTime.now());
      setState(() => _remaining = rem.isNegative ? Duration.zero : rem);
    });
  }

  Future<void> _loadMyVote() async {
    final v = await SongBattleService.instance.myVote(widget.battle.id);
    if (mounted) setState(() => _myVotedSide = v);
  }

  Future<void> _vote(bool forChallenger) async {
    if (_myVotedSide != null || _loadingVote) return;
    setState(() => _loadingVote = true);
    await SongBattleService.instance.vote(
      battleId: widget.battle.id,
      forChallenger: forChallenger,
    );
    if (mounted) setState(() { _myVotedSide = forChallenger; _loadingVote = false; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _fmtTime(Duration d) {
    if (d.inSeconds <= 0) return 'Ended';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.battle;
    final total = b.totalVotes;
    final pC = total == 0 ? 0.5 : b.votesChallenger / total;
    final voted = _myVotedSide != null;
    final ended = _remaining.inSeconds <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuraTheme.surface),
      ),
      child: Column(children: [
        // Header row
        Row(children: [
          _Avatar(url: b.challengerPhoto, name: b.challengerName),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${b.challengerName} vs ${b.opponentName}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                Icon(ended ? Icons.timer_off_rounded : Icons.timer_outlined,
                    size: 11, color: ended ? Colors.redAccent : AuraTheme.textMuted),
                const SizedBox(width: 3),
                Text(ended ? 'Battle ended' : 'ends in ${_fmtTime(_remaining)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: ended ? Colors.redAccent : AuraTheme.textMuted)),
              ]),
            ]),
          ),
          _Avatar(url: b.opponentPhoto, name: b.opponentName),
        ]),
        const SizedBox(height: 14),

        // Song cards
        Row(children: [
          Expanded(child: _SongVoteCard(
            song: b.challengerSong,
            picked: _myVotedSide == true,
            winning: voted && b.votesChallenger > b.votesOpponent,
            onTap: (!voted && !ended && !_loadingVote) ? () => _vote(true) : null,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('VS',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18,
                    color: AuraTheme.textMuted.withOpacity(0.5))),
          ),
          Expanded(child: _SongVoteCard(
            song: b.opponentSong ?? BattleSong(title: 'Choosing...', artist: ''),
            picked: _myVotedSide == false,
            winning: voted && b.votesOpponent > b.votesChallenger,
            onTap: (b.opponentSong != null && !voted && !ended && !_loadingVote)
                ? () => _vote(false)
                : null,
          )),
        ]),

        // Vote bar
        if (voted || ended) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 30,
              child: Stack(children: [
                Container(color: AuraTheme.surface),
                AnimatedFractionallySizedBox(
                  widthFactor: pC,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  child: Container(
                      color: AuraTheme.accent),
                ),
                Row(children: [
                  Expanded(child: Center(
                    child: Text('${(pC * 100).round()}%  ${b.challengerName.split(' ').first}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  )),
                  Expanded(child: Center(
                    child: Text('${b.opponentName.split(' ').first}  ${((1 - pC) * 100).round()}%',
                        style: TextStyle(
                            color: pC < 0.5 ? Colors.white : AuraTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  )),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text('$total vote${total == 1 ? '' : 's'} · one per account',
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
          if (ended) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                b.votesChallenger > b.votesOpponent
                    ? '🏆 ${b.challengerSong.title} wins!'
                    : b.votesOpponent > b.votesChallenger
                        ? '🏆 ${b.opponentSong?.title ?? 'Opponent'} wins!'
                        : '🤝 It\'s a tie!',
                style: const TextStyle(
                    color: AuraTheme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            ),
          ],
        ],
        if (!voted && !ended)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('tap a song to vote · one vote per account',
                style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MyBattleCard — my battles with update-song option + edit request banner
// ─────────────────────────────────────────────────────────────────────────────

class _MyBattleCard extends StatelessWidget {
  final SongBattle battle;
  final String myUid;
  const _MyBattleCard({required this.battle, required this.myUid});

  bool get _amChallenger => battle.challengerId == myUid;

  BattleSong get _mySong =>
      _amChallenger ? battle.challengerSong : (battle.opponentSong ?? BattleSong(title: '?', artist: ''));

  String get _opponentName =>
      _amChallenger ? battle.opponentName : battle.challengerName;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final isPending = b.status == BattleStatus.pending;
    final hasEditReq = b.editRequest != null;
    final editForMe = hasEditReq && b.editRequest!.requestedBy != myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: editForMe
              ? Colors.orange.withOpacity(0.4)
              : AuraTheme.surface,
        ),
      ),
      child: Column(children: [
        // Edit request banner
        if (editForMe)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              const Text('✏️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_opponentName wants to change their song to "${b.editRequest!.newSong.title}"',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => SongBattleService.instance.acceptEditRequest(b.id),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              TextButton(
                onPressed: () => SongBattleService.instance.rejectEditRequest(b.id),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Status + opponent row
            Row(children: [
              _statusChip(b.status, b.isExpired),
              const Spacer(),
              Text('vs $_opponentName',
                  style: TextStyle(
                      color: AuraTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),

            // My song card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AuraTheme.accent.withOpacity(0.2)),
              ),
              child: Row(children: [
                _ArtThumbnail(url: _mySong.artUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_mySong.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_mySong.artist,
                      style: TextStyle(
                          color: AuraTheme.textMuted, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('my song',
                      style: TextStyle(
                          color: AuraTheme.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ])),
                // Update song button (only before battle is active, or always if pending)
                if (!b.isExpired)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: AuraTheme.accent),
                    tooltip: 'Change my song',
                    onPressed: () => _showSongEditSheet(context),
                  ),
              ]),
            ),

            // Pending state hint
            if (isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Waiting for $_opponentName to accept and pick their song',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.amber),
                      maxLines: 2),
                ]),
              ),
            ],

            // Vote tally (if active)
            if (b.status == BattleStatus.active) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${b.votesChallenger} votes for ${b.challengerName.split(' ').first}',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
                Text('${b.votesOpponent} for ${b.opponentName.split(' ').first}',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _statusChip(BattleStatus status, bool expired) {
    Color color;
    String label;
    if (expired) { color = Colors.grey; label = 'Ended'; }
    else switch (status) {
      case BattleStatus.pending: color = Colors.amber; label = '⏳ Pending'; break;
      case BattleStatus.active: color = Colors.green; label = '🔥 Live'; break;
      case BattleStatus.completed: color = Colors.grey; label = 'Done'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _showSongEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SongPickerSheet(
        title: 'Change Your Song',
        subtitle: 'Your opponent must approve the change',
        onPick: (song) async {
          await SongBattleService.instance.requestSongEdit(
            battleId: battle.id,
            newSong: song,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InviteCard — pending invite: accept (pick song) or decline
// ─────────────────────────────────────────────────────────────────────────────

class _InviteCard extends StatelessWidget {
  final SongBattle battle;
  const _InviteCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final b = battle;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AuraTheme.accent.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Avatar(url: b.challengerPhoto, name: b.challengerName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('⚔️ ${b.challengerName} challenged you!',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              Text('Pick your song and battle',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        // Challenger's song
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AuraTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            _ArtThumbnail(url: b.challengerSong.artUrl, size: 40),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.challengerSong.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(b.challengerSong.artist,
                  style: TextStyle(
                      color: AuraTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 2),
              Text('their song',
                  style: TextStyle(
                      color: AuraTheme.accent, fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ])),
          ]),
        ),
        const SizedBox(height: 14),

        // Accept / Decline
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => SongBattleService.instance.declineBattle(b.id),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AuraTheme.textMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Decline',
                  style: TextStyle(
                      color: AuraTheme.textMuted, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _showAcceptSheet(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Pick My Song & Accept',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showAcceptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SongPickerSheet(
        title: 'Pick Your Song',
        subtitle: 'Choose the song to battle ${battle.challengerName} with',
        onPick: (song) async {
          await SongBattleService.instance.acceptBattle(
            battleId: battle.id,
            mySong: song,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StartBattleSheet — pick friend → pick song → send invite
// ─────────────────────────────────────────────────────────────────────────────

class _StartBattleSheet extends StatefulWidget {
  const _StartBattleSheet();
  @override
  State<_StartBattleSheet> createState() => _StartBattleSheetState();
}

class _StartBattleSheetState extends State<_StartBattleSheet> {
  // Step 0 = pick opponent, Step 1 = pick song
  int _step = 0;
  Map<String, dynamic>? _selectedOpponent;
  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final list = await SongBattleService.instance.getFollowing();
    if (mounted) setState(() { _friends = list; _loadingFriends = false; });
  }

  Future<void> _sendBattle(BattleSong song) async {
    if (_selectedOpponent == null) return;
    setState(() => _sending = true);
    try {
      await SongBattleService.instance.createBattle(
        opponentId: _selectedOpponent!['uid'] as String,
        opponentName: _selectedOpponent!['name'] as String? ?? 'Friend',
        opponentPhoto: _selectedOpponent!['photoUrl'] as String?,
        mySong: song,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚔️ Battle sent to ${_selectedOpponent!['name']}! Valid for 24 hours.'),
            backgroundColor: AuraTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: _step == 0 ? _buildFriendPicker() : _buildSongStep(),
      ),
    );
  }

  Widget _buildFriendPicker() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Handle
      Center(
        child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AuraTheme.surface,
                borderRadius: BorderRadius.circular(2))),
      ),
      const SizedBox(height: 16),
      const Text('⚔️ Start a Battle',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      const SizedBox(height: 6),
      Text('Challenge a friend — battle is live for 24 hours',
          style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
      const SizedBox(height: 20),
      if (_loadingFriends)
        const Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AuraTheme.accent),
        )
      else if (_friends.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Follow some people first to challenge them!',
              style: TextStyle(color: AuraTheme.textMuted),
              textAlign: TextAlign.center),
        )
      else
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _friends.length,
            itemBuilder: (_, i) {
              final f = _friends[i];
              final selected = _selectedOpponent?['uid'] == f['uid'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: _Avatar(
                    url: f['photoUrl'] as String?,
                    name: f['name'] as String? ?? '?',
                    size: 40),
                title: Text(f['name'] as String? ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? AuraTheme.accent : null)),
                subtitle: f['auraName'] != null && (f['auraName'] as String).isNotEmpty
                    ? Text('@${f['auraName']}',
                        style: TextStyle(
                            color: AuraTheme.textMuted, fontSize: 11))
                    : null,
                trailing: selected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AuraTheme.accent)
                    : null,
                onTap: () => setState(() => _selectedOpponent = f),
              );
            },
          ),
        ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedOpponent == null
              ? null
              : () => setState(() => _step = 1),
          style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AuraTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: Text(
              _selectedOpponent == null
                  ? 'Select a friend first'
                  : 'Next — Pick your song →',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ),
    ]);
  }

  Widget _buildSongStep() {
    return _SongPickerSheet(
      title: 'Your Battle Song',
      subtitle: 'vs ${_selectedOpponent!['name']} · battle valid for 24 hrs',
      sending: _sending,
      onPick: _sendBattle,
      onBack: () => setState(() => _step = 0),
      inlineMode: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SongPickerSheet — Spotify search + pick
// ─────────────────────────────────────────────────────────────────────────────

class _SongPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(BattleSong) onPick;
  final VoidCallback? onBack;
  final bool inlineMode;
  final bool sending;

  const _SongPickerSheet({
    required this.title,
    required this.subtitle,
    required this.onPick,
    this.onBack,
    this.inlineMode = false,
    this.sending = false,
  });
  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _picking = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    try {
      final hits = await SpotifyService().search(q);
      if (mounted) setState(() { _results = hits; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pick(Map<String, dynamic> r) async {
    setState(() => _picking = true);
    final song = BattleSong(
      title: r['title'] as String? ?? '',
      artist: r['artist'] as String? ?? '',
      artUrl: r['artUrl'] as String?,
      previewUrl: r['previewUrl'] as String?,
    );
    await widget.onPick(song);
    if (mounted && !widget.inlineMode) Navigator.pop(context);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (!widget.inlineMode) ...[
        Center(
          child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 16),
      ],

      if (widget.onBack != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                size: 16, color: AuraTheme.accent),
            label: const Text('Back',
                style: TextStyle(color: AuraTheme.accent, fontSize: 13)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ),

      Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      const SizedBox(height: 4),
      Text(widget.subtitle,
          style: TextStyle(color: AuraTheme.textMuted, fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),

      TextField(
        controller: _ctrl,
        autofocus: true,
        onChanged: (v) => _search(v),
        decoration: InputDecoration(
          hintText: 'Search Spotify for a song...',
          prefixIcon: const Icon(Icons.search_rounded, color: AuraTheme.textMuted),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AuraTheme.accent)))
              : null,
          filled: true,
          fillColor: AuraTheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 12),

      ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.38),
        child: _results.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Search for a song to battle with',
                      style: TextStyle(color: AuraTheme.textMuted),
                      textAlign: TextAlign.center),
                ))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    leading: _ArtThumbnail(
                        url: r['artUrl'] as String?, size: 44),
                    title: Text(r['title'] as String? ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(r['artist'] as String? ?? '',
                        style: TextStyle(
                            color: AuraTheme.textMuted, fontSize: 11)),
                    trailing: _picking
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AuraTheme.accent))
                        : const Icon(Icons.add_circle_rounded,
                            color: AuraTheme.accent, size: 24),
                    onTap: _picking || widget.sending ? null : () => _pick(r),
                  );
                },
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SongVoteCard — song card inside live battle (tap to vote)
// ─────────────────────────────────────────────────────────────────────────────

class _SongVoteCard extends StatelessWidget {
  final BattleSong song;
  final bool picked;
  final bool winning;
  final VoidCallback? onTap;
  const _SongVoteCard({
    required this.song,
    required this.picked,
    required this.winning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: picked
              ? AuraTheme.accent
              : winning
                  ? AuraTheme.accent.withOpacity(0.08)
                  : AuraTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: picked
              ? null
              : winning
                  ? Border.all(color: AuraTheme.accent.withOpacity(0.3))
                  : Border.all(color: AuraTheme.card),
          boxShadow: picked
              ? [BoxShadow(
                  color: AuraTheme.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(children: [
          _ArtThumbnail(url: song.artUrl, size: 52, radius: 10),
          const SizedBox(height: 8),
          Text(song.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: picked ? Colors.white : null)),
          const SizedBox(height: 2),
          Text(song.artist,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  color: picked
                      ? Colors.white.withOpacity(0.75)
                      : AuraTheme.textMuted)),
          if (winning) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: picked
                      ? Colors.white.withOpacity(0.25)
                      : AuraTheme.accent,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('leading 🔥',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
          if (onTap == null && !picked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('voted ✓',
                  style: TextStyle(
                      fontSize: 9,
                      color: AuraTheme.textMuted)),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraTheme.accent.withOpacity(0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _initials())
          : _initials(),
    );
  }

  Widget _initials() => Center(
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: AuraTheme.accent,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.4)));
}

class _ArtThumbnail extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  const _ArtThumbnail({this.url, required this.size, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size, height: size,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: AuraTheme.accent.withOpacity(0.12),
      child: const Center(
          child: Icon(Icons.music_note_rounded,
              color: AuraTheme.accent, size: 20)));
}
