import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/aura_theme.dart';
import '../../models/song_battle_model.dart';
import '../../services/song_battle_service.dart';
import '../../services/spotify_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — show the "Start a Battle" flow
// ─────────────────────────────────────────────────────────────────────────────

void showStartBattleSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FriendPickerSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — show a battle invite (for opponent)
// ─────────────────────────────────────────────────────────────────────────────

void showBattleInviteSheet(BuildContext context, SongBattle battle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BattleInviteSheet(battle: battle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — show a live active battle
// ─────────────────────────────────────────────────────────────────────────────

void showActiveBattleSheet(BuildContext context, SongBattle battle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActiveBattleSheet(battleId: battle.id),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Friend Picker
// ─────────────────────────────────────────────────────────────────────────────

class _FriendPickerSheet extends StatefulWidget {
  const _FriendPickerSheet();

  @override
  State<_FriendPickerSheet> createState() => _FriendPickerSheetState();
}

class _FriendPickerSheetState extends State<_FriendPickerSheet> {
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final friends = await SongBattleService.instance.getFollowing();
    if (mounted) setState(() { _friends = friends; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _friends
      : _friends
          .where((f) =>
              (f['name'] as String).toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      child: Column(children: [
        _SheetHandle(),
        const SizedBox(height: 4),
        const Text('⚔️  Challenge a Friend',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('Pick a friend — you\'ll both choose your battle songs',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55)),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // Search bar
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search friends…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AuraTheme.accent),
          )
        else if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _friends.isEmpty
                  ? 'Follow some friends first to battle them!'
                  : 'No friends match "$_query"',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Colors.white.withOpacity(0.07), height: 1),
              itemBuilder: (_, i) {
                final f = _filtered[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: _Avatar(url: f['photoUrl'] as String?,
                      name: f['name'] as String),
                  title: Text(f['name'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Text(f['auraName'] as String? ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45), fontSize: 12)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AuraTheme.accent, AuraTheme.accentLight]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Battle',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _SongPickerSheet(
                        opponent: f,
                        isChallenger: true,
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Song Picker (shared by challenger + opponent)
// ─────────────────────────────────────────────────────────────────────────────

class _SongPickerSheet extends StatefulWidget {
  // For challenger: opponent map, no battleId
  // For opponent: battleId, no opponent
  // For edit request: battleId + isEditRequest
  final Map<String, dynamic>? opponent;
  final String? battleId;
  final bool isChallenger;
  final bool isEditRequest;

  const _SongPickerSheet({
    this.opponent,
    this.battleId,
    this.isChallenger = false,
    this.isEditRequest = false,
  });

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Map<String, dynamic>? _picked;
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final res = await SpotifyService().search(q);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  Future<void> _submit() async {
    final p = _picked;
    if (p == null) return;
    setState(() => _submitting = true);

    final song = BattleSong(
      title: p['song'] as String,
      artist: p['artist'] as String,
      artUrl: p['artUrl'] as String?,
      previewUrl: p['previewUrl'] as String?,
    );

    try {
      if (widget.isEditRequest && widget.battleId != null) {
        await SongBattleService.instance.requestSongEdit(
            battleId: widget.battleId!, newSong: song);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Edit request sent! Waiting for your opponent to accept ✉️'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      if (widget.isChallenger && widget.opponent != null) {
        final opp = widget.opponent!;
        await SongBattleService.instance.createBattle(
          opponentId: opp['uid'] as String,
          opponentName: opp['name'] as String,
          opponentPhoto: opp['photoUrl'] as String?,
          mySong: song,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Battle sent to ${opp['name']}! Waiting for them to pick their song 🥊'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      if (!widget.isChallenger && widget.battleId != null) {
        await SongBattleService.instance.acceptBattle(
            battleId: widget.battleId!, mySong: song);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Battle is ON! 🔥 Let the votes decide.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Something went wrong: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditRequest
        ? '✏️  Change Your Song'
        : widget.isChallenger
            ? '🎵  Pick Your Battle Song'
            : '🎶  Pick Your Song';
    final sub = widget.isEditRequest
        ? 'Your opponent will need to approve the change'
        : widget.isChallenger
            ? 'Choose the song you\'re going to war with'
            : 'Show \'em what you\'ve got!';

    return _SheetShell(
      child: Column(children: [
        _SheetHandle(),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(sub,
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.55))),
        const SizedBox(height: 16),
        // Picked song preview
        if (_picked != null) ...[
          _PickedSongCard(track: _picked!,
              onClear: () => setState(() => _picked = null)),
          const SizedBox(height: 12),
        ],
        // Search
        TextField(
          controller: _ctrl,
          onChanged: _search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search Spotify…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4)),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        if (_results.isNotEmpty)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final t = _results[i];
                final picked = _picked == t;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: t['artUrl'] != null
                        ? CachedNetworkImage(
                            imageUrl: t['artUrl'] as String,
                            width: 44, height: 44, fit: BoxFit.cover)
                        : Container(width: 44, height: 44,
                            color: AuraTheme.surface,
                            child: const Icon(Icons.music_note_rounded,
                                color: AuraTheme.accent, size: 20)),
                  ),
                  title: Text(t['song'] as String,
                      style: TextStyle(
                          color: picked ? AuraTheme.accent : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  subtitle: Text(t['artist'] as String,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  trailing: picked
                      ? const Icon(Icons.check_circle_rounded,
                          color: AuraTheme.accent)
                      : null,
                  onTap: () => setState(() => _picked = t),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _picked == null || _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraTheme.accent,
              disabledBackgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    widget.isEditRequest
                        ? 'Send Edit Request'
                        : widget.isChallenger
                            ? 'Send Battle Invite ⚔️'
                            : 'Lock In My Song 🔒',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Battle Invite Sheet (shown to opponent)
// ─────────────────────────────────────────────────────────────────────────────

class _BattleInviteSheet extends StatefulWidget {
  final SongBattle battle;
  const _BattleInviteSheet({required this.battle});

  @override
  State<_BattleInviteSheet> createState() => _BattleInviteSheetState();
}

class _BattleInviteSheetState extends State<_BattleInviteSheet> {
  bool _declining = false;

  Future<void> _decline() async {
    setState(() => _declining = true);
    await SongBattleService.instance.declineBattle(widget.battle.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Battle declined.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.battle;
    return _SheetShell(
      child: Column(children: [
        _SheetHandle(),
        const SizedBox(height: 8),
        const Text('⚔️  Battle Invite!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 20),
        // Challenger card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            _Avatar(url: b.challengerPhoto, name: b.challengerName),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b.challengerName,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text('challenged you to a song battle!',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 13)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        // Their song
        _SongTile(song: b.challengerSong, label: '${b.challengerName}\'s song'),
        const SizedBox(height: 6),
        Text('VS',
            style: TextStyle(color: Colors.white.withOpacity(0.35),
                fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AuraTheme.accent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.music_note_rounded,
                color: AuraTheme.accent, size: 28),
            const SizedBox(width: 12),
            Text('Your song — you pick!',
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _declining ? null : _decline,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _declining
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Decline',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SongPickerSheet(
                    battleId: b.id,
                    isChallenger: false,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AuraTheme.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Accept & Pick Song 🎵',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Battle Sheet (voting + edit request handling)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBattleSheet extends StatefulWidget {
  final String battleId;
  const _ActiveBattleSheet({required this.battleId});

  @override
  State<_ActiveBattleSheet> createState() => _ActiveBattleSheetState();
}

class _ActiveBattleSheetState extends State<_ActiveBattleSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  bool? _myVote; // true = challenger, false = opponent, null = not voted
  bool _loadingVote = false;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _loadMyVote();
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyVote() async {
    final v = await SongBattleService.instance.myVote(widget.battleId);
    if (mounted) setState(() => _myVote = v);
    _barCtrl.forward();
  }

  Future<void> _vote(bool forChallenger) async {
    if (_myVote != null) return;
    setState(() => _loadingVote = true);
    HapticFeedback.mediumImpact();
    await SongBattleService.instance.vote(
        battleId: widget.battleId, forChallenger: forChallenger);
    if (mounted) {
      setState(() { _myVote = forChallenger; _loadingVote = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SongBattle?>(
      stream: SongBattleService.instance.battleStream(widget.battleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return _SheetShell(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AuraTheme.accent),
              ),
            ),
          );
        }
        final b = snap.data!;
        if (b.status == BattleStatus.completed) {
          return _SheetShell(
            child: _CompletedBattleView(battle: b),
          );
        }
        return _SheetShell(
          child: Column(children: [
            _SheetHandle(),
            const SizedBox(height: 4),
            const Text('🥊  SONG BATTLE',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: AuraTheme.accent, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            if (b.isExpired)
              Text('Battle ended',
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 12))
            else
              Text(_timeLeft(b.expiresAt),
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 12)),
            const SizedBox(height: 20),
            // Edit request banner
            if (b.editRequest != null)
              _EditRequestBanner(battle: b),
            // VS layout
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _BattleSide(
                song: b.challengerSong,
                name: b.challengerName,
                photo: b.challengerPhoto,
                votes: b.votesChallenger,
                total: b.totalVotes,
                isMyVote: _myVote == true,
                onVote: _myVote == null && !_loadingVote
                    ? () => _vote(true) : null,
                label: 'Challenger',
              )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                child: Text('VS',
                    style: TextStyle(color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w900, fontSize: 22)),
              ),
              Expanded(child: _BattleSide(
                song: b.opponentSong ?? const BattleSong(title: '?', artist: '?'),
                name: b.opponentName,
                photo: b.opponentPhoto,
                votes: b.votesOpponent,
                total: b.totalVotes,
                isMyVote: _myVote == false,
                onVote: _myVote == null && !_loadingVote
                    ? () => _vote(false) : null,
                label: 'Opponent',
              )),
            ]),
            if (_myVote != null) ...[
              const SizedBox(height: 12),
              _VoteBar(
                  challengerPct: b.challengerPct,
                  challengerVotes: b.votesChallenger,
                  opponentVotes: b.votesOpponent),
            ] else ...[
              const SizedBox(height: 12),
              Text('Tap a song to vote!',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 13)),
            ],
            const SizedBox(height: 20),
            // Request edit button (only for participants)
            _EditRequestButton(battle: b),
          ]),
        );
      },
    );
  }

  String _timeLeft(DateTime expires) {
    final diff = expires.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m left';
    return '${diff.inMinutes}m left';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BattleSide extends StatelessWidget {
  final BattleSong song;
  final String name;
  final String? photo;
  final int votes, total;
  final bool isMyVote;
  final VoidCallback? onVote;
  final String label;

  const _BattleSide({
    required this.song, required this.name, this.photo,
    required this.votes, required this.total,
    required this.isMyVote, this.onVote, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : votes / total;
    return GestureDetector(
      onTap: onVote,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyVote
              ? AuraTheme.accent.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMyVote ? AuraTheme.accent : Colors.white.withOpacity(0.1),
            width: isMyVote ? 2 : 1,
          ),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          _Avatar(url: photo, name: name, radius: 24),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          if (song.artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                  imageUrl: song.artUrl!,
                  width: 60, height: 60, fit: BoxFit.cover),
            )
          else
            Container(width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: AuraTheme.accent, size: 28)),
          const SizedBox(height: 8),
          Text(song.title,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(song.artist,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          if (isMyVote)
            const Icon(Icons.how_to_vote_rounded,
                color: AuraTheme.accent, size: 18),
          if (total > 0)
            Text('${(pct * 100).round()}%',
                style: TextStyle(
                    color: isMyVote ? AuraTheme.accent : Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final double challengerPct;
  final int challengerVotes, opponentVotes;

  const _VoteBar({required this.challengerPct,
      required this.challengerVotes, required this.opponentVotes});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Container(height: 24, color: Colors.white.withOpacity(0.1)),
          FractionallySizedBox(
            widthFactor: challengerPct,
            child: Container(
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AuraTheme.accent, AuraTheme.accentLight]),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$challengerVotes votes',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        Text('${challengerVotes + opponentVotes} total',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        Text('$opponentVotes votes',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ]),
    ]);
  }
}

class _EditRequestBanner extends StatefulWidget {
  final SongBattle battle;
  const _EditRequestBanner({required this.battle});

  @override
  State<_EditRequestBanner> createState() => _EditRequestBannerState();
}

class _EditRequestBannerState extends State<_EditRequestBanner> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    await SongBattleService.instance.acceptEditRequest(widget.battle.id);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Song update accepted! ✅'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    await SongBattleService.instance.rejectEditRequest(widget.battle.id);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.battle.editRequest!;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Only show accept/reject if I'm the one who needs to respond (not the requester)
    final iAmTheResponder = req.requestedBy != myUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 6),
          const Text('Song Edit Requested',
              style: TextStyle(color: Colors.orange,
                  fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        Text('→ ${req.newSong.title} by ${req.newSong.artist}',
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        if (!iAmTheResponder)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Waiting for opponent to respond…',
                style: TextStyle(
                    color: Colors.orange.withOpacity(0.7), fontSize: 11)),
          ),
        if (!_loading && iAmTheResponder) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reject,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Reject',
                    style: TextStyle(color: Colors.orange,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Accept',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ] else
          const Center(child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
          )),
      ]),
    );
  }
}

class _EditRequestButton extends StatelessWidget {
  final SongBattle battle;
  const _EditRequestButton({required this.battle});

  @override
  Widget build(BuildContext context) {
    // Only show for participants, and only if no pending edit request
    if (battle.editRequest != null) return const SizedBox.shrink();
    if (battle.status != BattleStatus.active) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SongPickerSheet(
            battleId: battle.id,
            isEditRequest: true,
          ),
        );
      },
      icon: Icon(Icons.edit_rounded,
          color: Colors.white.withOpacity(0.45), size: 16),
      label: Text('Request song change',
          style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 13)),
    );
  }
}

class _CompletedBattleView extends StatelessWidget {
  final SongBattle battle;
  const _CompletedBattleView({required this.battle});

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final challengerWon = b.votesChallenger >= b.votesOpponent;
    return Column(children: [
      _SheetHandle(),
      const SizedBox(height: 12),
      const Text('🏆  Battle Complete!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
              color: Colors.white)),
      const SizedBox(height: 20),
      Text(
        challengerWon
            ? '${b.challengerName} wins!'
            : '${b.opponentName} wins!',
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: AuraTheme.accent),
      ),
      const SizedBox(height: 8),
      _SongTile(
        song: challengerWon ? b.challengerSong : (b.opponentSong ?? b.challengerSong),
        label: 'Winning Song',
      ),
      const SizedBox(height: 16),
      _VoteBar(
          challengerPct: b.challengerPct,
          challengerVotes: b.votesChallenger,
          opponentVotes: b.votesOpponent),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable atoms
// ─────────────────────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final Widget child;
  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const _Avatar({this.url, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    if (url != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(url!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AuraTheme.accent.withOpacity(0.3),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AuraTheme.accent, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final BattleSong song;
  final String label;
  const _SongTile({required this.song, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        if (song.artUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                imageUrl: song.artUrl!,
                width: 44, height: 44, fit: BoxFit.cover),
          )
        else
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.music_note_rounded,
                  color: AuraTheme.accent, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 10, fontWeight: FontWeight.w600)),
          Text(song.title,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 14)),
          Text(song.artist,
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _PickedSongCard extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback onClear;
  const _PickedSongCard({required this.track, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuraTheme.accent.withOpacity(0.5)),
      ),
      child: Row(children: [
        if (track['artUrl'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
                imageUrl: track['artUrl'] as String,
                width: 44, height: 44, fit: BoxFit.cover),
          )
        else
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.music_note_rounded,
                  color: AuraTheme.accent, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('✅  Selected',
              style: TextStyle(color: AuraTheme.accent,
                  fontSize: 10, fontWeight: FontWeight.w700)),
          Text(track['song'] as String,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 14)),
          Text(track['artist'] as String,
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 12)),
        ])),
        IconButton(
          icon: Icon(Icons.close_rounded,
              color: Colors.white.withOpacity(0.4)),
          onPressed: onClear,
        ),
      ]),
    );
  }
}
