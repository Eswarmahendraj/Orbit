import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'pfp_editor_screen.dart';
import 'secret_vault_screen.dart';
import 'edit_profile_screen.dart';
import '../privacy/privacy_screen.dart';
import '../social/vibe_check_screen.dart';
import '../social/vybe_map_screen.dart';
import '../settings/settings_screen.dart';
import '../home/vibe_picker_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringAnim;
  final _player = AudioPlayer();
  bool _isPlaying = false;
  String? _previewUrl;

  static const _moods = [
    ('chill', '☀️'), ('hyped', '⚡'), ('nostalgic', '🌙'),
    ('focused', '🎧'), ('sad', '🌧️'), ('romantic', '💫'),
    ('cozy', '🫶'), ('euphoric', '✨'),
  ];

  static const _moodTags = ['indie', 'late nights', 'lo-fi', 'road trips', 'rainy days'];

  @override
  void initState() {
    super.initState();
    _ringAnim = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _fetchPreview();
  }

  @override
  void dispose() {
    _ringAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    try {
      final res = await http.get(Uri.parse(
          'https://itunes.apple.com/search?term=golden+hour+jvke&media=music&limit=1'));
      final data = jsonDecode(res.body);
      if ((data['results'] as List).isNotEmpty) {
        if (mounted) setState(() => _previewUrl = data['results'][0]['previewUrl']);
      }
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    if (_previewUrl != null) {
      try {
        await _player.setUrl(_previewUrl!);
        await _player.play();
      } catch (_) {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text("how are you vibing?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
            children: _moods.map((m) {
              final state = OrbitState();
              final selected = m.$1 == state.mood;
              return GestureDetector(
                onTap: () {
                  state.mood = m.$1;
                  state.moodEmoji = m.$2;
                  state.save();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? AuraTheme.accent : AuraTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(m.$2, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(m.$1,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AuraTheme.textPrimary)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Vibe Song Card ────────────────────────────────────────────

  Widget _vibeSongCard(OrbitState state) {
    if (!state.vibeActive) {
      // No active vibe song — show "set one" prompt
      return GestureDetector(
        onTap: () => _setVibeSheet(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AuraTheme.accent.withOpacity(0.2), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AuraTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.music_note_rounded,
                  color: AuraTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('set your vibe song',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text('show what you\'re listening to for 24h',
                    style: TextStyle(
                        color: AuraTheme.textMuted, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.add_circle_outline_rounded,
                color: AuraTheme.accent, size: 22),
          ]),
        ),
      );
    }

    // Active vibe song
    final hoursLeft = state.vibeHoursLeft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AuraTheme.accent.withOpacity(0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          const Text('🎵', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: const Text('VIBE SONG',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.accent)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer_outlined,
                  size: 10, color: AuraTheme.accent),
              const SizedBox(width: 3),
              Text('${hoursLeft}h left',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AuraTheme.accent,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),

        // Song row
        Row(children: [
          state.vibeArtUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    state.vibeArtUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _vibePlaceholder(),
                  ),
                )
              : _vibePlaceholder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(state.vibeSong,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(state.vibeArtist,
                  style: const TextStyle(
                      color: AuraTheme.textMuted, fontSize: 12)),
            ]),
          ),
          // Play button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: AuraTheme.accent, shape: BoxShape.circle),
              child: Center(
                child: _isPlaying
                    ? const Icon(Icons.pause_rounded,
                        color: Colors.white, size: 18)
                    : const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),

        // Change / clear row
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _setVibeSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                    color: AuraTheme.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(Icons.refresh_rounded,
                      color: AuraTheme.accent, size: 15),
                  SizedBox(width: 5),
                  Text('change vibe',
                      style: TextStyle(
                          color: AuraTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              state.clearVibeSong();
              setState(() {});
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: AuraTheme.surface,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('clear',
                  style: TextStyle(
                      color: AuraTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _vibePlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: AuraTheme.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.music_note_rounded,
          color: AuraTheme.accent, size: 22),
    );
  }

  // ── Set Vibe Song Bottom Sheet ────────────────────────────────

  void _setVibeSheet() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          Future<void> doSearch(String q) async {
            if (q.trim().isEmpty) return;
            setSheet(() { searching = true; results = []; });
            try {
              final res = await http.get(Uri.parse(
                  'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&media=music&limit=8'));
              final data = jsonDecode(res.body);
              setSheet(() {
                results = List<Map<String, dynamic>>.from(data['results'] ?? []);
                searching = false;
              });
            } catch (_) {
              setSheet(() => searching = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AuraTheme.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('set your vibe song',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text('shows on your profile for 24 hours',
                    style: TextStyle(
                        color: AuraTheme.textMuted, fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search a song...',
                    prefixIcon:
                        const Icon(Icons.search, color: AuraTheme.accent),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AuraTheme.accent),
                            ),
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: doSearch,
                ),
              ),
              const SizedBox(height: 8),
              if (results.isNotEmpty)
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final r = results[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            r['artworkUrl60'] ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                              width: 44,
                              height: 44,
                              color: AuraTheme.surface,
                              child: const Icon(Icons.music_note,
                                  color: AuraTheme.accent),
                            ),
                          ),
                        ),
                        title: Text(r['trackName'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle: Text(r['artistName'] ?? '',
                            style: const TextStyle(
                                color: AuraTheme.textSecondary,
                                fontSize: 11)),
                        onTap: () {
                          OrbitState().setVibeSong(
                            r['trackName'] ?? '',
                            r['artistName'] ?? '',
                            artUrl: r['artworkUrl100'],
                          );
                          Navigator.pop(ctx);
                          setState(() {});
                          _fetchPreviewForVibe(r['previewUrl']);
                        },
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('search to find your current vibe',
                      style: TextStyle(
                          color: AuraTheme.textMuted, fontSize: 14)),
                ),
              const SizedBox(height: 12),
            ]),
          );
        });
      },
    );
  }

  void _fetchPreviewForVibe(String? url) {
    if (url != null) setState(() => _previewUrl = url);
  }

  Widget _buildPfp(String initial) {
    final s = OrbitState();
    Widget img;
    if (s.pfpFile != null) {
      img = Image.file(s.pfpFile!, fit: BoxFit.cover, width: 90, height: 90);
      if (s.pfpFilter != 'none') {
        const filterMap = <String, List<double>>{
          'warm': [1.2,0,0,0,20, 0,1.0,0,0,5, 0,0,0.7,0,-15, 0,0,0,1,0],
          'cool': [0.8,0,0,0,-10, 0,1.0,0,0,5, 0,0,1.3,0,25, 0,0,0,1,0],
          'noir': [0.33,0.33,0.33,0,0, 0.33,0.33,0.33,0,0, 0.33,0.33,0.33,0,0, 0,0,0,1,0],
          'rose': [1.2,0.1,0,0,15, 0,0.85,0,0,-5, 0,0,0.85,0,-5, 0,0,0,1,0],
          'golden': [1.3,0.1,0,0,25, 0.1,1.1,0,0,10, 0,0,0.55,0,-20, 0,0,0,1,0],
          'fade': [0.85,0,0,0,40, 0,0.85,0,0,35, 0,0,0.85,0,30, 0,0,0,0.85,0],
          'vivid': [1.5,-0.2,-0.2,0,0, -0.2,1.5,-0.2,0,0, -0.2,-0.2,1.5,0,0, 0,0,0,1,0],
        };
        final matrix = filterMap[s.pfpFilter];
        if (matrix != null) {
          img = ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: img);
        }
      }
    } else {
      img = Container(
        width: 90, height: 90,
        color: AuraTheme.accent.withOpacity(0.15),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: AuraTheme.accent, fontSize: 36, fontWeight: FontWeight.w800)),
      );
    }
    return img;
  }

  @override
  Widget build(BuildContext context) {
    final state = OrbitState();
    final displayName = state.displayName;
    final username = state.username;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'Y';
    final postCount = state.myPosts.length;

    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AuraTheme.background,
            title: Text(username,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VybeMapScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AuraTheme.accent),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  if (updated == true && mounted) setState(() {});
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(children: [
              const SizedBox(height: 24),
              // PFP with animated ring
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push<bool>(context,
                        MaterialPageRoute(builder: (_) => const PfpEditorScreen()));
                    if (updated == true) setState(() {});
                  },
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (_, child) => CustomPaint(
                      painter: _RingPainter(
                          progress: _ringAnim.value, color: AuraTheme.accent),
                      child: child,
                    ),
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(child: _buildPfp(initial)),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: AuraTheme.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              if (state.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  child: Text(state.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AuraTheme.textSecondary, fontSize: 13)),
                ),
              const SizedBox(height: 8),
              // Today's vibe chip
              GestureDetector(
                onTap: () async {
                  await showVibePicker(context, todayMode: true);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.moodEmoji} ${state.mood} · today',
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ),

              // Always vibes
              if (state.alwaysVibes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: state.alwaysVibes
                      .map((v) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AuraTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AuraTheme.accent.withOpacity(0.3)),
                            ),
                            child: Text('${v['emoji']} ${v['label']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AuraTheme.textSecondary)),
                          ))
                      .toList(),
                ),
              ],

              // Identity tags (if public)
              if (state.identityTagsPublic && state.identityTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: state.identityTags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF8EDFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9B59B6))),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 20),

              // ── Vibe song card ──
              _vibeSongCard(state),

              const SizedBox(height: 20),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatChip(label: 'vybes', value: '$postCount'),
                  const _StatChip(label: 'synced', value: '5'),
                  _StatChip(label: 'streak', value: '${state.streakCount}🔥'),
                ]),
              ),
              const SizedBox(height: 16),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SecretVaultScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: AuraTheme.card,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: AuraTheme.accent, size: 18),
                            SizedBox(width: 6),
                            Text('vault',
                                style: TextStyle(
                                    color: AuraTheme.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const VibeCheckScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: AuraTheme.card,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌡️', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text('vibe check',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Mood tags
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moodTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        border: Border.all(color: AuraTheme.accent.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(tag,
                        style: const TextStyle(
                            color: AuraTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('my vybes',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text('$postCount posts',
                        style: const TextStyle(
                            color: AuraTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),

          // Vybe grid — shows actual posts
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: state.myPosts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 40),
                      child: Center(
                        child: Column(children: [
                          const Text('🎵', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          const Text("You haven't dropped any vybes yet",
                              style: TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
                        ]),
                      ),
                    ),
                  )
                : SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final post = state.myPosts[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: AuraTheme.accent.withOpacity(0.08 + (i % 3) * 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: post['art'] != null && (post['art'] as String).isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(fit: StackFit.expand, children: [
                                    Image.network(post['art'], fit: BoxFit.cover),
                                    Container(color: Colors.black.withOpacity(0.3)),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.music_note, color: Colors.white, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            post['song'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                )
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.music_note, color: AuraTheme.accent, size: 28),
                                  const SizedBox(height: 4),
                                  Text(
                                    post['song'] ?? 'vybe ${i + 1}',
                                    style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ]),
                        );
                      },
                      childCount: state.myPosts.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AuraTheme.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AuraTheme.textMuted)),
      ]);
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withOpacity(0), color, color.withOpacity(0)],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
