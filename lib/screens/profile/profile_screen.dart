import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';
import 'pfp_editor_screen.dart';
import 'secret_vault_screen.dart';
import '../privacy/privacy_screen.dart';
import '../social/vibe_check_screen.dart';
import '../social/vybe_map_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringAnim;
  String _currentMood = 'chill';
  String _currentMoodEmoji = '☀️';
  final _player = AudioPlayer();
  bool _isPlaying = false;
  String? _previewUrl;

  final List<Map<String, String>> _moods = const [
    {'label': 'chill', 'emoji': '☀️'},
    {'label': 'hyped', 'emoji': '⚡'},
    {'label': 'nostalgic', 'emoji': '🌙'},
    {'label': 'focused', 'emoji': '🎧'},
    {'label': 'sad', 'emoji': '🌧️'},
    {'label': 'romantic', 'emoji': '💫'},
  ];

  final List<String> _moodTags = const [
    'indie', 'late nights', 'lo-fi', 'road trips', 'rainy days',
  ];

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _ringAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _fetchPreview();
  }

  @override
  void dispose() {
    _ringAnim.dispose();
    _player.dispose();
    super.dispose();
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
        width: 90,
        height: 90,
        color: AuraTheme.accent.withOpacity(0.15),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: AuraTheme.accent,
                fontSize: 36,
                fontWeight: FontWeight.w800)),
      );
    }
    return img;
  }

  Future<void> _fetchPreview() async {
    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=golden+hour+jvke&media=music&limit=1');
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      if (data['results'].isNotEmpty) {
        setState(() => _previewUrl = data['results'][0]['previewUrl']);
      }
    } catch (_) {}
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      if (_previewUrl != null) {
        try {
          await _player.setUrl(_previewUrl!);
          await _player.play();
        } catch (_) {
          setState(() => _isPlaying = false);
        }
      }
    }
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('how are you vibing?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: _moods.map((m) {
                final selected = m['label'] == _currentMood;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentMood = m['label']!;
                      _currentMoodEmoji = m['emoji']!;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          selected ? AuraTheme.accent : AuraTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m['emoji']!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          m['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AuraTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?.displayName ?? 'Eswar';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';

    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AuraTheme.background,
            title: const Text('my orbit',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: 'Vybe Map',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const VybeMapScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Privacy',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Avatar with ring — tap to edit PFP
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(context,
                          MaterialPageRoute(
                              builder: (_) => const PfpEditorScreen()));
                      if (updated == true) setState(() {});
                    },
                    child: AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (context, child) => CustomPaint(
                        painter: _RingPainter(
                            progress: _ringAnim.value,
                            color: AuraTheme.accent),
                        child: child,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: _buildPfp(initial),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: AuraTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _showMoodPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AuraTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_currentMoodEmoji $_currentMood',
                      style: const TextStyle(
                          color: AuraTheme.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _StatChip(label: 'vybes', value: '312'),
                      _StatChip(label: 'synced', value: '104'),
                      _StatChip(label: 'streak', value: '21🔥'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const SecretVaultScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AuraTheme.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                            MaterialPageRoute(
                                builder: (_) => const VibeCheckScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AuraTheme.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🌡️', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text('vibe check',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Now vibing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AuraTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                          left: BorderSide(
                              color: AuraTheme.accent, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AuraTheme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note,
                              color: AuraTheme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Golden Hour',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text('JVKE',
                                  style: TextStyle(
                                      color: AuraTheme.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: AuraTheme.accent,
                                shape: BoxShape.circle),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Mood tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moodTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AuraTheme.accent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                color: AuraTheme.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text('my vybes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17)),
                  ),
                ),
              ],
            ),
          ),

          // Vybe grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Container(
                  decoration: BoxDecoration(
                    color: AuraTheme.accent.withOpacity(0.08 + (i % 3) * 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note,
                          color: AuraTheme.accent, size: 28),
                      const SizedBox(height: 4),
                      Text('vybe ${i + 1}',
                          style: const TextStyle(
                              fontSize: 10, color: AuraTheme.textMuted)),
                    ],
                  ),
                ),
                childCount: 12,
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AuraTheme.textPrimary)),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AuraTheme.textMuted)),
      ],
    );
  }
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
