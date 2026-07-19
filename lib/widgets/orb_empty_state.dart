import 'package:flutter/material.dart';
import '../theme/aura_theme.dart';

// ── Reusable empty state widget ───────────────────────────────────────────────

class OrbEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OrbEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AuraTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AuraTheme.textMuted,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AuraTheme.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pre-built empty states for common screens ─────────────────────────────────

class EmptyPeopleState extends StatelessWidget {
  final VoidCallback? onExplore;
  const EmptyPeopleState({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '🌌',
    title: 'No one here yet',
    subtitle: 'When people join Orbit, they\'ll show up here. Invite friends to grow your orbit.',
    actionLabel: onExplore != null ? 'Explore vibes' : null,
    onAction: onExplore,
  );
}

class EmptyDMsState extends StatelessWidget {
  final VoidCallback? onFind;
  const EmptyDMsState({super.key, this.onFind});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '💫',
    title: 'No messages yet',
    subtitle: 'Find someone vibing on the same wavelength and start a conversation.',
    actionLabel: 'Find people',
    onAction: onFind,
  );
}

class EmptyFeedState extends StatelessWidget {
  final VoidCallback? onFollow;
  const EmptyFeedState({super.key, this.onFollow});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '🎵',
    title: 'Your feed is quiet',
    subtitle: 'Follow people to see what they\'re listening to, posting, and vibing with.',
    actionLabel: 'Find people to follow',
    onAction: onFollow,
  );
}

class EmptyPulseState extends StatelessWidget {
  const EmptyPulseState({super.key});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '🎧',
    title: 'No beats yet',
    subtitle: 'Pulse cards will appear here as people share what moves them.',
  );
}

class EmptySearchState extends StatelessWidget {
  final String query;
  const EmptySearchState({super.key, required this.query});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '🔍',
    title: 'Nothing for "$query"',
    subtitle: 'Try different keywords, an artist name, or a mood.',
  );
}

class EmptyCampfiresState extends StatelessWidget {
  final VoidCallback? onCreate;
  const EmptyCampfiresState({super.key, this.onCreate});

  @override
  Widget build(BuildContext context) => OrbEmptyState(
    emoji: '🔥',
    title: 'No campfires burning',
    subtitle: 'Start a listening room, invite your crew, and share the vibe.',
    actionLabel: 'Start a campfire',
    onAction: onCreate,
  );
}
