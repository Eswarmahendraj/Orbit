import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../theme/aura_theme.dart';
import '../../utils/filters.dart';

/// Full-screen filter picker — works for both photos and videos.
///
/// [imagePath]  — for photo: the actual image file.
///                for video: the extracted JPEG thumbnail (used in strip).
/// [isVideo]    — true when the source is a video.
/// [videoPath]  — actual video file path (only used when [isVideo] is true).
///
/// Returns the chosen [int] filter index on confirm, or null if backed out.
class StatusFilterScreen extends StatefulWidget {
  final String imagePath;
  final bool isVideo;
  final String? videoPath;

  const StatusFilterScreen({
    super.key,
    required this.imagePath,
    this.isVideo = false,
    this.videoPath,
  });

  @override
  State<StatusFilterScreen> createState() => _StatusFilterScreenState();
}

class _StatusFilterScreenState extends State<StatusFilterScreen> {
  int _selected = 0;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.videoPath != null) {
      _videoCtrl =
          VideoPlayerController.file(File(widget.videoPath!))
            ..initialize().then((_) {
              if (!mounted) return;
              _videoCtrl!.setLooping(true);
              _videoCtrl!.setVolume(0); // muted preview
              _videoCtrl!.play();
              setState(() => _videoReady = true);
            });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _selected = i);
    final itemW = 88.0;
    final screenW = MediaQuery.of(context).size.width;
    final offset = (i * itemW) - (screenW / 2) + itemW / 2;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Builds the main preview (photo or video) with the active filter ────
  Widget _buildPreview() {
    final filter = kVybeFilters[_selected].colorFilter;
    if (widget.isVideo) {
      return ColorFiltered(
        key: ValueKey(_selected),
        colorFilter: filter,
        child: _videoReady && _videoCtrl != null
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl!.value.size.width,
                    height: _videoCtrl!.value.size.height,
                    child: VideoPlayer(_videoCtrl!),
                  ),
                ),
              )
            // Show thumbnail while video initialises
            : Image.file(
                File(widget.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      );
    }
    return ColorFiltered(
      key: ValueKey(_selected),
      colorFilter: filter,
      child: Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = kVybeFilters[_selected];
    final thumbFile = File(widget.imagePath); // thumbnail for strip always

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isVideo)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.videocam, size: 18,
                    color: AuraColors.textSecondary),
              ),
            const Text('Add Filter',
                style:
                    TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, _selected),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AuraColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Use This',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Large preview ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _buildPreview(),
                ),
              ),
            ),
          ),

          // ── Filter name ──────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Row(
              key: ValueKey(_selected),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(current.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  current.name,
                  style: const TextStyle(
                    color: AuraColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Thumbnail strip ──────────────────────────────────────────────
          SizedBox(
            height: 106,
            child: ListView.builder(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kVybeFilters.length,
              itemBuilder: (_, i) {
                final f = kVybeFilters[i];
                final active = i == _selected;
                return GestureDetector(
                  onTap: () => _select(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active
                                  ? AuraColors.accent
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AuraColors.accent
                                          .withOpacity(0.45),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                          // Strip always uses the thumbnail image (static frame)
                          child: ClipOval(
                            child: ColorFiltered(
                              colorFilter: f.colorFilter,
                              child: Image.file(
                                thumbFile,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${f.emoji} ${f.name}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? AuraColors.accent
                                : AuraColors.textSecondary,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
