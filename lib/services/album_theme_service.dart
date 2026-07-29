import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlbumThemeService
//
// Extracts a vibrant/dominant color from an album art URL and caches it
// in memory so repeated lookups are instant.
// ─────────────────────────────────────────────────────────────────────────────

class AlbumThemeService {
  AlbumThemeService._();

  // In-memory LRU-style cache (URL → Color)
  static final _cache = <String, Color>{};

  static const _fallback = Color(0xFF7C3AED); // Orbit purple

  /// Returns the extracted vibrant/dominant color for [imageUrl].
  /// Falls back to [fallback] (or Orbit purple) if extraction fails.
  static Future<Color> extractColor(
    String? imageUrl, {
    Color? fallback,
  }) async {
    final fb = fallback ?? _fallback;
    if (imageUrl == null || imageUrl.isEmpty) return fb;

    if (_cache.containsKey(imageUrl)) return _cache[imageUrl]!;

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(150, 150),
      ).timeout(const Duration(seconds: 4));

      final color = generator.vibrantColor?.color ??
          generator.mutedColor?.color ??
          generator.dominantColor?.color ??
          fb;

      // Ensure it's not too dark (min luminance 0.08) to show on dark UI
      final hsl = HSLColor.fromColor(color);
      final adjusted = hsl.lightness < 0.25
          ? hsl.withLightness(0.4).toColor()
          : color;

      _cache[imageUrl] = adjusted;
      return adjusted;
    } catch (_) {
      return fb;
    }
  }

  /// Clears the cache (call on logout / low-memory events).
  static void clearCache() => _cache.clear();
}
