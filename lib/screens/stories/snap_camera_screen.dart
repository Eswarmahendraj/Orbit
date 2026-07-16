import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../theme/aura_theme.dart';
import 'snap_filters.dart';

// Identity color matrix (no-op)
const _kIdentity = <double>[
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

// ─────────────────────────────────────────────────────────────────────────────
// SnapAudience — who can see this snap
// ─────────────────────────────────────────────────────────────────────────────

enum SnapAudience {
  everyone('🌍', 'Everyone'),
  friends('👥', 'Friends'),
  closeFriends('⭐', 'Close Friends'),
  onlyMe('🔒', 'Only Me');

  final String icon;
  final String label;
  const SnapAudience(this.icon, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// SnapCameraScreen — entry point (choose photo or 15s video)
// ─────────────────────────────────────────────────────────────────────────────

class SnapCameraScreen extends StatefulWidget {
  const SnapCameraScreen({super.key});

  @override
  State<SnapCameraScreen> createState() => _SnapCameraScreenState();
}

class _SnapCameraScreenState extends State<SnapCameraScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  bool _loading = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    setState(() => _loading = true);
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1080,
      );
      if (xfile != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SnapPreviewScreen(
              file: File(xfile.path),
              isVideo: false,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _captureVideo() async {
    setState(() => _loading = true);
    try {
      final xfile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 15),
      );
      if (xfile != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SnapPreviewScreen(
              file: File(xfile.path),
              isVideo: true,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _loading = true);
    try {
      final choice = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AuraTheme.themeCard,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AuraTheme.themeTextMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AuraTheme.accent,
                  child: Icon(Icons.image_rounded,
                      color: Colors.white, size: 20)),
              title: Text('Photo from gallery',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AuraTheme.themeTextPrimary)),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: CircleAvatar(
                  backgroundColor: AuraTheme.themeSurface,
                  child: const Icon(Icons.videocam_rounded,
                      color: AuraTheme.accent, size: 20)),
              title: Text('Video from gallery (≤15s)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AuraTheme.themeTextPrimary)),
              onTap: () => Navigator.pop(context, true),
            ),
          ]),
        ),
      );
      if (choice == null) {
        setState(() => _loading = false);
        return;
      }
      final XFile? xfile;
      if (choice) {
        xfile = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(seconds: 15));
      } else {
        xfile = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 90, maxWidth: 1080);
      }
      if (xfile != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SnapPreviewScreen(
              file: File(xfile!.path),
              isVideo: choice,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('snap 📸',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AuraTheme.accent))
          : SafeArea(
              child: Column(
                children: [
                  // ── Hero area ────────────────────────────────────────
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Camera viewfinder (decorative — real camera opened on tap)
                          ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AuraTheme.accent.withOpacity(0.4),
                                    width: 2),
                                color: AuraTheme.accent.withOpacity(0.06),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 72,
                                color: AuraTheme.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Capture a moment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Photos or up to 15-second videos',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Action buttons ────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(children: [
                      // Photo + Video row
                      Row(children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.camera_alt_rounded,
                            label: 'Photo Snap',
                            onTap: _capturePhoto,
                            gradient: const [
                              Color(0xFFFF8C42),
                              Color(0xFFFFAD75)
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.videocam_rounded,
                            label: 'Video (15s)',
                            onTap: _captureVideo,
                            gradient: const [
                              Color(0xFFE040FB),
                              Color(0xFFFF8C42)
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // Gallery
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickFromGallery,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.photo_library_rounded,
                              size: 18),
                          label: const Text('Pick from gallery',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionBtn helper
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradient;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.gradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SnapPreviewScreen — preview snap + choose audience + post
// ─────────────────────────────────────────────────────────────────────────────

class _SnapPreviewScreen extends StatefulWidget {
  final File file;
  final bool isVideo;
  const _SnapPreviewScreen({required this.file, required this.isVideo});

  @override
  State<_SnapPreviewScreen> createState() => _SnapPreviewScreenState();
}

class _SnapPreviewScreenState extends State<_SnapPreviewScreen> {
  SnapAudience _audience = SnapAudience.friends;
  SnapFilter? _filter;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoCtrl = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _videoReady = true);
            _videoCtrl!.setLooping(true);
            _videoCtrl!.play();
          }
        });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  void _postSnap() {
    // In a real app: upload file + metadata to Firestore/Storage
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${widget.isVideo ? '🎬 Video' : '📸 Photo'} snap posted to ${_audience.label}!'),
      backgroundColor: AuraTheme.accent,
      behavior: SnackBarBehavior.floating,
    ));
    // Pop back to home
    Navigator.of(context)
      ..pop()  // preview
      ..pop(); // camera
  }

  void _showAudiencePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraTheme.themeCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AuraTheme.themeTextMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Who can see this snap?',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AuraTheme.themeTextPrimary)),
            const SizedBox(height: 12),
            ...SnapAudience.values.map((a) => ListTile(
                  leading: Text(a.icon,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(a.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AuraTheme.themeTextPrimary)),
                  trailing: _audience == a
                      ? const Icon(Icons.check_circle_rounded,
                          color: AuraTheme.accent)
                      : null,
                  onTap: () {
                    setState(() => _audience = a);
                    setInner(() {});
                    Navigator.pop(ctx);
                  },
                )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Media preview (with color-matrix filter) ─────────────
          if (widget.isVideo && _videoReady)
            ColorFiltered(
              colorFilter: ColorFilter.matrix(
                  _filter?.matrix ?? _kIdentity),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoCtrl!.value.size.width,
                  height: _videoCtrl!.value.size.height,
                  child: VideoPlayer(_videoCtrl!),
                ),
              ),
            )
          else if (widget.isVideo && !_videoReady)
            const Center(
                child: CircularProgressIndicator(color: AuraTheme.accent))
          else
            ColorFiltered(
              colorFilter: ColorFilter.matrix(
                  _filter?.matrix ?? _kIdentity),
              child: Image.file(widget.file, fit: BoxFit.cover),
            ),

          // ── Filter overlay (animated effects on top of media) ────
          if (_filter != null)
            Positioned.fill(
              child: IgnorePointer(
                child: SnapFilterOverlay(filterId: _filter!.id),
              ),
            ),

          // ── Top bar ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(children: [
                  // Close
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  // Duration badge (video only)
                  if (widget.isVideo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('≤15s',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                ]),
              ),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Filter picker strip ────────────────────────
                    const SizedBox(height: 12),
                    SnapFilterPicker(
                      selected: _filter,
                      onSelect: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 10),

                    // ── Audience + Post row ────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(children: [
                        // Audience chip
                        GestureDetector(
                          onTap: _showAudiencePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(_audience.icon,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(_audience.label,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more_rounded,
                                  color: Colors.white, size: 16),
                            ]),
                          ),
                        ),
                        const Spacer(),
                        // Post button
                        GestureDetector(
                          onTap: _postSnap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8C42), Color(0xFFFFAD75)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AuraTheme.accent.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Post snap',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                  SizedBox(width: 6),
                                  Icon(Icons.send_rounded,
                                      color: Colors.white, size: 18),
                                ]),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
