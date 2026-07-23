import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

class PfpEditorScreen extends StatefulWidget {
  const PfpEditorScreen({super.key});
  @override
  State<PfpEditorScreen> createState() => _PfpEditorScreenState();
}

class _PfpEditorScreenState extends State<PfpEditorScreen>
    with TickerProviderStateMixin {
  final _state = OrbitState();
  File? _file;
  String _filterId = 'none';
  late AnimationController _pulse;

  // ── 20 Gen Z Filters ─────────────────────────────────────────────────────
  // Each matrix: [r_r, r_g, r_b, r_a, r_const,
  //               g_r, g_g, g_b, g_a, g_const,
  //               b_r, b_g, b_b, b_a, b_const,
  //               a_r, a_g, a_b, a_a, a_const]
  // Constants are added to the 0-255 range result.

  static const _filters = [
    // ── 1. Raw ──────────────────────────────────────────────────────────────
    _Flt('none', 'Raw', '◎', Color(0xFF888888), null),

    // ── 2. Golden Hour — warm amber glow ────────────────────────────────────
    _Flt('goldenhour', 'Golden Hour', '🌅', Color(0xFFFF9A3C), [
      1.30,  0.00,  0.00,  0,  20,
      0.05,  1.10,  0.00,  0,   5,
      0.00,  0.00,  0.55,  0, -15,
      0,     0,     0,     1,   0,
    ]),

    // ── 3. Arctic — clinical cold blue ──────────────────────────────────────
    _Flt('arctic', 'Arctic', '🧊', Color(0xFF5BC8FF), [
      0.68,  0.00,  0.00,  0, -15,
      0.00,  0.95,  0.05,  0,   5,
      0.05,  0.05,  1.55,  0,  28,
      0,     0,     0,     1,   0,
    ]),

    // ── 4. Cherry Bomb — bold dramatic reds ─────────────────────────────────
    _Flt('cherrybomb', 'Cherry Bomb', '🍒', Color(0xFFCC1A1A), [
      1.65, -0.10, -0.10,  0,   8,
      0.00,  0.82,  0.00,  0, -18,
      0.00,  0.00,  0.60,  0, -32,
      0,     0,     0,     1,   0,
    ]),

    // ── 5. Soft Girl — dreamy pink lifted ───────────────────────────────────
    _Flt('softgirl', 'Soft Girl', '🎀', Color(0xFFFFB6C1), [
      1.05,  0.08,  0.02,  0,  42,
      0.00,  0.86,  0.04,  0,  32,
      0.00,  0.00,  0.85,  0,  38,
      0,     0,     0,     1,   0,
    ]),

    // ── 6. Dark Academia — warm sepia shadows ───────────────────────────────
    _Flt('darkacademia', 'Dark Academia', '📚', Color(0xFF8B6914), [
      0.48,  0.46,  0.06,  0, -10,
      0.38,  0.44,  0.06,  0, -22,
      0.24,  0.34,  0.06,  0, -38,
      0,     0,     0,     1,   0,
    ]),

    // ── 7. VSCOcore — airy warm faded ───────────────────────────────────────
    _Flt('vscocore', 'VSCOcore', '🏖️', Color(0xFFFFC57D), [
      1.08,  0.00,  0.00,  0,  32,
      0.00,  1.00,  0.00,  0,  22,
      0.00,  0.00,  0.82,  0,  28,
      0,     0,     0,     1,   0,
    ]),

    // ── 8. Noir — high contrast B&W ─────────────────────────────────────────
    _Flt('noir', 'Noir', '🎬', Color(0xFF444444), [
      0.30,  0.59,  0.11,  0, -22,
      0.30,  0.59,  0.11,  0, -22,
      0.30,  0.59,  0.11,  0, -22,
      0,     0,     0,     1,   0,
    ]),

    // ── 9. Neon Rave — cyberpunk oversaturated ──────────────────────────────
    _Flt('neonrave', 'Neon Rave', '🕺', Color(0xFF00F5FF), [
      1.65, -0.30,  0.10,  0,  0,
     -0.20,  1.45, -0.10,  0,  0,
      0.10, -0.20,  1.75,  0,  0,
      0,     0,     0,     1,  0,
    ]),

    // ── 10. Ethereal — overexposed dreamy cool ──────────────────────────────
    _Flt('ethereal', 'Ethereal', '🫧', Color(0xFFD4EEFF), [
      0.85,  0.00,  0.15,  0,  58,
      0.00,  0.82,  0.05,  0,  52,
      0.05,  0.00,  0.92,  0,  58,
      0,     0,     0,     1,   0,
    ]),

    // ── 11. Vaporwave — purple pink cyan aesthetic ──────────────────────────
    _Flt('vaporwave', 'Vaporwave', '💜', Color(0xFFBF5FFF), [
      1.00,  0.00,  0.38,  0,   5,
      0.00,  0.68,  0.12,  0, -22,
      0.18,  0.00,  1.48,  0,  28,
      0,     0,     0,     1,   0,
    ]),

    // ── 12. Latte — creamy warm mocha ───────────────────────────────────────
    _Flt('latte', 'Latte', '☕', Color(0xFFD4956A), [
      1.12,  0.14,  0.00,  0,  12,
      0.06,  0.97,  0.00,  0,   4,
      0.00,  0.06,  0.62,  0, -12,
      0,     0,     0,     1,   0,
    ]),

    // ── 13. Midnight — dark deep cinematic blue ─────────────────────────────
    _Flt('midnight', 'Midnight', '🌙', Color(0xFF1A2A6C), [
      0.52,  0.00,  0.00,  0, -38,
      0.00,  0.58,  0.10,  0, -32,
      0.05,  0.12,  1.28,  0,  -5,
      0,     0,     0,     1,   0,
    ]),

    // ── 14. Cottagecore — earthy green forest ───────────────────────────────
    _Flt('cottagecore', 'Cottagecore', '🌿', Color(0xFF4A7C59), [
      0.82,  0.05,  0.00,  0,  -5,
      0.10,  1.22,  0.05,  0,  10,
      0.00,  0.05,  0.72,  0, -18,
      0,     0,     0,     1,   0,
    ]),

    // ── 15. Y2K — early digital camera oversaturated ────────────────────────
    _Flt('y2k', 'Y2K', '💿', Color(0xFFFF69B4), [
      1.32, -0.10,  0.12,  0, 14,
      0.00,  1.22,  0.00,  0, 10,
      0.12,  0.00,  1.28,  0, 14,
      0,     0,     0,     1,  0,
    ]),

    // ── 16. Glazed — peachy warm donut ──────────────────────────────────────
    _Flt('glazed', 'Glazed', '🍩', Color(0xFFFFB347), [
      1.14,  0.12,  0.05,  0, 26,
      0.05,  0.86,  0.05,  0, 18,
      0.00,  0.00,  0.80,  0, 24,
      0,     0,     0,     1,  0,
    ]),

    // ── 17. Grunge — gritty desaturated dirty green ─────────────────────────
    _Flt('grunge', 'Grunge', '🤘', Color(0xFF6B6B3A), [
      0.50,  0.28,  0.14,  0, -22,
      0.14,  0.62,  0.14,  0, -16,
      0.10,  0.18,  0.48,  0, -28,
      0,     0,     0,     1,   0,
    ]),

    // ── 18. Euphoria — purple glam sparkle ──────────────────────────────────
    _Flt('euphoria', 'Euphoria', '✨', Color(0xFFC43FFF), [
      1.10,  0.00,  0.32,  0,   5,
      0.00,  0.62,  0.10,  0, -28,
      0.28,  0.12,  1.52,  0,  18,
      0,     0,     0,     1,   0,
    ]),

    // ── 19. Kodak Gold — classic film warmth ────────────────────────────────
    _Flt('kodak', 'Kodak Gold', '📷', Color(0xFFE8C97A), [
      1.18,  0.08,  0.00,  0,   5,
      0.05,  0.96,  0.02,  0,  -5,
      0.00,  0.05,  0.75,  0,  -8,
      0,     0,     0,     1,   0,
    ]),

    // ── 20. Ice Spice — copper orange bold ──────────────────────────────────
    _Flt('icespice', 'Ice Spice', '🧡', Color(0xFFFF6B2B), [
      1.50,  0.00, -0.12,  0, 28,
      0.05,  1.02,  0.00,  0, 10,
     -0.12,  0.00,  0.80,  0,  0,
      0,     0,     0,     1,  0,
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _file = _state.pfpFile;
    _filterId = _state.pfpFilter;
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final xf = await ImagePicker()
          .pickImage(source: source, imageQuality: 85, maxWidth: 900);
      if (xf != null) setState(() => _file = File(xf.path));
    } catch (_) {}
  }

  Widget _applyFilter(Widget child, _Flt flt) {
    if (flt.matrix == null) return child;
    return ColorFiltered(
        colorFilter: ColorFilter.matrix(flt.matrix!), child: child);
  }

  // ── Large preview at top ────────────────────────────────────────────────
  Widget _preview(double size) {
    final flt = _filters.firstWhere((f) => f.id == _filterId);
    Widget img = _file != null
        ? Image.file(_file!, fit: BoxFit.cover, width: size, height: size)
        : Container(
            width: size, height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  flt.accent.withOpacity(0.4),
                  flt.accent.withOpacity(0.15),
                ],
              ),
            ),
            child: Icon(Icons.person_rounded,
                size: size * 0.45, color: Colors.white.withOpacity(0.6)),
          );

    img = _applyFilter(img, flt);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size + 14 + _pulse.value * 6,
            height: size + 14 + _pulse.value * 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                flt.accent.withOpacity(0.25 * (1 - _pulse.value * 0.3)),
                Colors.transparent,
              ]),
            ),
          ),
          // Accent border ring
          Container(
            width: size + 6, height: size + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: flt.accent.withOpacity(0.6), width: 2),
            ),
          ),
          // Photo
          ClipOval(child: SizedBox(width: size, height: size, child: child)),
          // Filter badge
          Positioned(
            bottom: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: flt.accent.withOpacity(0.6), width: 1.2),
              ),
              child: Text(
                '${flt.emoji}  ${flt.name}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: flt.accent,
                    letterSpacing: 0.3),
              ),
            ),
          ),
        ],
        children: [img],
      ),
    );
  }

  // ── Filter thumbnail ────────────────────────────────────────────────────
  Widget _thumb(_Flt f, double size) {
    Widget inner = _file != null
        ? Image.file(_file!, fit: BoxFit.cover, width: size, height: size)
        : Container(
            width: size, height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  f.accent.withOpacity(0.55),
                  f.accent.withOpacity(0.20),
                ],
              ),
            ),
            child: Center(
              child: Text(f.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          );
    return _applyFilter(inner, f);
  }

  @override
  Widget build(BuildContext context) {
    final selFlt = _filters.firstWhere((f) => f.id == _filterId);

    return Scaffold(
      backgroundColor: AuraTheme.background,
      appBar: AppBar(
        backgroundColor: AuraTheme.background,
        elevation: 0,
        title: const Text('edit photo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context, false)),
        actions: [
          TextButton(
            onPressed: () async {
              _state.pfpFile = _file;
              _state.pfpFilter = _filterId;
              await _state.save();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text('save',
                style: TextStyle(
                    color: selFlt.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ── Preview ────────────────────────────────────────────────────
          Center(child: _preview(175)),
          const SizedBox(height: 22),

          // ── Source buttons ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _srcBtn(Icons.camera_alt_rounded, 'Camera',
                  selFlt.accent, () => _pick(ImageSource.camera)),
              const SizedBox(width: 12),
              _srcBtn(Icons.photo_library_rounded, 'Gallery',
                  selFlt.accent, () => _pick(ImageSource.gallery)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('✦ filters',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.5,
                      color: selFlt.accent)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selFlt.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selFlt.accent.withOpacity(0.3), width: 1),
                ),
                child: Text('${_filters.length} filters',
                    style: TextStyle(
                        fontSize: 11,
                        color: selFlt.accent,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Filter strip ───────────────────────────────────────────────
          SizedBox(
            height: 118,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = _filterId == f.id;
                return GestureDetector(
                  onTap: () => setState(() => _filterId = f.id),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: sel ? 72 : 64,
                        height: sel ? 72 : 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sel
                                ? f.accent
                                : Colors.white.withOpacity(0.10),
                            width: sel ? 2.5 : 1.5,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: f.accent.withOpacity(0.50),
                                    blurRadius: 14,
                                    spreadRadius: 0,
                                  )
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13.5),
                          child: _thumb(f, sel ? 72 : 64),
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 72,
                        child: Text(
                          sel ? '${f.emoji} ${f.name}' : f.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                sel ? FontWeight.w800 : FontWeight.w500,
                            color: sel
                                ? f.accent
                                : Colors.white.withOpacity(0.45),
                            letterSpacing: sel ? 0.2 : 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Text('swipe for more vibes →',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.25),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _srcBtn(IconData icon, String label, Color accent,
          VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: AuraTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: accent.withOpacity(0.25), width: 1.2),
          ),
          child: Row(children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
}

// ── Filter model ──────────────────────────────────────────────────────────
class _Flt {
  final String id;
  final String name;
  final String emoji;
  final Color accent;        // Dominant tone colour for glow / badge
  final List<double>? matrix;
  const _Flt(this.id, this.name, this.emoji, this.accent, this.matrix);
}
