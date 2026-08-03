import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Orbit Wrapped — Annual Year-in-Review
// ─────────────────────────────────────────────────────────────────────────────

class WrappedStats {
  final int totalMoments;
  final int totalTimestamps;
  final String topArtist;
  final String topGenre;
  final String personalityType;
  final String personalityEmoji;
  final int vibeMatchesMade;
  final int playlistsCreated;
  final int year;

  const WrappedStats({
    required this.totalMoments,
    required this.totalTimestamps,
    required this.topArtist,
    required this.topGenre,
    required this.personalityType,
    required this.personalityEmoji,
    required this.vibeMatchesMade,
    required this.playlistsCreated,
    required this.year,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Loader
// ─────────────────────────────────────────────────────────────────────────────

Future<WrappedStats> _loadWrappedStats(String uid) async {
  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final yearStart = DateTime(now.year, 1, 1);
  final yearStartTs = Timestamp.fromDate(yearStart);

  // Moments count
  final momentsSnap = await db
      .collection('music_moments')
      .where('uid', isEqualTo: uid)
      .where('createdAt', isGreaterThanOrEqualTo: yearStartTs)
      .get();

  // Timestamps count
  final tsSnap = await db
      .collection('song_timestamps')
      .where('uid', isEqualTo: uid)
      .where('savedAt', isGreaterThanOrEqualTo: yearStartTs)
      .get();

  // Personality
  final personalitySnap =
      await db.collection('music_personalities').doc(uid).get();
  final personalityTitle =
      personalitySnap.data()?['title'] as String? ?? 'Music Lover';
  final personalityEmoji =
      personalitySnap.data()?['emoji'] as String? ?? '🎵';

  // Vibe matches made (cached docs where this user is uid)
  final vibeSnap = await db
      .collection('vibe_matches')
      .where('uid1', isEqualTo: uid)
      .get();

  // Playlists created
  final playlistSnap = await db
      .collection('collab_playlists')
      .where('ownerUid', isEqualTo: uid)
      .where('createdAt', isGreaterThanOrEqualTo: yearStartTs)
      .get();

  // Top artist from timestamps (most frequent)
  final allTs = tsSnap.docs.map((d) => d.data());
  final artistCounts = <String, int>{};
  for (final d in allTs) {
    final a = d['artist'] as String? ?? '';
    if (a.isNotEmpty) artistCounts[a] = (artistCounts[a] ?? 0) + 1;
  }
  String topArtist = 'Your Artist';
  if (artistCounts.isNotEmpty) {
    final sorted = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topArtist = sorted.first.key;
  }

  return WrappedStats(
    totalMoments: momentsSnap.size,
    totalTimestamps: tsSnap.size,
    topArtist: topArtist,
    topGenre: 'Pop', // Could be enriched with genre data from Music DNA
    personalityType: personalityTitle,
    personalityEmoji: personalityEmoji,
    vibeMatchesMade: vibeSnap.size,
    playlistsCreated: playlistSnap.size,
    year: now.year,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OrbitWrappedScreen extends StatefulWidget {
  const OrbitWrappedScreen({super.key});

  @override
  State<OrbitWrappedScreen> createState() => _OrbitWrappedScreenState();
}

class _OrbitWrappedScreenState extends State<OrbitWrappedScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _entryAnim;
  WrappedStats? _stats;
  bool _loading = true;
  int _currentPage = 0;
  final _shareKey = GlobalKey();

  // Slide config
  static const int _totalSlides = 6;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entryAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = Provider.of<OrbitState>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final stats = await _loadWrappedStats(uid);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return Scaffold(
        backgroundColor: AuraTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AuraTheme.accent),
              const SizedBox(height: 16),
              Text(
                'Building your ${DateTime.now().year} Wrapped...',
                style: TextStyle(
                    color: AuraTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;
    final state = Provider.of<OrbitState>(context);

    final slides = [
      _IntroSlide(stats: stats, name: state.displayName),
      _TopArtistSlide(stats: stats),
      _PersonalitySlide(stats: stats),
      _MomentsSlide(stats: stats),
      _ConnectionsSlide(stats: stats),
      _ShareSlide(stats: stats, shareKey: _shareKey, name: state.displayName),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Slides
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _totalSlides,
            itemBuilder: (_, i) => slides[i],
          ),

          // Top bar (progress + close)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Progress dots
                  ...List.generate(_totalSlides, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: i == _currentPage ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap zones (left/right)
          Positioned.fill(
            top: 80,
            bottom: 80,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _prevPage,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextPage,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          // Bottom arrow hint
          if (_currentPage < _totalSlides - 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(Icons.keyboard_arrow_right_rounded,
                      color: Colors.white.withOpacity(0.5), size: 28),
                  Text(
                    'Tap right to continue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 1 — Intro
// ─────────────────────────────────────────────────────────────────────────────

class _IntroSlide extends StatelessWidget {
  final WrappedStats stats;
  final String name;
  const _IntroSlide({required this.stats, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'orbit',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.year} Wrapped',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Hey $name, here\'s your musical universe this year.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 2 — Top Artist
// ─────────────────────────────────────────────────────────────────────────────

class _TopArtistSlide extends StatelessWidget {
  final WrappedStats stats;
  const _TopArtistSlide({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your #1 artist this year',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                stats.topArtist,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('🎵', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats.totalTimestamps} moments bookmarked',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'across your listening sessions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 3 — Personality
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalitySlide extends StatelessWidget {
  final WrappedStats stats;
  const _PersonalitySlide({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stats.personalityEmoji,
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'Your music personality',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stats.personalityType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'This is who you are as a listener.\nOwn it. 🔮',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 4 — Moments & Activity
// ─────────────────────────────────────────────────────────────────────────────

class _MomentsSlide extends StatelessWidget {
  final WrappedStats stats;
  const _MomentsSlide({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2d1b69), Color(0xFF11998e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You were busy',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              _StatRow(
                  emoji: '🎤',
                  value: '${stats.totalMoments}',
                  label: 'Music Moments shared'),
              const SizedBox(height: 16),
              _StatRow(
                  emoji: '🔖',
                  value: '${stats.totalTimestamps}',
                  label: 'Song moments bookmarked'),
              const SizedBox(height: 16),
              _StatRow(
                  emoji: '🎵',
                  value: '${stats.playlistsCreated}',
                  label: 'Collab playlists started'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatRow(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 5 — Connections
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectionsSlide extends StatelessWidget {
  final WrappedStats stats;
  const _ConnectionsSlide({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFda4453), Color(0xFF89216b)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💞', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                'Music brings people together',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${stats.vibeMatchesMade}\nVibe Checks',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'You connected with ${stats.vibeMatchesMade} people '
                'over music this year. That\'s your orbit. 🌟',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 6 — Share Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShareSlide extends StatelessWidget {
  final WrappedStats stats;
  final GlobalKey shareKey;
  final String name;
  const _ShareSlide(
      {required this.stats, required this.shareKey, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shareable card
              RepaintBoundary(
                key: shareKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF302b63), Color(0xFF0f0c29)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌙',
                              style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            'orbit ${stats.year} wrapped',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ShareStat(
                          label: '#1 artist', value: stats.topArtist),
                      const SizedBox(height: 8),
                      _ShareStat(
                          label: 'personality',
                          value:
                              '${stats.personalityEmoji} ${stats.personalityType}'),
                      const SizedBox(height: 8),
                      _ShareStat(
                          label: 'moments',
                          value: '${stats.totalMoments} shared'),
                      const SizedBox(height: 8),
                      _ShareStat(
                          label: 'connections',
                          value: '${stats.vibeMatchesMade} vibe checks'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Share button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareCard(context),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text(
                    'Share My Wrapped',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF302b63),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareCard(BuildContext context) async {
    try {
      final boundary =
          shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      await boundary.toImage(pixelRatio: 3.0);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Text('🎉  '),
              Text('Wrapped card ready to share!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF302b63),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }
}

class _ShareStat extends StatelessWidget {
  final String label;
  final String value;
  const _ShareStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label  ',
          style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
