import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/aura_theme.dart';
import '../../utils/filters.dart';

// ── Sticker data ──────────────────────────────────────────────────────────────
class VybeStickerItem {
  final String emoji;
  double x;   // 0.0–1.0 relative to canvas width
  double y;   // 0.0–1.0 relative to canvas height
  double scale;

  VybeStickerItem({required this.emoji, this.x = 0.5, this.y = 0.5, this.scale = 1.0});

  Map<String, dynamic> toJson() => {'emoji': emoji, 'x': x, 'y': y, 'scale': scale};
  factory VybeStickerItem.fromJson(Map<String, dynamic> j) =>
      VybeStickerItem(emoji: j['emoji'], x: j['x'], y: j['y'], scale: j['scale']);
}

// ── Sticker categories ────────────────────────────────────────────────────────
class _StickerCategory {
  final String name;
  final String icon;
  final List<String> stickers;
  const _StickerCategory(this.name, this.icon, this.stickers);
}

const _kCategories = [
  _StickerCategory('Bitmoji', '🧑', [
    '🧑‍🎤', '🧑‍🚀', '🧑‍🎨', '🧑‍💻', '💃', '🕺',
    '🙆', '🙋', '🤷', '🤦', '🫶', '🤜',
    '🫡', '🤩', '😎', '🥳', '😏', '🤭',
    '🥸', '🤪', '😤', '🫠', '🥺', '😭',
  ]),
  _StickerCategory('Moods', '✨', [
    '✨', '🔥', '💜', '💙', '🩷', '🖤',
    '⚡', '🌈', '🌙', '⭐', '💫', '🌟',
    '❤️‍🔥', '💞', '🫀', '💢', '💥', '❄️',
    '🌸', '🌺', '🌻', '🫧', '🎆', '🎇',
  ]),
  _StickerCategory('Music', '🎵', [
    '🎵', '🎶', '🎸', '🎹', '🎺', '🥁',
    '🎤', '🎧', '📻', '🎼', '🪗', '🎻',
    '🔊', '🎙️', '📢', '🎚️', '🎛️', '🪕',
  ]),
  _StickerCategory('Vybe', '💜', [
    '💜', '🌀', '🫦', '👁️', '🤌', '💎',
    '🏆', '👑', '🦋', '🐉', '🦄', '🌊',
    '🧿', '🪬', '☯️', '♾️', '🌐', '🔮',
  ]),
  _StickerCategory('Text', '💬', [
    '💬', '😍', '🥵', '🤡', '💀', '👻',
    '🫶', '🤞', '🤙', '👋', '🫰', '🖖',
    '☝️', '🙌', '👏', '🤜', '✌️', '🫵',
  ]),
];

// ── VybeStickerScreen ─────────────────────────────────────────────────────────
/// Shows the filtered image/thumbnail and lets the user add draggable emoji stickers.
/// Returns a List<VybeStickerItem> (can be empty) when done.
class VybeStickerScreen extends StatefulWidget {
  final String imagePath;    // thumbnail / photo to display
  final int filterIndex;     // applied filter to preview
  final bool isVideo;

  const VybeStickerScreen({
    super.key,
    required this.imagePath,
    required this.filterIndex,
    this.isVideo = false,
  });

  @override
  State<VybeStickerScreen> createState() => _VybeStickerScreenState();
}

