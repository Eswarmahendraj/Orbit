import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Daily Drop — everyone listens to the same song at the same time
// Date-seeded so the song changes daily. Live emoji reactions via Firestore.
// ─────────────────────────────────────────────────────────────────────────────

// Curated drop songs — changes daily by seed
const _dropSongs = [
  {'song': 'Espresso', 'artist': 'Sabrina Carpenter',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273e3e3b64cea45265469d4cde5',
   'previewUrl': 'https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview126/v4/f3/59/61/f35961d7-45a7-6c4e-44c9-7d57e74de695/mzaf_17841427633730504268.plus.aac.p.m4a'},
  {'song': 'luther', 'artist': 'Kendrick Lamar & SZA',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b2732e02117d76426a08ac7d3a75',
   'previewUrl': null},
  {'song': 'Good 4 U', 'artist': 'Olivia Rodrigo',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273a91c10fe9472d9bd89802e5a',
   'previewUrl': null},
  {'song': 'As It Was', 'artist': 'Harry Styles',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b2732e8ed79e177ff6011076f5f0',
   'previewUrl': null},
  {'song': 'Flowers', 'artist': 'Miley Cyrus',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273c5649add07ed3720be9d5526',
   'previewUrl': null},
  {'song': 'Blinding Lights', 'artist': 'The Weeknd',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36',
   'previewUrl': null},
  {'song': 'Golden Hour', 'artist': 'JVKE',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273c9b01e1c5ee46d4ca22e5b41',
   'previewUrl': null},
  {'song': 'Heather', 'artist': 'Conan Gray',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273e6d8e9e7dd80f0c0d88dff2c',
   'previewUrl': null},
  {'song': 'Anti-Hero', 'artist': 'Taylor Swift',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
   'previewUrl': null},
  {'song': 'Vampire', 'artist': 'Olivia Rodrigo',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273e85259a1cae29a8d91f2093d',
   'previewUrl': null},
  {'song': 'Cruel Summer', 'artist': 'Taylor Swift',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273e787cffec20aa2a396a61647',
   'previewUrl': null},
  {'song': 'Stay', 'artist': 'The Kid LAROI & Justin Bieber',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b2736f4430e2b3e6c9b66f5b957e',
   'previewUrl': null},
  {'song': 'Peaches', 'artist': 'Justin Bieber',
   'artUrl': null, 'previewUrl': null},
  {'song': 'Heat Waves', 'artist': 'Glass Animals',
   'artUrl': 'https://i.scdn.co/image/ab67616d0000b273712701c5e263efc8726b1464',
   'previewUrl': null},
];

const _dropEmojis = ['🔥', '😭', '💀', '✨', '🎵', '🫀', '👏', '😮'];

class DailyDropScreen extends StatefulWidget {
  const DailyDropScreen({super.key});
  @override
  State<DailyDropScreen> createState() => _DailyDropScreenState();
}

class _DailyDropScreenState extends State<DailyDropScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _state = OrbitState();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isJoined = false;

  late Map<String, dynamic> _todaySong;
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _dropCollectionPath => 'daily_drop_reactions/$_todayKey/reactions';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    _todaySong = Map<String, dynamic>.from(
        _dropSongs[seed % _dropSongs.length]);

    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
        lowerBound: 0.95,
        upperBound: 1.05)
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_isJoined) return;
    HapticFeedback.mediumImpact();
    setState(() => _isJoined = true);

    // Play preview if available
    final url = _todaySong['previewUrl'] as String?;
    if (url != null) {
      _player = AudioPlayer();
      try {
        await _player!.setUrl(url);
        _player!.play();
        setState(() => _isPlaying = true);
      } catch (_) {}
    }
  }

  Future<void> _react(String emoji) async {
    HapticFeedback.selectionClick();
    final uid = _uid;
    if (uid == null) return;
    await _db.collection(_dropCollectionPath).doc(uid).set({
      'uid': uid,
      'name': _state.displayName,
      'emoji': emoji,
      'song': _todaySong['song'],
      'date': _todayKey,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final artUrl = _todaySong['artUrl'] as String?;

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('the daily drop ⚡',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          Text(_todayKey,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Header copy
          Text('right now, every orbiter is listening to this.',
              style: TextStyle(color: Colors.white.withOpacity(0.5),
                  fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // Album art / song card
          ScaleTransition(
            scale: _isJoined ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AuraTheme.card, AuraTheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isJoined ? [
                  BoxShadow(
                      color: AuraTheme.accent.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 8)),
                ] : [],
              ),
              child: Column(children: [
                // Art
                if (artUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                        imageUrl: artUrl,
                        width: 200, height: 200, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                        color: AuraTheme.surface,
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.music_note_rounded,
                        color: AuraTheme.accent, size: 64),
                  ),
                const SizedBox(height: 20),
                Text(_todaySong['song'] as String,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 22),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(_todaySong['artist'] as String,
                    style: TextStyle(color: Colors.white.withOpacity(0.6),
                        fontSize: 15),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // Join / Play button
          if (!_isJoined)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _join,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraTheme.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('join the drop ⚡',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            )
          else ...[
            // Emoji reactions
            Text('react live 👇',
                style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 12, fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _dropEmojis.map((e) => GestureDetector(
                onTap: () => _react(e),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12), width: 1),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              )).toList(),
            ),
          ],

          const SizedBox(height: 28),

          // Live reaction stream
          Text("orbiter reactions",
              style: TextStyle(color: Colors.white.withOpacity(0.45),
                  fontSize: 12, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          _LiveReactions(collectionPath: _dropCollectionPath),
        ]),
      ),
    );
  }
}

class _LiveReactions extends StatelessWidget {
  final String collectionPath;
  const _LiveReactions({required this.collectionPath});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('be the first to react 🎵',
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 13)),
            ),
          );
        }

        // Aggregate emojis
        final counts = <String, int>{};
        final names = <String, List<String>>{};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final emoji = data['emoji'] as String? ?? '🎵';
          final name = data['name'] as String? ?? 'Orbiter';
          counts[emoji] = (counts[emoji] ?? 0) + 1;
          names[emoji] = [...(names[emoji] ?? []), name];
        }

        return Column(children: [
          // Emoji summary bar
          Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: counts.entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(e.key, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('${e.value}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 16),
          // Recent reactions list
          ...docs.take(8).map((d) {
            final data = d.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(data['emoji'] as String? ?? '🎵',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(data['name'] as String? ?? 'Orbiter',
                    style: TextStyle(color: Colors.white.withOpacity(0.65),
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            );
          }),
          if (docs.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+ ${docs.length - 8} more orbiter${docs.length - 8 == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 12)),
            ),
        ]);
      },
    );
  }
}
