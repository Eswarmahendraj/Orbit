import 'package:flutter/material.dart';

class AuraTheme {
  // Core palette
  static const Color background = Color(0xFFF4F0E8); // cream
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF0EBE0);
  static const Color accent = Color(0xFFFF4500); // orange-red
  static const Color accentLight = Color(0xFFFF7A50); // light orange

  // Aliases (all orange now — no lime)
  static const Color orange = accent;
  static const Color pink = accentLight;
  static const Color cyan = Color(0xFFFF6030);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Gradients
  static const List<Color> brandGradient = [accent, accentLight];
  static const List<Color> vibeGradient = [accent, accentLight, accent];

  static ThemeData get dark => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: accent,
          secondary: accentLight,
          surface: background,
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
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: card,
          indicatorColor: accent.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: accent, fontSize: 11, fontWeight: FontWeight.w600);
            }
            return TextStyle(
                color: textMuted, fontSize: 11, fontWeight: FontWeight.w500);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accent, size: 24);
            }
            return const IconThemeData(color: textMuted, size: 24);
          }),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: accent,
          labelStyle:
              const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          checkmarkColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: textMuted),
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w800, fontSize: 32),
          headlineMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, fontSize: 24),
          titleLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
          titleMedium: TextStyle(
              color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          labelSmall: TextStyle(
              color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      );
}
