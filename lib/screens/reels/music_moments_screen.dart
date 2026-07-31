import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/music_moment_model.dart';
import '../../theme/aura_theme.dart';
import 'capture_moment_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Music Moments Screen — echo chain for a song
// Shows all 10s clips / photos posted to a specific track
// ─────────────────────────────────────────────────────────────────────────────

// Seed data shown when Firestore has no moments yet
final _seedMoments = [
  MusicMoment(
    id: 'seed_1', uid: 'u1',
    username: '@zara.k', displayName: 'Zara K', avatarEmoji: '🌙',
    song: '', artist: '', songKey: '',
    mood: 'melancholy', moodEmoji: '🌙',
    caption: 'this song lives in my chest fr',
    fires: 214, isPhoto: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  MusicMoment(
    id: 'seed_2', uid: 'u2',
    username: '@jay.rk', displayName: 'Jay R', avatarEmoji: '🎧',
    song: '', artist: '', songKey: '',
    mood: 'peaceful', moodEmoji: '💚',
    caption: 'driving at 2am with this on repeat',
    fires: 87, isPhoto: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  MusicMoment(
    id: 'seed_3', uid: 'u3',
    username: '@maya.w', displayName: 'Maya W', avatarEmoji: '✨',
    song: '', artist: '', songKey: '',
    mood: 'hype', moodEmoji: '🔥',
    caption: 'the way this hits in the club omg',
    fires: 63, isPhoto: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  MusicMoment(
    id: 'seed_4', uid: 'u4',
    username: '@alex.o', displayName: 'Alex O', avatarEmoji: '🎵',
    song: '', artist: '', songKey: '',
    mood: 'emotional', moodEmoji: '😭',
    caption: 'not me crying in the shower again',
    fires: 41, isPhoto: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
];

class MusicMomentsScreen extends StatefulWidget {
  final String song;
  final String artist;
  final String? previewUrl;
  final String? artUrl;

  const MusicMomentsScreen({
    super.key,
    required this.song,
    required this.artist,
    this.previewUrl,
    this.artUrl,
  });

  @override
  State<MusicMomentsScreen> createState() => _MusicMomentsScreenState();
}

class _MusicMomentsScreenState extends State<MusicMomentsScreen> {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  final Set<String> _fired = {};
  List<MusicMoment> _moments = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final key = MusicMoment.makeSongKey(widget.song, widget.artist);
    _sub = _db
        .collection('music_moments')
        .where('songKey', isEqualTo: key)
        .orderBy('fires', descending: true)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final loaded = snap.docs
          .map((d) => MusicMoment.fromFirestore(d))
          .toList();
      setState(() {
        _moments = loaded;
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggleFire(MusicMoment m) async {
    HapticFeedback.selectionClick();
    final alreadyFired = _fired.contains(m.id);
    setState(() {
      if (alreadyFired) _fired.remove(m.id);
      else _fired.add(m.id);
    });
    try {
      await _db.collection('music_moments').doc(m.id).update({
        'fires': FieldValue.increment(alreadyFired ? -1 : 1),
      });
    } catch (_) {
      // revert on error
      setState(() {
        if (alreadyFired) _fired.add(m.id);
        else _fired.remove(m.id);
      });
    }
  }

  Future<void> _openCapture() async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CaptureMomentScreen(
        song: widget.song,
        artist: widget.artist,
        previewUrl: widget.previewUrl,
        artUrl: widget.artUrl,
      )),
    );
    if (posted == true && mounted) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('moment posted ✨'),
            backgroundColor: AuraTheme.accent),
      );
    }
  }

  List<MusicMoment> get _displayMoments =>
      _moments.isEmpty ? _seedMoments : _moments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: SafeArea(child: Column(children: [

        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AuraTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('echo chain',
                    style: TextStyle(color: AuraTheme.textPrimary, fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(
                  '${widget.song} · ${widget.artist}',
                  style: const TextStyle(color: AuraTheme.textSecondary,
                      fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )),
            // Echo count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
              ),
              child: Text('${_displayMoments.length} echoes',
                  style: const TextStyle(color: AuraTheme.accent,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Song pill ───────────────────────────────────────────────────────
        _SongHeader(song: widget.song, artist: widget.artist,
            artUrl: widget.artUrl, previewUrl: widget.previewUrl),
        const SizedBox(height: 8),

        const Divider(color: Color(0xFF1E1E2E), height: 1),

        // ── Moments list ─────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AuraTheme.accent, strokeWidth: 2))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _displayMoments.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFF1A1A2E), height: 1),
                  itemBuilder: (_, i) {
                    final m = _displayMoments[i];
                    return _MomentTile(
                      moment: m,
                      isOriginal: i == 0,
                      fired: _fired.contains(m.id),
                      onFire: () => _toggleFire(m),
                    );
                  },
                ),
        ),

        // ── Add your echo CTA ────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: _openCapture,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AuraTheme.accent.withOpacity(0.15),
                    AuraTheme.accentLight.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.35)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.videocam_rounded, color: AuraTheme.accent,
                    size: 20),
                const SizedBox(width: 8),
                const Text('add your echo',
                    style: TextStyle(color: AuraTheme.accent,
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ])),
    );
  }
}

