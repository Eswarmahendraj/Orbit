import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../models/collab_playlist_model.dart';
import '../../services/collab_playlist_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Discovery / My Playlists Screen
// ─────────────────────────────────────────────────────────────────────────────
class CollabPlaylistScreen extends StatelessWidget {
  const CollabPlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OrbitState>(context);

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: Text(
          'Collab Playlists',
          style: TextStyle(
              color: AuraTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AuraTheme.accent, size: 28),
            onPressed: () =>
                _showCreateSheet(context, state),
          ),
        ],
      ),
      body: StreamBuilder<List<CollabPlaylist>>(
        stream: CollabPlaylistService().myPlaylistsStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AuraTheme.accent));
          }

          final playlists = snap.data ?? [];

          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎵', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'No collab playlists yet',
                    style: TextStyle(
                        color: AuraTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start building one with friends',
                    style:
                        TextStyle(color: AuraTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (_, i) => _PlaylistCard(
              playlist: playlists[i],
              myUid: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(
      BuildContext context, OrbitState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreatePlaylistSheet(state: state),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist Card
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistCard extends StatelessWidget {
  final CollabPlaylist playlist;
  final String myUid;

  const _PlaylistCard({
    required this.playlist,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = playlist.ownerUid == myUid;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollabPlaylistActiveScreen(
            playlistId: playlist.id,
            myUid: myUid,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1E30)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AuraTheme.accent, AuraTheme.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.queue_music_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                        color: AuraTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount} tracks · ${playlist.memberUids.length} members',
                    style:
                        TextStyle(color: AuraTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOwner ? 'You created this' : 'by ${playlist.ownerName}',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AuraTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Playlist Screen
// ─────────────────────────────────────────────────────────────────────────────
class CollabPlaylistActiveScreen extends StatelessWidget {
  final String playlistId;
  final String myUid;

  const CollabPlaylistActiveScreen({
    super.key,
    required this.playlistId,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<OrbitState>(context);

    return StreamBuilder<CollabPlaylist?>(
      stream: CollabPlaylistService().playlistStream(playlistId),
      builder: (context, snap) {
        final playlist = snap.data;

        return Scaffold(
          backgroundColor: AuraTheme.background,
          appBar: AppBar(
            backgroundColor: AuraTheme.background,
            elevation: 0,
            title: Text(
              playlist?.name ?? 'Collab Playlist',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            actions: [
              if (playlist != null)
                IconButton(
                  icon: Icon(Icons.add_rounded, color: AuraTheme.accent, size: 28),
                  onPressed: () => _showAddTrackSheet(
                      context, state, playlist),
                ),
            ],
          ),
          body: playlist == null
              ? Center(
                  child: CircularProgressIndicator(color: AuraTheme.accent))
              : playlist.tracks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎵',
                              style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No tracks yet',
                            style: TextStyle(
                                color: AuraTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to add the first song!',
                            style: TextStyle(
                                color: AuraTheme.textSecondary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _buildTrackList(context, state, playlist),
        );
      },
    );
  }

  Widget _buildTrackList(BuildContext context, OrbitState state, CollabPlaylist playlist) {
    // Sort by votes descending
    final sorted = List<CollabTrack>.from(playlist.tracks)
      ..sort((a, b) => b.votes.compareTo(a.votes));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: sorted.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Icon(Icons.people_rounded,
                    color: AuraTheme.textMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${playlist.memberUids.length} members · sorted by votes',
                  style:
                      TextStyle(color: AuraTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }
        final track = sorted[i - 1];
        return _TrackTile(
          track: track,
          myUid: myUid,
          isOwner: playlist.ownerUid == myUid,
          rank: i,
          onVote: () => CollabPlaylistService().voteTrack(
            playlistId: playlistId,
            trackId: track.id,
            uid: myUid,
            currentTracks: playlist.tracks,
          ),
          onRemove: () => CollabPlaylistService().removeTrack(
            playlistId: playlistId,
            trackId: track.id,
            currentTracks: playlist.tracks,
          ),
        );
      },
    );
  }

  void _showAddTrackSheet(BuildContext context, OrbitState state, CollabPlaylist playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddTrackSheet(
        state: state,
        playlistId: playlistId,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track Tile
// ─────────────────────────────────────────────────────────────────────────────
class _TrackTile extends StatelessWidget {
  final CollabTrack track;
  final String myUid;
  final bool isOwner;
  final int rank;
  final VoidCallback onVote;
  final VoidCallback onRemove;

  const _TrackTile({
    required this.track,
    required this.myUid,
    required this.isOwner,
    required this.rank,
    required this.onVote,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasVoted = track.hasVoted(myUid);
    final voteColor = hasVoted ? AuraTheme.accent : AuraTheme.textMuted;
    final isMyTrack = track.addedByUid == myUid;
    final canRemove = isOwner || isMyTrack;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              hasVoted ? AuraTheme.accent.withOpacity(0.3) : const Color(0xFF1E1E30),
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                  color: rank == 1 ? AuraTheme.accent : AuraTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),

          // Album art
          if (track.artUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.artUrl!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _artPlaceholder(),
              ),
            )
          else
            _artPlaceholder(),

          const SizedBox(width: 12),

          // Title + artist + added by
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AuraTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artist,
                  style:
                      TextStyle(color: AuraTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  isMyTrack ? 'Added by you' : 'by ${track.addedByName}',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Vote button
          GestureDetector(
            onTap: onVote,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      hasVoted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(hasVoted),
                      color: voteColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${track.votes}',
                    style: TextStyle(
                        color: voteColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  color: AuraTheme.textMuted, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _artPlaceholder() => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.music_note_rounded,
            color: AuraTheme.accent, size: 22),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Playlist Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePlaylistSheet extends StatefulWidget {
  final OrbitState state;

  const _CreatePlaylistSheet(
      {required this.state});

  @override
  State<_CreatePlaylistSheet> createState() =>
      _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<_CreatePlaylistSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final id = await CollabPlaylistService().createPlaylist(
        ownerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        ownerName: widget.state.displayName,
        name: _ctrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollabPlaylistActiveScreen(
              playlistId: id,
              myUid: FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: AuraTheme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E30),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'New Collab Playlist',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Friends can join and add songs together',
              style: TextStyle(color: AuraTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(color: AuraTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Playlist name...',
                hintStyle: TextStyle(color: AuraTheme.textMuted),
                filled: true,
                fillColor: AuraTheme.card,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Create Playlist',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Track Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddTrackSheet extends StatefulWidget {
  final OrbitState state;
  final String playlistId;

  const _AddTrackSheet({
    required this.state,
    required this.playlistId,
  });

  @override
  State<_AddTrackSheet> createState() => _AddTrackSheetState();
}

class _AddTrackSheetState extends State<_AddTrackSheet> {
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  bool _loading = false;
  bool _useNowPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.vibeSong.isNotEmpty) {
      _useNowPlaying = true;
      _titleCtrl.text = widget.state.vibeSong;
      _artistCtrl.text = widget.state.vibeArtist;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final trackId =
          '${(FirebaseAuth.instance.currentUser?.uid ?? '').substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

      final track = CollabTrack(
        id: trackId,
        title: _titleCtrl.text.trim(),
        artist: _artistCtrl.text.trim(),
        artUrl: _useNowPlaying ? widget.state.vibeArtUrl : null,
        addedByUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        addedByName: widget.state.displayName,
        votes: 0,
        votedByUids: [],
        addedAt: DateTime.now(),
      );

      await CollabPlaylistService().addTrack(
        playlistId: widget.playlistId,
        track: track,
      );

      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNowPlaying = widget.state.vibeSong.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: AuraTheme.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E30),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add a Track',
              style: TextStyle(
                  color: AuraTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Now Playing quick-add
            if (hasNowPlaying) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _useNowPlaying = !_useNowPlaying;
                    if (_useNowPlaying) {
                      _titleCtrl.text = widget.state.vibeSong;
                      _artistCtrl.text = widget.state.vibeArtist;
                    } else {
                      _titleCtrl.clear();
                      _artistCtrl.clear();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _useNowPlaying
                        ? AuraTheme.accent.withOpacity(0.12)
                        : AuraTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _useNowPlaying
                          ? AuraTheme.accent.withOpacity(0.4)
                          : const Color(0xFF1E1E30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: _useNowPlaying
                            ? AuraTheme.accent
                            : AuraTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Now Playing',
                              style: TextStyle(
                                  color: AuraTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.state.vibeSong,
                              style: TextStyle(
                                  color: AuraTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.state.vibeArtist,
                              style: TextStyle(
                                  color: AuraTheme.textSecondary,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _useNowPlaying
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: _useNowPlaying
                            ? AuraTheme.accent
                            : AuraTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Divider(color: const Color(0xFF1E1E30))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or type manually',
                    style:
                        TextStyle(color: AuraTheme.textMuted, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: const Color(0xFF1E1E30))),
              ]),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: AuraTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Song title',
                hintStyle: TextStyle(color: AuraTheme.textMuted),
                filled: true,
                fillColor: AuraTheme.card,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistCtrl,
              style: TextStyle(color: AuraTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Artist name',
                hintStyle: TextStyle(color: AuraTheme.textMuted),
                filled: true,
                fillColor: AuraTheme.card,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Add to Playlist',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
