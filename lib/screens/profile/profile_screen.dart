import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/orbit_state.dart';
import '../../services/spotify_service.dart';
import '../../services/apple_music_service.dart';
import '../../services/storage_service.dart';
import '../../services/social_service.dart';
import '../../theme/aura_theme.dart';
import '../../widgets/orb_skeleton.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'pfp_editor_screen.dart';
import 'secret_vault_screen.dart';
import 'edit_profile_screen.dart';
import '../privacy/privacy_screen.dart';
import '../social/vibe_check_screen.dart';
import '../social/vybe_map_screen.dart';
import '../settings/settings_screen.dart';
import '../home/vibe_picker_sheet.dart';
import 'era_picker_sheet.dart';

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

  // Spotify Now Playing
  Map<String, dynamic>? _spotifyNowPlaying;
  bool _spotifyLoading = false;
  Timer? _spotifyPollTimer;

  // Apple Music Now Playing (iOS only)
  Map<String, dynamic>? _appleNowPlaying;
  bool _appleLoading = false;

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
    _fetchSpotifyNowPlaying();
    _fetchAppleNowPlaying();
    // Poll Spotify every 30 s so the card stays live
    _spotifyPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (SpotifyService().isConnected) _fetchSpotifyNowPlaying();
    });
  }

  @override
  void dispose() {
    _ringAnim.dispose();
    _player.dispose();
    _pinnedPlayer?.dispose();
    _spotifyPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSpotifyNowPlaying() async {
    if (!SpotifyService().isConnected) return;
    setState(() => _spotifyLoading = true);
    final track = await SpotifyService().getNowPlaying();
    if (mounted) setState(() {
      _spotifyNowPlaying = track;
      _spotifyLoading = false;
    });
  }

  Future<void> _connectSpotify() async {
    final ok = await SpotifyService().connect();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Spotify connected!'),
        backgroundColor: Color(0xFF1DB954),
        behavior: SnackBarBehavior.floating,
      ));
      _fetchSpotifyNowPlaying();
    }
  }

  Future<void> _fetchAppleNowPlaying() async {
    if (!Platform.isIOS) return;
    if (!AppleMusicService().isAuthorized) return;
    setState(() => _appleLoading = true);
    final track = await AppleMusicService().getNowPlaying();
    if (mounted) setState(() {
      _appleNowPlaying = track;
      _appleLoading = false;
    });
  }

  Future<void> _connectAppleMusic() async {
    if (!Platform.isIOS) return;
    final ok = await AppleMusicService().authorize();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Apple Music connected!'),
        backgroundColor: Color(0xFFFC3C44),
        behavior: SnackBarBehavior.floating,
      ));
      _fetchAppleNowPlaying();
    }
  }

  double? _uploadProgress; // null = idle, 0–1 = uploading

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final xf = await ImagePicker().pickImage(
          source: source, imageQuality: 85, maxWidth: 800);
      if (xf == null) return;

      final state = OrbitState();
      if (mounted) setState(() => _uploadProgress = 0.0);

      String? url;

      if (kIsWeb) {
        // On web, dart:io File doesn't exist — read raw bytes instead
        final bytes = await xf.readAsBytes();
        final mimeType = xf.mimeType ?? 'image/jpeg';
        url = await StorageService().uploadProfilePhotoBytes(
          bytes,
          contentType: mimeType,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
      } else {
        // Mobile: use File path + show local preview instantly
        final file = File(xf.path);
        state.pfpFile = file;
        if (mounted) setState(() {});
        url = await StorageService().uploadProfilePhoto(
          file,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
      }

      state.pfpUrl = url;
      await state.save();
      // Publish updated pfpUrl to Firestore so other users see it
      SocialService().upsertProfile();

      if (mounted) setState(() => _uploadProgress = null);
    } catch (_) {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  void _showPfpOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          const Text('change photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _pfpOption(Icons.camera_alt_rounded, 'Take a photo', () async {
            Navigator.pop(context);
            await _pickPhoto(ImageSource.camera);
          }),
          _pfpOption(Icons.photo_library_rounded, 'Choose from gallery', () async {
            Navigator.pop(context);
            await _pickPhoto(ImageSource.gallery);
          }),
          _pfpOption(Icons.auto_fix_high_rounded, 'Edit with filters', () async {
            Navigator.pop(context);
            final updated = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => const PfpEditorScreen()));
            if (updated == true && mounted) setState(() {});
          }),
        ]),
      ),
    );
  }

  Widget _pfpOption(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: AuraTheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AuraTheme.accent, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        onTap: onTap,
      );

  void _showQrSheet() {
    final state = OrbitState();
    final handle = state.displayName.isNotEmpty
        ? state.displayName.toLowerCase().replaceAll(' ', '.')
        : 'you';
    final url = 'https://orbit.app/u/$handle';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AuraTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('share your orbit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('@$handle',
              style: const TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A1A1A)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              // Orbit branding strip
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: AuraTheme.accent,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Center(
                    child: Text('O',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('ORBIT',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Text('scan to find me on Orbit',
              style: TextStyle(
                  color: AuraTheme.textMuted.withOpacity(0.7), fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _appleMusicCard() {
    if (!Platform.isIOS) return const SizedBox.shrink();

    const appleRed = Color(0xFFFC3C44);
    final apple = AppleMusicService();

    if (!apple.isAuthorized) {
      return GestureDetector(
        onTap: _connectAppleMusic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: appleRed.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appleRed.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Text('🎵', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Connect Apple Music',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: appleRed)),
                Text('show what you\'re listening to live',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: appleRed),
          ]),
        ),
      );
    }

    if (_appleLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFC3C44))),
          SizedBox(width: 12),
          Text('checking Apple Music...', style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
        ]),
      );
    }

    if (_appleNowPlaying == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Text('🎵', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('not playing anything on Apple Music',
                style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
          ),
          GestureDetector(
            onTap: _fetchAppleNowPlaying,
            child: const Icon(Icons.refresh, size: 16, color: AuraTheme.textMuted),
          ),
        ]),
      );
    }

    final track = _appleNowPlaying!;
    final isPlaying = track['isPlaying'] as bool? ?? false;
    final artUrl = track['artUrl'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appleRed.withOpacity(0.3)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: artUrl != null
              ? Image.network(artUrl, width: 48, height: 48, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _appleMusicArtPlaceholder())
              : _appleMusicArtPlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: appleRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: isPlaying ? appleRed : AuraTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPlaying ? 'LIVE' : 'PAUSED',
                    style: TextStyle(
                        color: isPlaying ? appleRed : AuraTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 3),
            Text(track['song'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(track['artist'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _fetchAppleNowPlaying,
          child: const Icon(Icons.refresh, size: 16, color: AuraTheme.textMuted),
        ),
      ]),
    );
  }

  Widget _appleMusicArtPlaceholder() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFFFC3C44).withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: Color(0xFFFC3C44), size: 22),
  );

  Widget _spotifyCard() {
    final spotify = SpotifyService();
    if (!spotify.isConnected) {
      return GestureDetector(
        onTap: _connectSpotify,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Text('🎵', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Connect Spotify',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1DB954))),
                Text('show what you\'re listening to live',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 11)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF1DB954)),
          ]),
        ),
      );
    }

    if (_spotifyLoading) {
      return const NowPlayingCardSkeleton();
    }

    if (_spotifyNowPlaying == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Text('🎵', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('not playing anything right now',
                style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
          ),
          GestureDetector(
            onTap: _fetchSpotifyNowPlaying,
            child: const Icon(Icons.refresh, size: 16, color: AuraTheme.textMuted),
          ),
        ]),
      );
    }

    final track = _spotifyNowPlaying!;
    final isPlaying = track['isPlaying'] as bool? ?? false;
    final artUrl = track['artUrl'] as String?;
    final progressMs = track['progressMs'] as int? ?? 0;
    final durationMs = track['durationMs'] as int? ?? 1;
    final progress = durationMs > 0 ? progressMs / durationMs : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          // Album art with live pulse
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: artUrl != null
                  ? Image.network(artUrl, width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _spotifyArtPlaceholder())
                  : _spotifyArtPlaceholder(),
            ),
            if (isPlaying)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _WaveformPainter(_ringAnim.value),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isPlaying)
                      _AnimatedBars()
                    else
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                          color: AuraTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      isPlaying ? 'LIVE' : 'PAUSED',
                      style: TextStyle(
                          color: isPlaying ? const Color(0xFF1DB954) : AuraTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchSpotifyNowPlaying,
                  child: const Icon(Icons.refresh, size: 14, color: AuraTheme.textMuted),
                ),
              ]),
              const SizedBox(height: 4),
              Text(track['song'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(track['artist'] as String,
                  style: const TextStyle(color: AuraTheme.textMuted, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        // Progress bar
        if (durationMs > 1) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AuraTheme.textMuted.withOpacity(0.15),
              color: const Color(0xFF1DB954),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_msToTime(progressMs),
                  style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted)),
              Text(_msToTime(durationMs),
                  style: const TextStyle(fontSize: 9, color: AuraTheme.textMuted)),
            ],
          ),
        ],
      ]),
    );
  }

  String _msToTime(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _spotifyArtPlaceholder() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFF1DB954).withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 22),
  );

  Widget _musicPlaceholder() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: AuraTheme.accent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: AuraTheme.accent, size: 20),
  );

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
                          Navigator.pop(context);
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

  // ── Helpers ──────────────────────────────────────────────────

  bool _isToday(String isoStr) {
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  String _timeAgo(String isoStr) {
    final dt = DateTime.tryParse(isoStr);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // ── Moment Detail Sheet (with poll) ──────────────────────────

  void _showMomentDetail(OrbitState state, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MomentDetailSheet(
        moment: state.myMoments[index],
        onVote: (optionKey) async {
          // toggle vote: if already voted this option, unvote
          final m = state.myMoments[index];
          final prev = m['pollVotedOption'] as String? ?? '';
          if (prev == optionKey) {
            m['pollVotedOption'] = '';
            m[optionKey] = (int.tryParse(m[optionKey]?.toString() ?? '0') ?? 0 - 1)
                .clamp(0, 9999).toString();
          } else {
            if (prev.isNotEmpty) {
              m[prev] = (int.tryParse(m[prev]?.toString() ?? '0') ?? 0 - 1)
                  .clamp(0, 9999).toString();
            }
            m['pollVotedOption'] = optionKey;
            m[optionKey] =
                ((int.tryParse(m[optionKey]?.toString() ?? '0') ?? 0) + 1).toString();
          }
          await state.save();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  // ── Pinned Song ───────────────────────────────────────────────

  Widget _pinnedSongCard(OrbitState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _playOrPausePinned(state),
        onLongPress: () => _showPinSongSheet(state),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AuraTheme.accent.withOpacity(0.18),
                AuraTheme.accentLight.withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AuraTheme.accent.withOpacity(0.3)),
          ),
          child: Row(children: [
            // Disc art
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AuraTheme.accent.withOpacity(0.15),
              ),
              child: Center(
                child: Icon(
                  _pinnedPlaying ? Icons.pause_rounded : Icons.music_note_rounded,
                  color: AuraTheme.accent, size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.push_pin_rounded, size: 11, color: AuraTheme.accent),
                  SizedBox(width: 4),
                  Text('song of the moment',
                      style: TextStyle(color: AuraTheme.accent, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 3),
                Text(state.pinnedSong,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(state.pinnedArtist,
                    style: const TextStyle(color: AuraTheme.textMuted, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            // Play button
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                  color: AuraTheme.accent, shape: BoxShape.circle),
              child: Icon(
                _pinnedPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 20,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  bool _pinnedPlaying = false;
  AudioPlayer? _pinnedPlayer;

  Future<void> _playOrPausePinned(OrbitState state) async {
    _pinnedPlayer ??= AudioPlayer();
    if (_pinnedPlaying) {
      await _pinnedPlayer!.pause();
      setState(() => _pinnedPlaying = false);
    } else {
      final url = state.pinnedPreviewUrl;
      if (url.isEmpty) return;
      try {
        await _pinnedPlayer!.setUrl(url);
        await _pinnedPlayer!.play();
        setState(() => _pinnedPlaying = true);
        _pinnedPlayer!.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed && mounted) {
            setState(() => _pinnedPlaying = false);
          }
        });
      } catch (_) {}
    }
  }

  void _showPinSongSheet(OrbitState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PinSongSheet(
        onPinned: (song, artist, url) async {
          state.pinnedSong = song;
          state.pinnedArtist = artist;
          state.pinnedPreviewUrl = url ?? '';
          await state.save();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showVibeStatusPicker(OrbitState state) {
    const presets = [
      ('in class', '😶'),
      ('at the gym', '💪'),
      ('studying', '📚'),
      ('free time', '✨'),
      ('with friends', '🔥'),
      ('gaming', '🎮'),
      ('eating', '🍜'),
      ('on a walk', '🌿'),
      ('crying in my room', '🛁'),
      ('can\'t sleep', '🌙'),
      ('at work', '💼'),
      ('driving', '🚗'),
      ('chilling', '🛋️'),
      ('out tonight', '🌃'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AuraTheme.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('what are you up to?',
                  style: TextStyle(
                      color: AuraTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('shows on your profile until you clear it',
                  style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, emoji) in presets)
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        state.vibeStatus = label;
                        state.vibeStatusEmoji = emoji;
                        await state.save();
                        if (mounted) setState(() {});
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: AuraTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AuraTheme.textMuted.withOpacity(0.15)),
                        ),
                        child: Text('$emoji  $label',
                            style: const TextStyle(
                                color: AuraTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                ],
              ),
              if (state.vibeStatus.isNotEmpty) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    state.vibeStatus = '';
                    state.vibeStatusEmoji = '';
                    await state.save();
                    if (mounted) setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('✕  clear status',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Moment Streak Banner ──────────────────────────────────────

  Widget _momentStreakBanner(OrbitState state) {
    final posted = state.postedMomentToday;
    final streak = state.momentStreak;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: posted
              ? [const Color(0xFF2ECC71).withOpacity(0.13),
                 const Color(0xFF1ABC9C).withOpacity(0.06)]
              : [AuraTheme.accent.withOpacity(0.13),
                 const Color(0xFFFFAD75).withOpacity(0.06)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: posted
              ? const Color(0xFF2ECC71).withOpacity(0.45)
              : AuraTheme.accent.withOpacity(0.45),
          width: 1.5,
        ),
      ),
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('$streak',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AuraTheme.accent,
                    height: 1)),
            const SizedBox(width: 6),
            const Text('day',
                style: TextStyle(
                    fontSize: 13,
                    color: AuraTheme.accent,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 2),
          const Text('moment streak',
              style: TextStyle(fontSize: 11, color: AuraTheme.textMuted)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: posted
                ? const Color(0xFF2ECC71).withOpacity(0.15)
                : AuraTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(posted ? '✓' : '⚡',
                style: TextStyle(
                    fontSize: 18,
                    color: posted
                        ? const Color(0xFF2ECC71)
                        : AuraTheme.accent)),
            const SizedBox(height: 2),
            Text(
              posted ? 'done\ntoday!' : 'post a\nmoment',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: posted
                      ? const Color(0xFF2ECC71)
                      : AuraTheme.accent,
                  height: 1.3),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Monthly Orbit Stats ───────────────────────────────────────

  Widget _orbitStatsCard(OrbitState state) {
    final month = _monthName(DateTime.now().month);
    final postCount = state.myPosts.length;
    final momentCount = state.myMoments.length;
    final streak = state.momentStreak;
    // Derive top mood from posts (most frequent vibeTag)
    final moodFreq = <String, int>{};
    for (final p in state.myPosts) {
      final t = p['vibeTag'] as String? ?? '';
      if (t.isNotEmpty) moodFreq[t] = (moodFreq[t] ?? 0) + 1;
    }
    final topMood = moodFreq.isEmpty ? state.mood : (
        moodFreq.entries.reduce((a, b) => a.value > b.value ? a : b).key);
    final topMoodEmoji = moodFreq.isEmpty ? state.moodEmoji : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A0A2E),
              AuraTheme.accent.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AuraTheme.accent.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('🌟', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('your orbit · $month',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AuraTheme.accent,
                      letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _statPill('$postCount', 'posts', Icons.grid_view_rounded),
              const SizedBox(width: 10),
              _statPill('$momentCount', 'moments', Icons.auto_awesome_rounded),
              const SizedBox(width: 10),
              _statPill('$streak 🔥', 'streak', Icons.local_fire_department_rounded),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _miniStat(
                    '${topMoodEmoji.isNotEmpty ? topMoodEmoji : '🎭'} $topMood',
                    'top mood'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                    state.pinnedSong.isNotEmpty
                        ? '🎵 ${state.pinnedSong}'
                        : '— not set',
                    'pinned song'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Icon(icon, color: AuraTheme.accent, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label,
                style: const TextStyle(
                    color: AuraTheme.textMuted, fontSize: 10)),
          ]),
        ),
      );

  Widget _miniStat(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: AuraTheme.textMuted, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];

  // ── Moments strip ─────────────────────────────────────────────

  Widget _momentsStrip(OrbitState state) {
    if (state.myMoments.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          const Text('moments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AuraTheme.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${state.myMoments.length}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AuraTheme.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: state.myMoments.length,
          itemBuilder: (_, i) {
            final m = state.myMoments[i];
            final text = m['text'] as String? ?? '';
            final ts = m['timestamp'] as String? ?? '';
            final today = _isToday(ts);
            final hasPoll = m.containsKey('pollOption1');
            final label = hasPoll ? '📊' : (text.isNotEmpty ? text[0] : '✨');
            return GestureDetector(
              onTap: () => _showMomentDetail(state, i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: today
                          ? const LinearGradient(
                              colors: [Color(0xFFFF8C42), Color(0xFFFFD580)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)
                          : null,
                      color: today ? null : AuraTheme.surface,
                      border: today
                          ? null
                          : Border.all(
                              color: AuraTheme.accent.withOpacity(0.3),
                              width: 2),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraTheme.card,
                      ),
                      child: Center(
                        child: Text(label,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 62,
                    child: Text(
                      today ? 'today' : _timeAgo(ts),
                      style: TextStyle(
                          fontSize: 9, color: AuraTheme.textMuted),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── Grid item ─────────────────────────────────────────────────

  Widget _buildGridItem(Map<String, dynamic> post, int i) {
    final photoPath = post['photoPath'] as String?;
    final artUrl = post['art'] as String?;
    final song = post['song'] as String?;
    final vibeTag = post['vibeTag'] as String? ?? '';
    final vibeEmoji = post['vibeEmoji'] as String? ?? '';
    final songEmoji = post['songEmoji'] as String? ?? '🎵';

    Widget? media;
    if (photoPath != null && photoPath.isNotEmpty) {
      final f = File(photoPath);
      if (f.existsSync()) media = Image.file(f, fit: BoxFit.cover);
    }
    if (media == null && artUrl != null && artUrl.isNotEmpty) {
      media = Image.network(artUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    }

    return Container(
      decoration: BoxDecoration(
        color: AuraTheme.accent.withOpacity(0.08 + (i % 3) * 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: media != null
            ? Stack(fit: StackFit.expand, children: [
                media,
                Container(color: Colors.black.withOpacity(0.2)),
                if (vibeTag.isNotEmpty)
                  Positioned(
                    top: 5, left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$vibeEmoji $vibeTag',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 8)),
                    ),
                  ),
                if (song != null)
                  Positioned(
                    bottom: 5, left: 4, right: 4,
                    child: Row(children: [
                      Text(songEmoji,
                          style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(song,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.music_note,
                    color: AuraTheme.accent, size: 28),
                const SizedBox(height: 4),
                Text(
                  song ?? 'vybe ${i + 1}',
                  style: const TextStyle(
                      fontSize: 9, color: AuraTheme.textMuted),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
      ),
    );
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
                icon: const Icon(Icons.qr_code_rounded),
                tooltip: 'Share profile',
                onPressed: _showQrSheet,
              ),
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
                  onTap: () => _showPfpOptions(),
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
                      // Upload progress overlay
                      if (_uploadProgress != null)
                        Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 36, height: 36,
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                color: AuraTheme.accent,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      if (_uploadProgress == null)
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
              // Tappable display name
              GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  if (updated == true && mounted) setState(() {});
                },
                child: Text(displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              // Tappable bio (or add bio prompt)
              GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  if (updated == true && mounted) setState(() {});
                },
                child: state.bio.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 4),
                        child: Text(state.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AuraTheme.textSecondary, fontSize: 13)),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_circle_outline,
                                  size: 14, color: AuraTheme.textMuted),
                              SizedBox(width: 4),
                              Text('add bio',
                                  style: TextStyle(
                                      color: AuraTheme.textMuted,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic)),
                            ]),
                      ),
              ),
              const SizedBox(height: 8),
              // Chips row: mood + vibe status
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                          fontSize: 13),
                    ),
                  ),
                ),
                if (state.vibeStatus.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showVibeStatusPicker(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AuraTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AuraTheme.textMuted.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${state.vibeStatusEmoji} ${state.vibeStatus}',
                        style: const TextStyle(
                            color: AuraTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showVibeStatusPicker(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AuraTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AuraTheme.textMuted.withOpacity(0.15)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, size: 13, color: AuraTheme.textMuted),
                        SizedBox(width: 3),
                        Text('status', style: TextStyle(
                            color: AuraTheme.textMuted, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ]),

              // Era Badge
              if (state.currentEra.isNotEmpty) ...[
                const SizedBox(height: 10),
                EraBadge(
                  era: state.currentEra,
                  emoji: state.currentEraEmoji,
                  large: true,
                  onTap: () => showEraPicker(context,
                      onChanged: () => setState(() {})),
                ),
              ] else ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => showEraPicker(context,
                      onChanged: () => setState(() {})),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 13,
                          color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text("set your era",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12)),
                    ]),
                  ),
                ),
              ],

              // NPC Mode toggle
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (state.npcModeExpired) {
                    state.activateNpcMode();
                  } else {
                    state.deactivateNpcMode();
                  }
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (!state.npcModeExpired)
                        ? const Color(0xFF4286f4).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (!state.npcModeExpired)
                            ? const Color(0xFF4286f4).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🤖', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      (!state.npcModeExpired)
                          ? 'npc mode: on'
                          : 'npc mode: off',
                      style: TextStyle(
                          color: (!state.npcModeExpired)
                              ? const Color(0xFF4286f4)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
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
                              color: const Color(0xFFF8EDFF),
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

              const SizedBox(height: 16),

              // Moment streak banner
              _momentStreakBanner(state),

              // Pinned song card
              if (state.pinnedSong.isNotEmpty) ...[
                _pinnedSongCard(state),
                const SizedBox(height: 12),
              ],

              // Moments strip
              _momentsStrip(state),

              // Orbit stats card
              _orbitStatsCard(state),

              const SizedBox(height: 12),

              // Vibe song card
              _vibeSongCard(state),

              const SizedBox(height: 12),

              // Spotify Now Playing
              _spotifyCard(),

              const SizedBox(height: 10),

              // Apple Music Now Playing (iOS only — SizedBox.shrink on Android)
              _appleMusicCard(),

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

          // Vybe grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: state.myPosts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 40),
                      child: Center(
                        child: Column(children: const [
                          Text('🎵', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 8),
                          Text("You haven't dropped any vybes yet",
                              style: TextStyle(color: AuraTheme.textMuted, fontSize: 14)),
                        ]),
                      ),
                    ),
                  )
                : SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildGridItem(state.myPosts[i], i),
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

// ─── Supporting widgets ───────────────────────────────────────────────────────

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

// ─── Pin Song Sheet ───────────────────────────────────────────────────────────

class _PinSongSheet extends StatefulWidget {
  final void Function(String song, String artist, String? url) onPinned;
  const _PinSongSheet({required this.onPinned});

  @override
  State<_PinSongSheet> createState() => _PinSongSheetState();
}

class _PinSongSheetState extends State<_PinSongSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounce;

  // Preview player
  final _previewPlayer = AudioPlayer();
  int? _playingIndex;
  bool _previewLoading = false;

  // Local cache so repeat/partial queries feel instant
  static final Map<String, List<Map<String, dynamic>>> _cache = {};

  static const _quickTags = ['lo-fi', 'rap', 'pop', 'chill', 'indie', 'r&b', 'trap', 'edm'];

  Widget _musicPlaceholder() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: AuraTheme.accent.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: AuraTheme.accent, size: 20),
  );

  void _onChanged(String q) {
    _debounce?.cancel();
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      setState(() { _results = []; _loading = false; _source = ''; });
      return;
    }
    // Hit cache instantly (<5ms) then refresh from network
    if (_cache.containsKey(trimmed)) {
      setState(() { _results = _cache[trimmed]!; _loading = false; });
    } else {
      setState(() => _loading = true);
    }
    // Still fire network call to get fresh/complete results
    _debounce = Timer(const Duration(milliseconds: 80), () => _search(trimmed));
  }

  String _source = ''; // 'spotify' | 'apple' | ''

  Future<void> _search(String q) async {
    try {
      List<Map<String, dynamic>> list = [];
      String src = '';

      // 1. Spotify (if connected)
      if (SpotifyService().isConnected) {
        list = await SpotifyService().search(q);
        if (list.isNotEmpty) src = 'spotify';
      }

      // 2. Apple Music / iTunes catalog (fallback or primary on iOS)
      if (list.isEmpty) {
        final uri = Uri.parse(
            'https://itunes.apple.com/search?term=${Uri.encodeComponent(q)}&entity=song&limit=10');
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          list = (data['results'] as List).map<Map<String, dynamic>>((r) => {
                'song': r['trackName'] as String,
                'artist': r['artistName'] as String,
                'url': r['previewUrl'] as String?,
                'artUrl': (r['artworkUrl100'] as String?)
                    ?.replaceAll('100x100bb', '300x300bb'),
              }).toList();
          if (list.isNotEmpty) src = 'apple';
        }
      }

      if (list.isNotEmpty) _cache[q] = list; // save for instant recall
      if (mounted) setState(() { _results = list; _source = src; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePreview(int index) async {
    final url = _results[index]['url'] as String? ??
        _results[index]['previewUrl'] as String?;
    if (url == null || url.isEmpty) return;
    HapticFeedback.lightImpact();

    if (_playingIndex == index) {
      // Pause
      await _previewPlayer.pause();
      setState(() => _playingIndex = null);
      return;
    }

    await _previewPlayer.stop();
    setState(() { _playingIndex = index; _previewLoading = true; });
    try {
      await _previewPlayer.setUrl(url);
      await _previewPlayer.play();
      _previewPlayer.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() { _playingIndex = null; _previewLoading = false; });
        }
      });
    } catch (_) {}
    if (mounted) setState(() => _previewLoading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final typing = _ctrl.text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        height: screenH * 0.62,
        decoration: const BoxDecoration(
          color: AuraTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AuraTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('pin a song',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AuraTheme.textPrimary)),
          const SizedBox(height: 3),
          const Text('shows on your profile until you change it',
              style: TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            autofocus: true,
            style: const TextStyle(color: AuraTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'search songs, artists...',
              hintStyle: const TextStyle(color: AuraTheme.textMuted),
              // glass icon only shown when field is empty
              prefixIcon: typing
                  ? null
                  : const Icon(Icons.search, color: AuraTheme.textMuted),
              // clear (×) only shown while typing
              suffixIcon: typing
                  ? GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        _onChanged('');
                      },
                      child: const Icon(Icons.close,
                          color: AuraTheme.textMuted, size: 18),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              filled: true,
              fillColor: AuraTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Source badge — shows which service returned results
          if (_source.isNotEmpty && _results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_source == 'spotify'
                            ? const Color(0xFF1DB954)
                            : const Color(0xFFFC3C44))
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _source == 'spotify' ? '🎵' : '🍎',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _source == 'spotify' ? 'Spotify' : 'Apple Music',
                      style: TextStyle(
                          color: _source == 'spotify'
                              ? const Color(0xFF1DB954)
                              : const Color(0xFFFC3C44),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ]),
            ),
          // Quick-tag chips shown when no query yet
          if (_ctrl.text.isEmpty)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    _ctrl.text = _quickTags[i];
                    _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: _ctrl.text.length));
                    _onChanged(_quickTags[i]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AuraTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AuraTheme.accent.withOpacity(0.25)),
                    ),
                    child: Text(_quickTags[i],
                        style: const TextStyle(
                            color: AuraTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AuraTheme.accent),
                ),
              ),
            ),
          if (!_loading && _results.isEmpty && _ctrl.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('no results — try a different word',
                    style: TextStyle(color: AuraTheme.textMuted, fontSize: 13)),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                final artUrl = r['artUrl'] as String?;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: artUrl != null
                        ? Image.network(artUrl, width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _musicPlaceholder())
                        : _musicPlaceholder(),
                  ),
                  title: Text(r['song'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(r['artist'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AuraTheme.textMuted, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((r['url'] as String? ?? r['previewUrl'] as String?) != null)
                        GestureDetector(
                          onTap: () => _togglePreview(i),
                          child: Container(
                            width: 34, height: 34,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _playingIndex == i
                                  ? AuraTheme.accent.withOpacity(0.15)
                                  : AuraTheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: _previewLoading && _playingIndex == i
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: Padding(
                                      padding: EdgeInsets.all(9),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: AuraTheme.accent),
                                    ))
                                : Icon(
                                    _playingIndex == i
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 18,
                                    color: _playingIndex == i
                                        ? AuraTheme.accent
                                        : AuraTheme.textMuted),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _previewPlayer.stop();
                          widget.onPinned(
                              r['song'] as String,
                              r['artist'] as String,
                              r['url'] as String? ?? r['previewUrl'] as String?);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AuraTheme.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Pin',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_playingIndex != null && _playingIndex! < _results.length)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AuraTheme.accent.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.music_note_rounded,
                    size: 16, color: AuraTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '▶ ${_results[_playingIndex!]['song']} · 30s preview',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AuraTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await _previewPlayer.stop();
                    setState(() => _playingIndex = null);
                  },
                  child: const Icon(Icons.stop_rounded,
                      size: 18, color: AuraTheme.accent),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ─── Moment Detail Sheet (with poll) ─────────────────────────────────────────

class _MomentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> moment;
  final Future<void> Function(String optionKey) onVote;
  const _MomentDetailSheet({required this.moment, required this.onVote});

  @override
  State<_MomentDetailSheet> createState() => _MomentDetailSheetState();
}

class _MomentDetailSheetState extends State<_MomentDetailSheet> {
  bool _voting = false;

  Future<void> _vote(String key) async {
    if (_voting) return;
    setState(() => _voting = true);
    await widget.onVote(key);
    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final text = m['text'] as String? ?? '';
    final hasPoll = m.containsKey('pollOption1');
    final opt1 = m['pollOption1'] as String? ?? '';
    final opt2 = m['pollOption2'] as String? ?? '';
    final v1 = int.tryParse(m['pollVote1']?.toString() ?? '0') ?? 0;
    final v2 = int.tryParse(m['pollVote2']?.toString() ?? '0') ?? 0;
    final total = v1 + v2;
    final voted = m['pollVotedOption'] as String? ?? '';
    final pct1 = total == 0 ? 0.5 : v1 / total;
    final pct2 = total == 0 ? 0.5 : v2 / total;

    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AuraTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          const Text('moment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AuraTheme.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final shareText = hasPoll
                  ? '${text.isNotEmpty ? "$text\n\n" : ""}Poll on Orbit: "$opt1" vs "$opt2" — which side are you on? 🎵 orbit.app'
                  : '${text.isNotEmpty ? text : "Check this out"} 🎵 orbit.app';
              Share.share(shareText);
            },
            child: const Icon(Icons.ios_share_rounded,
                size: 20, color: AuraTheme.textMuted),
          ),
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 15, height: 1.5)),
        ],
        if (hasPoll) ...[
          const SizedBox(height: 20),
          const Text('poll', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AuraTheme.textMuted)),
          const SizedBox(height: 10),
          _pollOption('pollVote1', opt1, pct1, voted == 'pollVote1', total > 0 ? '${(pct1 * 100).round()}%' : ''),
          const SizedBox(height: 8),
          _pollOption('pollVote2', opt2, pct2, voted == 'pollVote2', total > 0 ? '${(pct2 * 100).round()}%' : ''),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text('$total ${total == 1 ? 'vote' : 'votes'}',
                style: const TextStyle(color: AuraTheme.textMuted, fontSize: 12)),
          ],
        ],
      ]),
    );
  }

  Widget _pollOption(String key, String label, double pct, bool isVoted, String pctStr) {
    return GestureDetector(
      onTap: () => _vote(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 48,
        decoration: BoxDecoration(
          color: isVoted
              ? AuraTheme.accent.withOpacity(0.12)
              : AuraTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isVoted
                ? AuraTheme.accent
                : AuraTheme.textMuted.withOpacity(0.2),
            width: isVoted ? 1.5 : 1,
          ),
        ),
        child: Stack(children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                color: AuraTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isVoted ? AuraTheme.accent : AuraTheme.textPrimary)),
              ),
              if (pctStr.isNotEmpty)
                Text(pctStr,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isVoted ? AuraTheme.accent : AuraTheme.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Animated music bars (Spotify "now playing" indicator) ─────────────────────
class _AnimatedBars extends StatefulWidget {
  const _AnimatedBars();
  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anims = [
      Tween(begin: 2.0, end: 10.0).animate(CurvedAnimation(
          parent: _c,
          curve: const Interval(0.0, 0.7, curve: Curves.easeInOut))),
      Tween(begin: 4.0, end: 10.0).animate(CurvedAnimation(
          parent: _c,
          curve: const Interval(0.2, 0.9, curve: Curves.easeInOut))),
      Tween(begin: 2.0, end: 8.0).animate(CurvedAnimation(
          parent: _c,
          curve: const Interval(0.1, 0.8, curve: Curves.easeInOut))),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _anims.map((a) => Container(
        width: 2.5,
        height: a.value,
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(1),
        ),
      )).toList(),
    ),
  );
}

// ── Subtle waveform overlay on album art while playing ────────────────────────
class _WaveformPainter extends CustomPainter {
  final double t;
  _WaveformPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1DB954).withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final y = size.height / 2 +
          math.sin((i / steps * 2 * math.pi) + t * 2 * math.pi) *
              (size.height * 0.25);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.t != t;
}
