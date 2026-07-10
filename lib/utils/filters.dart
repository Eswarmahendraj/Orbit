import 'dart:ui';

/// A named photo filter backed by a 4×5 colour matrix.
class VybeFilter {
  final String name;
  final String emoji;
  final List<double> matrix;
  const VybeFilter(this.name, this.emoji, this.matrix);

  ColorFilter get colorFilter => ColorFilter.matrix(matrix);
}

/// 14 creative filters — index 0 is always "Normal".
const List<VybeFilter> kVybeFilters = [

  // ── 0. Pure — raw, no filter ───────────────────────────────────────────
  VybeFilter('Pure', '✨', [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]),

  // ── 1. Surge — punchy colours, energy rush ────────────────────────────
  VybeFilter('Surge', '🔥', [
    1.35, -0.29, -0.06, 0,  0,
    -0.15, 1.21, -0.06, 0,  0,
    -0.15, -0.29, 1.44, 0,  0,
    0,     0,     0,    1,  0,
  ]),

  // ── 2. Voltage — hyper-electric, great for night shots ───────────────
  VybeFilter('Voltage', '⚡', [
    2.10, -0.90, -0.20, 0,  0,
    -0.45, 1.65, -0.20, 0,  0,
    -0.45, -0.90, 2.35, 0,  0,
    0,     0,     0,    1,  0,
  ]),

  // ── 3. Frost — icy blue tones ─────────────────────────────────────────
  VybeFilter('Frost', '🧊', [
    0.78, 0,    0,    0,  0,
    0,    0.88, 0,    0,  0,
    0,    0,    1.35, 0,  25,
    0,    0,    0,    1,  0,
  ]),

  // ── 4. Ember — golden hour glow ───────────────────────────────────────
  VybeFilter('Ember', '🌅', [
    1.25, 0,    0,    0,  15,
    0,    1.05, 0,    0,  0,
    0,    0,    0.65, 0,  0,
    0,    0,    0,    1,  0,
  ]),

  // ── 5. Drift — purple-orange twilight magic ───────────────────────────
  VybeFilter('Drift', '🌆', [
    1.30, -0.10, 0.10, 0,  8,
    -0.10, 0.85, 0,    0, -5,
    0.20,  0,    1.25, 0,  12,
    0,     0,    0,    1,  0,
  ]),

  // ── 6. Tide — teal ocean vibes ────────────────────────────────────────
  VybeFilter('Tide', '🌊', [
    0.65, 0,     0,    0, -10,
    0,    1.10,  0.12, 0,  10,
    0,    0.10,  1.35, 0,  18,
    0,    0,     0,    1,  0,
  ]),

  // ── 7. Ghost — stripped-back greyscale ────────────────────────────────
  VybeFilter('Ghost', '🩶', [
    0.213, 0.715, 0.072, 0, 0,
    0.213, 0.715, 0.072, 0, 0,
    0.213, 0.715, 0.072, 0, 0,
    0,     0,     0,     1, 0,
  ]),

  // ── 8. Shadow — high-contrast dramatic B&W ────────────────────────────
  VybeFilter('Shadow', '🎞️', [
    0.33, 0.33, 0.33, 0, -35,
    0.33, 0.33, 0.33, 0, -35,
    0.33, 0.33, 0.33, 0, -35,
    0,    0,    0,    1,  0,
  ]),

  // ── 9. Echo — desaturated matte, like a memory ────────────────────────
  VybeFilter('Echo', '🌫️', [
    0.52, 0.38, 0.10, 0, 55,
    0.20, 0.70, 0.10, 0, 35,
    0.20, 0.40, 0.40, 0, 35,
    0,    0,    0,    1,  0,
  ]),

  // ── 10. Float — soft lifted pastels, dreamy ───────────────────────────
  VybeFilter('Float', '🫧', [
    0.88, 0.12, 0.08, 0, 45,
    0.05, 0.88, 0.12, 0, 32,
    0.05, 0.05, 1.00, 0, 42,
    0,    0,    0,    1,  0,
  ]),

  // ── 11. Blush — warm soft pink ────────────────────────────────────────
  VybeFilter('Blush', '🌸', [
    1.25, 0.10, 0,    0, 18,
    0,    0.95, 0.05, 0,  5,
    0,    0,    0.75, 0,  0,
    0,    0,    0,    1,  0,
  ]),

  // ── 12. Vybe — the signature brand filter ─────────────────────────────
  VybeFilter('Vybe', '💜', [
    1.10, 0,    0.22, 0, 12,
    0,    0.78, 0,    0,  0,
    0.22, 0,    1.25, 0, 15,
    0,    0,    0,    1,  0,
  ]),

  // ── 13. Relic — timeless warm tone ───────────────────────────────────
  VybeFilter('Relic', '📜', [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0,     0,     0,     1, 0,
  ]),
];
