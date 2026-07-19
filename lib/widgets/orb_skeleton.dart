import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/aura_theme.dart';

// ── Reusable shimmer skeleton components ──────────────────────────────────────

class OrbSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const OrbSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuraTheme.surface,
      highlightColor: AuraTheme.card,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ── Person tile skeleton (for Find screen) ────────────────────────────────────

class PersonTileSkeleton extends StatelessWidget {
  const PersonTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuraTheme.surface,
      highlightColor: AuraTheme.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          // Avatar circle
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AuraTheme.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 120, color: AuraTheme.surface,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, color: AuraTheme.surface,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Container(
            width: 72, height: 30,
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Song tile skeleton ─────────────────────────────────────────────────────────

class SongTileSkeleton extends StatelessWidget {
  const SongTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuraTheme.surface,
      highlightColor: AuraTheme.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AuraTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 140, color: AuraTheme.surface,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 90, color: AuraTheme.surface,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              color: AuraTheme.surface,
              shape: BoxShape.circle,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Message thread tile skeleton ───────────────────────────────────────────────

class MessageTileSkeleton extends StatelessWidget {
  const MessageTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuraTheme.surface,
      highlightColor: AuraTheme.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
              color: AuraTheme.surface,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(height: 13, width: 110, color: AuraTheme.surface,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                  Container(height: 10, width: 40, color: AuraTheme.surface,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                ]),
                const SizedBox(height: 6),
                Container(height: 10, width: 180, color: AuraTheme.surface,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Now Playing card skeleton (profile screen) ────────────────────────────────

class NowPlayingCardSkeleton extends StatelessWidget {
  const NowPlayingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AuraTheme.surface,
      highlightColor: AuraTheme.card,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AuraTheme.card,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 60, color: AuraTheme.card,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 14, width: 140, color: AuraTheme.card,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 5),
                Container(height: 10, width: 90, color: AuraTheme.card,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Generic list of skeletons ──────────────────────────────────────────────────

class SkeletonList extends StatelessWidget {
  final Widget skeleton;
  final int count;

  const SkeletonList({super.key, required this.skeleton, this.count = 6});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: count,
    itemBuilder: (_, __) => skeleton,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
  );
}