// ── Song header ───────────────────────────────────────────────────────────────

class _SongHeader extends StatelessWidget {
  final String song;
  final String artist;
  final String? artUrl;
  final String? previewUrl;
  const _SongHeader({required this.song, required this.artist,
      this.artUrl, this.previewUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: artUrl != null
              ? CachedNetworkImage(imageUrl: artUrl!,
                  width: 44, height: 44, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _artFallback())
              : _artFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song, style: const TextStyle(color: AuraTheme.textPrimary,
                fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(artist, style: const TextStyle(
                color: AuraTheme.textSecondary, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        const Icon(Icons.music_note_rounded, color: AuraTheme.accent, size: 18),
      ]),
    );
  }

  Widget _artFallback() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: AuraTheme.accent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note_rounded, color: AuraTheme.accent, size: 22),
  );
}

// ── Individual moment tile ────────────────────────────────────────────────────

class _MomentTile extends StatefulWidget {
  final MusicMoment moment;
  final bool isOriginal;
  final bool fired;
  final VoidCallback onFire;
  const _MomentTile({required this.moment, required this.isOriginal,
      required this.fired, required this.onFire});

  @override
  State<_MomentTile> createState() => _MomentTileState();
}

class _MomentTileState extends State<_MomentTile> {
  bool _expanded = false;
  VideoPlayerController? _vidCtrl;
  bool _vidLoading = false;

  @override
  void dispose() {
    _vidCtrl?.dispose();
    super.dispose();
  }

  Future<void> _toggleExpand() async {
    HapticFeedback.selectionClick();
    if (_expanded) {
      _vidCtrl?.pause();
      setState(() => _expanded = false);
      return;
    }
    setState(() => _expanded = true);
    final url = widget.moment.clipUrl;
    if (url != null && !widget.moment.isPhoto) {
      setState(() => _vidLoading = true);
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.play();
      if (mounted) setState(() { _vidCtrl = ctrl; _vidLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final timeAgo = _timeAgo(m.createdAt);

    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top row: avatar + name + time
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isOriginal
                      ? AuraTheme.accent
                      : Colors.white.withOpacity(0.08),
                  width: widget.isOriginal ? 1.5 : 1,
                ),
              ),
              child: Center(child: Text(m.avatarEmoji,
                  style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(m.displayName,
                      style: const TextStyle(color: AuraTheme.textPrimary,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (widget.isOriginal) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AuraTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('original',
                          style: TextStyle(color: AuraTheme.accent,
                              fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                Text('${m.username} · $timeAgo',
                    style: const TextStyle(color: AuraTheme.textSecondary,
                        fontSize: 11)),
              ],
            )),
            // Mood tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AuraTheme.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${m.moodEmoji} ${m.mood}',
                  style: const TextStyle(color: AuraTheme.textSecondary,
                      fontSize: 11)),
            ),
          ]),

          // Expanded media
          if (_expanded) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 9 / 14,
                child: m.clipUrl == null
                    ? Container(
                        color: AuraTheme.card,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m.avatarEmoji,
                                style: const TextStyle(fontSize: 48)),
                            const SizedBox(height: 8),
                            Text(m.mood,
                                style: const TextStyle(
                                    color: AuraTheme.textSecondary,
                                    fontSize: 16)),
                          ],
                        ),
                      )
                    : m.isPhoto
                        ? CachedNetworkImage(
                            imageUrl: m.clipUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AuraTheme.card),
                          )
                        : _vidLoading || _vidCtrl == null
                            ? Container(color: AuraTheme.card,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        color: AuraTheme.accent,
                                        strokeWidth: 2)))
                            : FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _vidCtrl!.value.size.width,
                                  height: _vidCtrl!.value.size.height,
                                  child: VideoPlayer(_vidCtrl!),
                                ),
                              ),
              ),
            ),
          ] else if (m.clipUrl != null) ...[
            // Collapsed thumbnail hint
            const SizedBox(height: 8),
            Row(children: [
              Container(
                width: 52, height: 52,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AuraTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Center(child: Icon(
                  m.isPhoto ? Icons.photo_rounded : Icons.play_circle_fill_rounded,
                  color: AuraTheme.accent, size: 24,
                )),
              ),
              if (m.caption.isNotEmpty)
                Expanded(child: Text(m.caption,
                    style: const TextStyle(color: AuraTheme.textSecondary,
                        fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ] else if (m.caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(m.caption, style: const TextStyle(color: AuraTheme.textPrimary,
                fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],

          // Fire button
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: widget.onFire,
              child: Row(children: [
                Icon(
                  widget.fired
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: widget.fired ? AuraTheme.accent : AuraTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${m.fires + (widget.fired ? 1 : 0)}',
                  style: TextStyle(
                    color: widget.fired
                        ? AuraTheme.accent
                        : AuraTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: widget.fired
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 16),
            Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AuraTheme.textSecondary, size: 18,
            ),
            const SizedBox(width: 4),
            Text(_expanded ? 'collapse' : 'view',
                style: const TextStyle(color: AuraTheme.textSecondary,
                    fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

