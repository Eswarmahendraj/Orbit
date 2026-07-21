import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/aura_theme.dart';
import '../../models/orbit_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NPC Song of the Day — daily song persona
// "Today you're 'Espresso' by Sabrina Carpenter — chaotic, caffeinated,
//  unapologetically extra." Shows on profile. Changes every day.
// ─────────────────────────────────────────────────────────────────────────────

class NpcSongPersona {
  final String song;
  final String artist;
  final String emoji;
  final String description;
  final List<Color> gradient;

  const NpcSongPersona({
    required this.song,
    required this.artist,
    required this.emoji,
    required this.description,
    required this.gradient,
  });
}

const _npcPersonas = [
  NpcSongPersona(
    song: 'Espresso', artist: 'Sabrina Carpenter', emoji: '☕',
    description: 'chaotic, caffeinated, and unapologetically extra. you don\'t fix problems — you make them cuter.',
    gradient: [Color(0xFFf7971e), Color(0xFFffd200)],
  ),
  NpcSongPersona(
    song: 'luther', artist: 'Kendrick Lamar & SZA', emoji: '🌊',
    description: 'deeply romantic, lowkey unhinged. you love intensely and overthink everything twice.',
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
  ),
  NpcSongPersona(
    song: 'Anti-Hero', artist: 'Taylor Swift', emoji: '😈',
    description: 'self-aware chaos agent. you\'re the problem and you know it and honestly? fine with that.',
    gradient: [Color(0xFF141e30), Color(0xFF8e24aa)],
  ),
  NpcSongPersona(
    song: 'Heather', artist: 'Conan Gray', emoji: '🌿',
    description: 'quietly devastated, prettily sad. you hold doors open for people who don\'t deserve it.',
    gradient: [Color(0xFF134e5e), Color(0xFF71b280)],
  ),
  NpcSongPersona(
    song: 'Good 4 U', artist: 'Olivia Rodrigo', emoji: '⚡',
    description: 'petty but make it pop punk. your playlist is a court case and you\'re winning.',
    gradient: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
  ),
  NpcSongPersona(
    song: 'Flowers', artist: 'Miley Cyrus', emoji: '🌺',
    description: 'evolved, unbothered, bought yourself flowers. main character season, no auditions needed.',
    gradient: [Color(0xFFee0979), Color(0xFFff6a00)],
  ),
  NpcSongPersona(
    song: 'Blinding Lights', artist: 'The Weeknd', emoji: '🌆',
    description: 'running from something or toward something — honestly unclear. drives fast, feels faster.',
    gradient: [Color(0xFF141e30), Color(0xFF4286f4)],
  ),
  NpcSongPersona(
    song: 'Golden Hour', artist: 'JVKE', emoji: '🌅',
    description: 'soft, golden, a little bit delusional. you romanticize everything including Tuesday.',
    gradient: [Color(0xFFf7971e), Color(0xFFffd200)],
  ),
  NpcSongPersona(
    song: 'Heat Waves', artist: 'Glass Animals', emoji: '🌊',
    description: 'missing someone you shouldn\'t. your whole personality is a fever dream in july.',
    gradient: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
  ),
  NpcSongPersona(
    song: 'As It Was', artist: 'Harry Styles', emoji: '🪩',
    description: 'nostalgic for something that hasn\'t happened yet. you\'re doing your best. mostly.',
    gradient: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ),
  NpcSongPersona(
    song: 'Cruel Summer', artist: 'Taylor Swift', emoji: '☀️',
    description: 'chaotic summer energy. something is always about to happen and you are NOT ready.',
    gradient: [Color(0xFFf953c6), Color(0xFFb91d73)],
  ),
  NpcSongPersona(
    song: 'Vampire', artist: 'Olivia Rodrigo', emoji: '🩸',
    description: 'aware of every red flag and walked toward them anyway. you\'re healing. it\'s slow.',
    gradient: [Color(0xFF8e24aa), Color(0xFF141e30)],
  ),
  NpcSongPersona(
    song: 'Ghost', artist: 'Justin Bieber', emoji: '👻',
    description: 'leaving before you get left. emotionally unavailable but emotionally invested. both.',
    gradient: [Color(0xFF373b44), Color(0xFF4286f4)],
  ),
  NpcSongPersona(
    song: 'Thunderstruck', artist: 'AC/DC', emoji: '⚡',
    description: 'unstoppable energy, possibly unhinged. you walk into rooms like a main character entrance.',
    gradient: [Color(0xFF373b44), Color(0xFFf7971e)],
  ),
  NpcSongPersona(
    song: 'Africa', artist: 'Toto', emoji: '🌍',
    description: 'deeply nostalgic, irony-immune. you\'re the reason "it\'s giving retro" exists.',
    gradient: [Color(0xFF5c3317), Color(0xFF8b6914)],
  ),
  NpcSongPersona(
    song: 'drivers license', artist: 'Olivia Rodrigo', emoji: '🚗',
    description: 'you drive past their house but make it poetry. the most dramatic version of yourself.',
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
  ),
  NpcSongPersona(
    song: 'Midnight Rain', artist: 'Taylor Swift', emoji: '🌙',
    description: '2am is your timezone. you make sadness look aesthetic without even trying.',
    gradient: [Color(0xFF141e30), Color(0xFF2193b0)],
  ),
  NpcSongPersona(
    song: 'Crazy in Love', artist: 'Beyoncé', emoji: '💛',
    description: 'walking into rooms like you own them because you do. confidence is the base layer.',
    gradient: [Color(0xFFf7971e), Color(0xFF11998e)],
  ),
  NpcSongPersona(
    song: 'Stay', artist: 'The Kid LAROI & Justin Bieber', emoji: '🫀',
    description: 'attached and in denial about it. you stay up overthinking things that are fine.',
    gradient: [Color(0xFF11998e), Color(0xFF38ef7d)],
  ),
  NpcSongPersona(
    song: 'Peaches', artist: 'Justin Bieber', emoji: '🍑',
    description: 'summer mode permanently activated. soft life era, easy energy, impossible to dislike.',
    gradient: [Color(0xFFf7971e), Color(0xFFffd200)],
  ),
];

