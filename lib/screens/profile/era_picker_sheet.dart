import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/orbit_state.dart';
import '../../theme/aura_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// All available eras — very Gen Z
// ─────────────────────────────────────────────────────────────────────────────

class EraOption {
  final String label;
  final String emoji;
  final List<Color> gradient;

  const EraOption(this.label, this.emoji, this.gradient);
}

const kEras = [
  EraOption('villain era',    '🖤', [Color(0xFF1a1a2e), Color(0xFF16213e)]),
  EraOption('healing era',    '🌿', [Color(0xFF134e5e), Color(0xFF71b280)]),
  EraOption('glow-up era',    '✨', [Color(0xFFf7971e), Color(0xFFffd200)]),
  EraOption('delulu era',     '🦋', [Color(0xFFa18cd1), Color(0xFFfbc2eb)]),
  EraOption('main character', '🎬', [Color(0xFFfc4a1a), Color(0xFFf7b733)]),
  EraOption('NPC era',        '🤖', [Color(0xFF373b44), Color(0xFF4286f4)]),
  EraOption('soft life era',  '🫧', [Color(0xFFe0c3fc), Color(0xFF8ec5fc)]),
  EraOption('that girl era',  '💪', [Color(0xFF11998e), Color(0xFF38ef7d)]),
  EraOption('chaos era',      '🌀', [Color(0xFFf953c6), Color(0xFFb91d73)]),
  EraOption('unbothered era', '😌', [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
  EraOption('romantic era',   '🌹', [Color(0xFFee0979), Color(0xFFff6a00)]),
  EraOption('academia era',   '📚', [Color(0xFF5c3317), Color(0xFF8b6914)]),
  EraOption('coquette era',   '🎀', [Color(0xFFf8b4c8), Color(0xFFe85d9d)]),
  EraOption('revenge era',    '⚡', [Color(0xFF141e30), Color(0xFF8e24aa)]),
  EraOption('era TBD',        '🌑', [Color(0xFF232526), Color(0xFF414345)]),
];

// ─────────────────────────────────────────────────────────────────────────────
// Show era picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

void showEraPicker(BuildContext context, {required VoidCallback onChanged}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EraPickerSheet(onChanged: onChanged),
  );
}

class _EraPickerSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _EraPickerSheet({required this.onChanged});

  @override
  State<_EraPickerSheet> createState() => _EraPickerSheetState();
}

class _EraPickerSheetState extends State<_EraPickerSheet> {
  final _state = OrbitState();

  Future<void> _pick(EraOption era) async {
    HapticFeedback.mediumImpact();
    _state.currentEra = era.label;
    _state.currentEraEmoji = era.emoji;
    await _state.save();

    // Sync to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'currentEra': era.label,
        'currentEraEmoji': era.emoji,
      }).catchError((_) {});
    }

    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    HapticFeedback.lightImpact();
    _state.currentEra = '';
    _state.currentEraEmoji = '';
    await _state.save();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'currentEra': '',
        'currentEraEmoji': '',
      }).catchError((_) {});
    }
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AuraTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(children: [
          const Text("what's your era?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const Spacer(),
          if (_state.currentEra.isNotEmpty)
            TextButton(
              onPressed: _clear,
              child: Text('clear',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 13)),
            ),
        ]),
        const SizedBox(height: 4),
        Text('tap to set your current era on your profile',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45))),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: kEras.map((era) {
            final selected = _state.currentEra == era.label;
            return GestureDetector(
              onTap: () => _pick(era),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: era.gradient)
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(
                          color: era.gradient.first.withOpacity(0.4),
                          blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Text(era.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(era.label,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (selected)
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Era Badge widget — use anywhere to display the era
// ─────────────────────────────────────────────────────────────────────────────

class EraBadge extends StatelessWidget {
  final String era;
  final String emoji;
  final bool large;
  final VoidCallback? onTap;

  const EraBadge({
    super.key,
    required this.era,
    required this.emoji,
    this.large = false,
    this.onTap,
  });

  static EraOption? _findOption(String era) {
    try {
      return kEras.firstWhere((e) => e.label == era);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (era.isEmpty) return const SizedBox.shrink();
    final opt = _findOption(era);
    final gradient = opt?.gradient ?? [AuraTheme.accent, AuraTheme.accentLight];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: large ? 14 : 10,
            vertical: large ? 7 : 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(large ? 14 : 10),
          boxShadow: [
            BoxShadow(
                color: gradient.first.withOpacity(0.4),
                blurRadius: large ? 12 : 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji,
              style: TextStyle(fontSize: large ? 18 : 14)),
          const SizedBox(width: 6),
          Text(era,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: large ? 14 : 11)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.edit_rounded,
                color: Colors.white.withOpacity(0.6),
                size: large ? 14 : 11),
          ],
        ]),
      ),
    );
  }
}
