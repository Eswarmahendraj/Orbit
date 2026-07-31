import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';
import '../../services/audio_player_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Music Personality Type — Model
// ─────────────────────────────────────────────────────────────────────────────

class MusicPersonality {
  final String uid;
  final String typeKey;       // e.g. 'midnight_explorer'
  final String title;         // e.g. 'Midnight Explorer'
  final String emoji;
  final String description;
  final String subheadline;
  final List<String> traits;
  final List<Color> gradient;
  final DateTime generatedAt;

  const MusicPersonality({
    required this.uid,
    required this.typeKey,
    required this.title,
    required this.emoji,
    required this.description,
    required this.subheadline,
    required this.traits,
    required this.gradient,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'typeKey': typeKey,
        'title': title,
        'emoji': emoji,
        'description': description,
        'subheadline': subheadline,
        'traits': traits,
        'gradientColors': gradient.map((c) => c.value).toList(),
        'generatedAt': Timestamp.fromDate(generatedAt),
      };

  factory MusicPersonality.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MusicPersonality(
      uid: d['uid'] ?? '',
      typeKey: d['typeKey'] ?? '',
      title: d['title'] ?? '',
      emoji: d['emoji'] ?? '🎵',
      description: d['description'] ?? '',
      subheadline: d['subheadline'] ?? '',
      traits: List<String>.from(d['traits'] ?? []),
      gradient: (d['gradientColors'] as List<dynamic>? ?? [])
          .map((v) => Color(v as int))
          .toList(),
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Personality Catalog (8 archetypes)
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalityTemplate {
  final String key;
  final String title;
  final String emoji;
  final String description;
  final String subheadline;
  final List<String> traits;
  final List<Color> gradient;

  const _PersonalityTemplate({
    required this.key,
    required this.title,
    required this.emoji,
    required this.description,
    required this.subheadline,
    required this.traits,
    required this.gradient,
  });
}

const List<_PersonalityTemplate> _kPersonalities = [
  _PersonalityTemplate(
    key: 'midnight_explorer',
    title: 'Midnight Explorer',
    emoji: '🌙',
    subheadline: 'You listen when the world sleeps',
    description:
        'Your best sessions start after midnight. You chase deep cuts, '
        'hidden B-sides, and artists nobody\'s heard of yet. '
        'You don\'t follow trends — you predict them.',
    traits: ['Night owl', 'Deep cuts hunter', 'Trend-setter', 'Solo listener'],
    gradient: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
  ),
  _PersonalityTemplate(
    key: 'vibe_architect',
    title: 'Vibe Architect',
    emoji: '🏗️',
    subheadline: 'You engineer the perfect playlist',
    description:
        'Every playlist you build is a carefully sequenced journey. '
        'BPM, key, mood, energy arc — you feel it all instinctively. '
        'People come to you for the aux cord.',
    traits: ['Playlist curator', 'Energy reader', 'Social DJ', 'Detail-oriented'],
    gradient: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  ),
  _PersonalityTemplate(
    key: 'genre_shapeshifter',
    title: 'Genre Shapeshifter',
    emoji: '🦋',
    subheadline: 'No box can hold your taste',
    description:
        'Classical at breakfast, hyperpop by lunch, ambient jazz at sunset. '
        'Your music taste spans continents and decades. '
        'You live between genres — and that\'s exactly where the magic is.',
    traits: ['Eclectic', 'Cross-genre', 'Open-minded', 'Trend agnostic'],
    gradient: [Color(0xFF2d1b69), Color(0xFF11998e), Color(0xFF38ef7d)],
  ),
  _PersonalityTemplate(
    key: 'nostalgia_keeper',
    title: 'Nostalgia Keeper',
    emoji: '📼',
    subheadline: 'Your soul lives in another era',
    description:
        'You rewind to eras that felt truer. Vinyl crackle, '
        'cassette hiss, early internet MP3s — you hear beauty in '
        'imperfection. The past has the best hits.',
    traits: ['Retro lover', 'Era curator', 'Emotional memory', 'Sentimental'],
    gradient: [Color(0xFFf7971e), Color(0xFFffd200)],
  ),
  _PersonalityTemplate(
    key: 'bass_seeker',
    title: 'Bass Seeker',
    emoji: '🔊',
    subheadline: 'You need to feel the music, not just hear it',
    description:
        'If it doesn\'t hit the chest, it doesn\'t count. '
        'Low frequencies are your love language. '
        'You measure a song\'s worth in bass drops and sub-bass presence.',
    traits: ['High energy', 'Physical listener', 'Volume maximizer', 'Festival goer'],
    gradient: [Color(0xFF141E30), Color(0xFF243B55)],
  ),
  _PersonalityTemplate(
    key: 'lyric_analyst',
    title: 'Lyric Analyst',
    emoji: '📖',
    subheadline: 'You decode what the artist really meant',
    description:
        'You pause songs to look up lyrics. You catch double meanings, '
        'hidden references, and personal metaphors nobody else notices. '
        'For you, music is literature with a melody.',
    traits: ['Word-focused', 'Deep listener', 'Meaning hunter', 'Poetry reader'],
    gradient: [Color(0xFF4b6cb7), Color(0xFF182848)],
  ),
  _PersonalityTemplate(
    key: 'mood_alchemist',
    title: 'Mood Alchemist',
    emoji: '✨',
    subheadline: 'You use music to transform how you feel',
    description:
        'Sad? You have a playlist. Anxious? Different playlist. '
        'Want to feel invincible? You know exactly which song. '
        'Music is your emotional toolkit — and you\'ve mastered it.',
    traits: ['Emotionally aware', 'Therapeutic listener', 'Mood curator', 'Empathetic'],
    gradient: [Color(0xFFda4453), Color(0xFF89216b)],
  ),
  _PersonalityTemplate(
    key: 'sonic_pioneer',
    title: 'Sonic Pioneer',
    emoji: '🚀',
    subheadline: 'You live at the edge of what music can be',
    description:
        'Experimental, avant-garde, glitchy, or unclassifiable — '
        'if it pushes boundaries, you\'re already there. '
        'You find beauty in sounds that make others uncomfortable.',
    traits: ['Experimental', 'Early adopter', 'Boundary pusher', 'Avant-garde'],
    gradient: [Color(0xFF7F00FF), Color(0xFFE100FF)],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class MusicPersonalityService {
  static final MusicPersonalityService _instance =
      MusicPersonalityService._();
  factory MusicPersonalityService() => _instance;
  MusicPersonalityService._();

  final _col =
      FirebaseFirestore.instance.collection('music_personalities');

  /// Get cached personality for a user (null if none yet)
  Future<MusicPersonality?> getPersonality(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return MusicPersonality.fromFirestore(doc);
  }

  /// Generate + cache a new personality based on OrbitState mood & simple heuristics
  Future<MusicPersonality> generatePersonality({
    required String uid,
    required String mood,
    required String moodEmoji,
    required String nowPlayingTitle,
    required String nowPlayingArtist,
  }) async {
    // Pick a personality deterministically from uid hash + current mood seed
    // so results are stable for the same user on the same day
    final seed = uid.hashCode ^ mood.hashCode ^ DateTime.now().day;
    final rng = math.Random(seed);
    final template = _kPersonalities[rng.nextInt(_kPersonalities.length)];

    final personality = MusicPersonality(
      uid: uid,
      typeKey: template.key,
      title: template.title,
      emoji: template.emoji,
      description: template.description,
      subheadline: template.subheadline,
      traits: template.traits,
      gradient: template.gradient,
      generatedAt: DateTime.now(),
    );

    await _col.doc(uid).set(personality.toMap());
    return personality;
  }

  /// Regenerate (force new pick)
  Future<MusicPersonality> regenerate({
    required String uid,
    required String mood,
    required String moodEmoji,
    required String nowPlayingTitle,
    required String nowPlayingArtist,
  }) async {
    // Delete cache so next call picks fresh
    await _col.doc(uid).delete();
    // Use a different seed that changes each call
    final seed = uid.hashCode ^ DateTime.now().millisecondsSinceEpoch;
    final rng = math.Random(seed);
    final template = _kPersonalities[rng.nextInt(_kPersonalities.length)];

    final personality = MusicPersonality(
      uid: uid,
      typeKey: template.key,
      title: template.title,
      emoji: template.emoji,
      description: template.description,
      subheadline: template.subheadline,
      traits: template.traits,
      gradient: template.gradient,
      generatedAt: DateTime.now(),
    );

    await _col.doc(uid).set(personality.toMap());
    return personality;
  }

  Stream<MusicPersonality?> personalityStream(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MusicPersonality.fromFirestore(doc);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MusicPersonalityScreen extends StatefulWidget {
  const MusicPersonalityScreen({super.key});

  @override
  State<MusicPersonalityScreen> createState() =>
      _MusicPersonalityScreenState();
}

class _MusicPersonalityScreenState extends State<MusicPersonalityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  MusicPersonality? _personality;
  bool _loading = true;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = Provider.of<OrbitState>(context, listen: false);
    final svc = MusicPersonalityService();
    MusicPersonality? p = await svc.getPersonality(state.uid);
    if (p == null) {
      final player = AudioPlayerService();
      p = await svc.generatePersonality(
        uid: state.uid,
        mood: state.mood ?? '',
        moodEmoji: state.moodEmoji ?? '',
        nowPlayingTitle: player.currentTitle,
        nowPlayingArtist: player.currentArtist,
      );
    }
    if (mounted) {
      setState(() {
        _personality = p;
        _loading = false;
      });
      _controller.forward(from: 0);
    }
  }

  Future<void> _regenerate() async {
    final state = Provider.of<OrbitState>(context, listen: false);
    final player = AudioPlayerService();
    setState(() => _regenerating = true);
    _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 300));
    final p = await MusicPersonalityService().regenerate(
      uid: state.uid,
      mood: state.mood ?? '',
      moodEmoji: state.moodEmoji ?? '',
      nowPlayingTitle: player.currentTitle,
      nowPlayingArtist: player.currentArtist,
    );
    if (mounted) {
      setState(() {
        _personality = p;
        _regenerating = false;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AuraTheme.current;
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          'Music Personality',
          style: TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_personality != null && !_regenerating)
            TextButton.icon(
              onPressed: _regenerate,
              icon: Icon(Icons.refresh_rounded,
                  color: theme.accent, size: 18),
              label: Text(
                'Retry',
                style: TextStyle(
                    color: theme.accent, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildLoading(theme)
          : _personality == null
              ? _buildEmpty(theme)
              : _buildContent(theme),
    );
  }

  Widget _buildLoading(AuraTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: theme.accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing your sound...',
            style: TextStyle(
                color: theme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AuraTheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎵',
              style:
                  const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Could not generate personality',
            style: TextStyle(color: theme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuraTheme theme) {
    final p = _personality!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ────────────────────────────────────────────────
            _PersonalityHeroCard(personality: p),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────
            Text(
              'About Your Type',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                p.description,
                style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 15,
                    height: 1.65),
              ),
            ),
            const SizedBox(height: 24),

            // ── Traits ────────────────────────────────────────────────────
            Text(
              'Your Traits',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: p.traits.map((t) => _TraitChip(trait: t, theme: theme, gradient: p.gradient)).toList(),
            ),
            const SizedBox(height: 24),

            // ── All Types Preview ─────────────────────────────────────────
            Text(
              'All Personality Types',
              style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 12),
            ..._kPersonalities.map((pt) => _TypeRow(
                  template: pt,
                  isMe: pt.key == p.typeKey,
                  theme: theme,
                )),

            const SizedBox(height: 24),

            // ── Regenerate ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _regenerating ? null : _regenerate,
                icon: _regenerating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: theme.accent))
                    : Icon(Icons.shuffle_rounded,
                        color: theme.accent, size: 18),
                label: Text(
                  _regenerating ? 'Analyzing...' : 'Discover a New Type',
                  style: TextStyle(
                      color: theme.accent, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.accent.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
// Hero Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalityHeroCard extends StatelessWidget {
  final MusicPersonality personality;
  const _PersonalityHeroCard({required this.personality});

  @override
  Widget build(BuildContext context) {
    final p = personality;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.gradient.isNotEmpty
              ? p.gradient
              : [const Color(0xFF302b63), const Color(0xFF0f0c29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (p.gradient.isNotEmpty ? p.gradient.first : Colors.purple)
                .withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji + "YOUR TYPE" label
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(p.emoji,
                    style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR TYPE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            p.subheadline,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated ${_formatDate(p.generatedAt)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trait Chip
// ─────────────────────────────────────────────────────────────────────────────

class _TraitChip extends StatelessWidget {
  final String trait;
  final AuraTheme theme;
  final List<Color> gradient;
  const _TraitChip(
      {required this.trait, required this.theme, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient.isNotEmpty
                ? gradient
                : [theme.accent, theme.accentSecondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        trait,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Type Row (in "All Types" list)
// ─────────────────────────────────────────────────────────────────────────────

class _TypeRow extends StatelessWidget {
  final _PersonalityTemplate template;
  final bool isMe;
  final AuraTheme theme;
  const _TypeRow(
      {required this.template, required this.isMe, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? theme.accent.withOpacity(0.12)
            : theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: theme.accent.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Gradient swatch
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: template.gradient.isNotEmpty
                    ? template.gradient
                    : [const Color(0xFF302b63), const Color(0xFF0f0c29)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(template.emoji,
                style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  template.subheadline,
                  style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