// Get today's persona (same for all users on the same day)
NpcSongPersona getNpcPersonaForToday() {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day;
  return _npcPersonas[seed % _npcPersonas.length];
}

// Compact widget to show on profile
class NpcSongBadge extends StatelessWidget {
  final VoidCallback? onTap;
  const NpcSongBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final persona = getNpcPersonaForToday();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: persona.gradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: persona.gradient.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(persona.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('today you\'re',
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                    fontSize: 9, fontWeight: FontWeight.w600)),
            Text('"${persona.song}"',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full screen view
// ─────────────────────────────────────────────────────────────────────────────

class NpcSongScreen extends StatefulWidget {
  const NpcSongScreen({super.key});
  @override
  State<NpcSongScreen> createState() => _NpcSongScreenState();
}

class _NpcSongScreenState extends State<NpcSongScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  final persona = getNpcPersonaForToday();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _dateLabel {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}';
  }

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    await Share.share(
        'today i\'m "${persona.song}" by ${persona.artist} ${persona.emoji}\n\n'
        '"${persona.description}"\n\n'
        'what\'s your NPC song today? find out on Orbit ✨');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NPC song of the day 🤖',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(_dateLabel,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 11)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: _share),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              // Big persona card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: persona.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: persona.gradient.first.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(children: [
                  Text(persona.emoji,
                      style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('today you\'re',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 13, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('"${persona.song}"',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w900, fontSize: 26),
                      textAlign: TextAlign.center),
                  Text('by ${persona.artist}',
                      style: const TextStyle(color: Colors.white70,
                          fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '"${persona.description}"',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.6,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              // Tomorrow hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Text('🔄', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text('a new song persona drops tomorrow',
                      style: TextStyle(color: Colors.white.withOpacity(0.45),
                          fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              // Other personas preview
              Text('other orbiters are also...',
                  style: TextStyle(color: Colors.white.withOpacity(0.35),
                      fontSize: 12, fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _npcPersonas.take(6).where((p) => p.song != persona.song)
                    .take(4).map((p) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: p.gradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${p.emoji} "${p.song}"',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                  label: const Text('share your NPC',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraTheme.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