class _VybeStickerScreenState extends State<VybeStickerScreen>
    with SingleTickerProviderStateMixin {
  final List<VybeStickerItem> _stickers = [];
  int _selectedCategory = 0;
  int? _activeSticker; // index of the currently focused sticker (for delete)
  late AnimationController _pulseCtrl;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _addSticker(String emoji) {
    setState(() {
      _stickers.add(VybeStickerItem(
        emoji: emoji,
        x: 0.35 + (_stickers.length % 3) * 0.12,
        y: 0.35 + (_stickers.length % 4) * 0.08,
        scale: 1.0,
      ));
      _activeSticker = _stickers.length - 1;
    });
  }

  void _deleteActive() {
    if (_activeSticker == null) return;
    setState(() {
      _stickers.removeAt(_activeSticker!);
      _activeSticker = null;
    });
  }

  void _done() => Navigator.pop(context, _stickers);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  if (_activeSticker != null)
                    GestureDetector(
                      onTap: _deleteActive,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            SizedBox(width: 5),
                            Text('Remove', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _done,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: const BoxDecoration(
                        gradient: AuraColors.brandGradient,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Canvas ────────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSticker = null),
                child: Container(
                  key: _canvasKey,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Base image with filter
                            Positioned.fill(
                              child: ColorFiltered(
                                colorFilter: kVybeFilters[widget.filterIndex].colorFilter,
                                child: Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Video badge
                            if (widget.isVideo)
                              Positioned(
                                top: 12, left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Video', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            // Stickers
                            ..._stickers.asMap().entries.map((entry) {
                              final i = entry.key;
                              final s = entry.value;
                              final isActive = _activeSticker == i;
                              return Positioned(
                                left: s.x * w - 30 * s.scale,
                                top: s.y * h - 30 * s.scale,
                                child: GestureDetector(
                                  onTap: () => setState(() => _activeSticker = isActive ? null : i),
                                  onScaleUpdate: (d) {
                                    setState(() {
                                      _activeSticker = i;
                                      final newX = (s.x * w + d.focalPointDelta.dx) / w;
                                      final newY = (s.y * h + d.focalPointDelta.dy) / h;
                                      s.x = newX.clamp(0.05, 0.95);
                                      s.y = newY.clamp(0.05, 0.95);
                                      if (d.scale != 1.0) {
                                        s.scale = (s.scale * d.scale).clamp(0.4, 3.0);
                                      }
                                    });
                                  },
                                  child: AnimatedBuilder(
                                    animation: _pulseCtrl,
                                    builder: (_, child) => Container(
                                      padding: EdgeInsets.all(isActive ? 4 : 0),
                                      decoration: isActive
                                          ? BoxDecoration(
                                              border: Border.all(
                                                color: AuraColors.accent.withOpacity(0.7 + 0.3 * _pulseCtrl.value),
                                                width: 2,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            )
                                          : null,
                                      child: child,
                                    ),
                                    child: Text(
                                      s.emoji,
                                      style: TextStyle(fontSize: 52 * s.scale),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Hint if no stickers
                            if (_stickers.isEmpty)
                              const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 120),
                                    Text('👇', style: TextStyle(fontSize: 32)),
                                    SizedBox(height: 8),
                                    Text('Tap stickers below to add',
                                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticker picker ─────────────────────────────────────────────
            _StickerPicker(
              categories: _kCategories,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (i) => setState(() => _selectedCategory = i),
              onStickerTap: _addSticker,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticker Picker Panel ──────────────────────────────────────────────────────
class _StickerPicker extends StatelessWidget {
  final List<_StickerCategory> categories;
  final int selectedCategory;
  final ValueChanged<int> onCategoryChanged;
  final ValueChanged<String> onStickerTap;

  const _StickerPicker({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onStickerTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categories[selectedCategory];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final active = i == selectedCategory;
                return GestureDetector(
                  onTap: () => onCategoryChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: active ? AuraColors.brandGradient : null,
                      color: active ? null : AuraColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? Colors.transparent : AuraColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categories[i].icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          categories[i].name,
                          style: TextStyle(
                            color: active ? Colors.white : AuraColors.textSecondary,
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Sticker grid
          SizedBox(
            height: 110,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: cat.stickers.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => onStickerTap(cat.stickers[i]),
                child: Container(
                  decoration: BoxDecoration(
                    color: AuraColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AuraColors.divider),
                  ),
                  child: Center(
                    child: Text(cat.stickers[i], style: const TextStyle(fontSize: 26)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
