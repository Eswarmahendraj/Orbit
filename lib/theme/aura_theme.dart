import 'package:flutter/material.dart';

// Convenience alias used by login / signup screens
class AuraColors {
  static const Color accent = AuraTheme.accent;
  static const Color textSecondary = AuraTheme.textSecondary;
  static const Color textPrimary = AuraTheme.textPrimary;
  static const Color surface = AuraTheme.surface;
  static const Color background = AuraTheme.background;
  static const Color card = AuraTheme.card;
  static const Color cyan = AuraTheme.cyan;
  static const Color pink = AuraTheme.pink;

  // Mood colors — vivid for dark bg
  static const Color moodCalm   = Color(0xFF38BDF8); // electric sky blue
  static const Color moodHappy  = Color(0xFFFFD60A); // vivid yellow
  static const Color moodEnergy = Color(0xFFFF4757); // neon red-pink
  static const Color moodFocus  = Color(0xFF2ECC71); // electric green
  static const Color moodSad    = Color(0xFF818CF8); // lavender indigo

  static const Color divider = Color(0xFF1E1E30);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080810), Color(0xFF0D0B1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [AuraTheme.accent, AuraTheme.accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AuraTheme {
  // ── Dark mode flag ────────────────────────────────────────────
  static bool isDark = true; // dark-first

  // ── Core palette — deep orbit dark (used as const refs everywhere) ──
  static const Color background  = Color(0xFF080810); // deep space
  static const Color card        = Color(0xFF0F0F1E); // dark card
  static const Color surface     = Color(0xFF161628); // interactive surface
  static const Color accent      = Color(0xFFFF6B00); // electric orange
  static const Color accentLight = Color(0xFFFF9640); // warm glow orange

  // Secondary accent palette
  static const Color purple   = Color(0xFF7C3AED); // orbit purple
  static const Color purpleLight = Color(0xFFA855F7);
  static const Color orange   = accent;
  static const Color pink     = Color(0xFFEC4899); // hot pink
  static const Color cyan     = Color(0xFF22D3EE); // space cyan
  static const Color green    = Color(0xFF10B981); // mint

  // Text — cool-toned for dark bg
  static const Color textPrimary   = Color(0xFFF2F0FA); // icy white
  static const Color textSecondary = Color(0xFF8A88AA); // cool gray-purple
  static const Color textMuted     = Color(0xFF4A4870); // muted indigo

  // ── Gradient helpers ──────────────────────────────────────────
  static const List<Color> brandGradient  = [accent, accentLight];
  static const List<Color> vibeGradient   = [accent, purple, cyan];
  static const List<Color> purpleGradient = [purple, purpleLight];
  static const List<Color> darkGradient   = [Color(0xFF0F0F1E), Color(0xFF080810)];

  // Glow shadow for glowing effects
  static List<BoxShadow> glowShadow({Color? color, double radius = 18, double opacity = 0.45}) => [
    BoxShadow(
      color: (color ?? accent).withOpacity(opacity),
      blurRadius: radius,
      spreadRadius: radius * 0.2,
    ),
  ];

  // ── Theme-aware dynamic getters ───────────────────────────────
  static Color get themeBg            => background;
  static Color get themeCard          => card;
  static Color get themeSurface       => surface;
  static Color get themeTextPrimary   => textPrimary;
  static Color get themeTextSecondary => textSecondary;
  static Color get themeTextMuted     => textMuted;
  static Color get themeDivider       => const Color(0xFF1E1E30);
  static Color get themeNavBar        => const Color(0xFF0A0A18);

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get light => dark; // alias

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: purple,
      tertiary: cyan,
      surface: card,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0A0A18),
      indicatorColor: accent.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700);
        }
        return const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accent, size: 24);
        }
        return const IconThemeData(color: textMuted, size: 24);
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0A0A18),
      selectedItemColor: accent,
      unselectedItemColor: textMuted,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent.withOpacity(0.2),
      labelStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: accent),
      checkmarkColor: accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: Color(0xFF1E1E30)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E1E30)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E1E30)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF1E1E30),
      thickness: 0.5,
    ),
    iconTheme: const IconThemeData(color: textPrimary),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w800, fontSize: 34,
          letterSpacing: -1.0),
      displayMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w800, fontSize: 28,
          letterSpacing: -0.8),
      headlineLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w800, fontSize: 24,
          letterSpacing: -0.5),
      headlineMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20,
          letterSpacing: -0.3),
      titleLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18,
          letterSpacing: -0.2),
      titleMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: textMuted, fontSize: 12),
      labelLarge: TextStyle(
          color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(
          color: textMuted, fontSize: 11, fontWeight: FontWeight.w500,
          letterSpacing: 0.5),
    ),
  );

  // Keep darkTheme as an alias for consistency
  static ThemeData get darkTheme => dark;
}
