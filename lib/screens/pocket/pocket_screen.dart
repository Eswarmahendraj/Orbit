import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/aura_theme.dart';
import 'pocket_chat_screen.dart';

class PocketScreen extends StatelessWidget {
  const PocketScreen({super.key});

  static const _myId = 'me';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Pocket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pockets')
            .where('participants', arrayContains: _myId)
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: AuraColors.accent));
          }
          final pockets = snap.data!.docs;
          if (pockets.isEmpty) return _EmptyPocket();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pockets.length,
            itemBuilder: (_, i) {
              final data = pockets[i].data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants']);
              final otherId = participants.firstWhere((id) => id != _myId,
                  orElse: () => '');
              final fromName = data['fromAuraName'] ?? 'Unknown';

              return _PocketCard(
                pocketId: pockets[i].id,
                peerId: otherId,
                peerName: fromName,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PocketChatScreen(
                    pocketId: pockets[i].id,
                    peerAuraName: fromName,
                    peerId: otherId,
                  ),
                )),
              ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.05);
            },
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is The Pocket?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            const Text(
              'The Pocket opens when you Nudge someone in a Campfire Room and they Nudge back.\n\n'
              'It\'s a private space between just the two of you — no pressure, no timers. '
              'Share music, voice notes, or just vibe. If it feels right, Root the connection.',
              style: TextStyle(color: AuraColors.textSecondary, height: 1.6)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PocketCard extends StatelessWidget {
  final String pocketId, peerId, peerName;
  final DateTime createdAt;
  final VoidCallback onTap;
  const _PocketCard({
    required this.pocketId, required this.peerId,
    required this.peerName, required this.createdAt, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.accent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AuraColors.accent.withOpacity(0.08),
            blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AuraColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AuraColors.accent.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(peerName[0],
                  style: const TextStyle(
                    color: AuraColors.accent,
                    fontWeight: FontWeight.w800, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(peerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Tap to open your Pocket',
                    style: TextStyle(
                        color: AuraColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AuraColors.textSecondary),
        ],
      ),
    ),
  );
}

class _EmptyPocket extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 56))
              .animate().fadeIn().scale(),
          const SizedBox(height: 20),
          const Text('Your Pocket is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text(
            'Join a Campfire Room and Nudge someone whose vibe resonates with you. '
            'If they Nudge back, your Pocket opens.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AuraColors.textSecondary, fontSize: 13, height: 1.6)),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AuraColors.accent,
              side: const BorderSide(color: AuraColors.accent),
            ),
            child: const Text('Go to Campfire'),
          ),
        ],
      ),
    ),
  );
}
