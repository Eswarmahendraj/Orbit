import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme preset model ────────────────────────────────────────────────────────
class AuraThemePreset {
  final String id;
  final String name;
  final String emoji;
  final String tagline;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color card;
  final Color surface;
  final Color purple;
  final List<Color> gradient; // 2-stop gradient for hero sections
  final Color navBg;

  const AuraThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.card,
    required this.surface,
    required this.purple,
    required this.gradient,
    required this.navBg,
  });
}

// ── All presets ───────────────────────────────────────────────────────────────
class AuraThemePresets {
  static const aura = AuraThemePreset(
    id: 'aura',
    name: 'AURA',
    emoji: '🔥',
    tagline: 'the original',
    accent:      Color(0xFFFF6B00),
    accentLight: Color(0xFFFF9640),
    background:  Color(0xFF080810),
    card:        Color(0xFF0F0F1E),
    surface:     Color(0xFF161628),
    purple:      Color(0xFF7C3AED),
    gradient: [Color(0xFFFF6B00), Color(0xFF7C3AED)],
    navBg:       Color(0xFF0A0A18),
  );

  static const y2k = AuraThemePreset(
    id: 'y2k',
    name: 'Y2K',
    emoji: '💿',
    tagline: 'early internet realness',
    accent:      Color(0xFFFF2D9B),
    accentLight: Color(0xFFFF6EC7),
    background:  Color(0xFF08050F),
    card:        Color(0xFF100820),
    surface:     Color(0xFF1A0F30),
    purple:      Color(0xFF9B30FF),
    gradient: [Color(0xFFFF2D9B), Color(0xFF9B30FF)],
    navBg:       Color(0xFF090611),
  );

  static const vaporwave = AuraThemePreset(
    id: 'vaporwave',
    name: 'Vaporwave',
    emoji: '💜',
    tagline: 'aesthetic dreams',
    accent:      Color(0xFFBF5FFF),
    accentLight: Color(0xFFE090FF),
    background:  Color(0xFF07060F),
    card:        Color(0xFF0E0A1C),
    surface:     Color(0xFF16112C),
    purple:      Color(0xFF5F2FBF),
    gradient: [Color(0xFFBF5FFF), Color(0xFF00F5FF)],
    navBg:       Color(0xFF080614),
  );

  static const darkAcademia = AuraThemePreset(
    id: 'darkacademia',
    name: 'Dark Academia',
    emoji: '📚',
    tagline: 'lit candles, darker thoughts',
    accent:      Color(0xFFD4A843),
    accentLight: Color(0xFFF0C86A),
    background:  Color(0xFF0A0804),
    card:        Color(0xFF141008),
    surface:     Color(0xFF1E1810),
    purple:      Color(0xFF8B4513),
    gradient: [Color(0xFFD4A843), Color(0xFF8B4513)],
    navBg:       Color(0xFF0C0A06),
  );

  static const cottagecore = AuraThemePreset(
    id: 'cottagecore',
    name: 'Cottagecore',
    emoji: '🌿',
    tagline: 'mossy vibes only',
    accent:      Color(0xFF4CAF82),
    accentLight: Color(0xFF7DCFA7),
    background:  Color(0xFF050A07),
    card:        Color(0xFF0A1009),
    surface:     Color(0xFF121A11),
    purple:      Color(0xFF2E7D52),
    gradient: [Color(0xFF4CAF82), Color(0xFF22D3EE)],
    navBg:       Color(0xFF060C07),
  );

  static const midnight = AuraThemePreset(
    id: 'midnight',
    name: 'Midnight',
    emoji: '🌙',
    tagline: 'born at 3am',
    accent:      Color(0xFF4F8EFF),
    accentLight: Color(0xFF7AADFF),
    background:  Color(0xFF03050F),
    card:        Color(0xFF080D1A),
    surface:     Color(0xFF0E1526),
    purple:      Color(0xFF1A3A8F),
    gradient: [Color(0xFF4F8EFF), Color(0xFF7C3AED)],
    navBg:       Color(0xFF050810),
  );

  static const all = [aura, y2k, vaporwave, darkAcademia, cottagecore, midnight];
}

// ── Service ───────────────────────────────────────────────────────────────────
class ThemeService extends ChangeNotifier {
  static final ThemeService _i = ThemeService._();
  factory ThemeService() => _i;
  ThemeService._();

  AuraThemePreset _current = AuraThemePresets.aura;
  AuraThemePreset get current => _current;

  String get id => _current.id;
  Color  get accent      => _current.accent;
  Color  get accentLight => _current.accentLight;
  Color  get background  => _current.background;
  Color  get card        => _current.card;
  Color  get surface     => _current.surface;
  Color  get purple      => _current.purple;
  Color  get navBg       => _current.navBg;
  List<Color> get gradient => _current.gradient;

  void setPreset(AuraThemePreset preset) {
    _current = preset;
    notifyListeners();
    _persist(preset.id);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('appThemeId') ?? 'aura';
    _current = AuraThemePresets.all.firstWhere(
      (t) => t.id == id,
      orElse: () => AuraThemePresets.aura,
    );
    notifyListeners();
  }

  Future<void> _persist(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('appThemeId', id);
  }

  // Full MaterialApp ThemeData for the active preset
  ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _current.background,
    colorScheme: ColorScheme.dark(
      primary:     _current.accent,
      secondary:   _current.purple,
      tertiary:    const Color(0xFF22D3EE),
      surface:     _current.card,
      onPrimary:   Colors.white,
      onSecondary: Colors.white,
      onSurface:   const Color(0xFFF2F0FA),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _current.background,
      foregroundColor: const Color(0xFFF2F0FA),
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFFF2F0FA)),
      titleTextStyle: const TextStyle(
        color: Color(0xFFF2F0FA),
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _current.navBg,
      indicatorColor: _current.accent.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
              color: _current.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700);
        }
        return const TextStyle(
            color: Color(0xFF4A4870),
            fontSize: 11,
            fontWeight: FontWeight.w500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: _current.accent, size: 24);
        }
        return const IconThemeData(color: Color(0xFF4A4870), size: 24);
      }),
    ),
    cardTheme: CardThemeData(
      color: _current.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _current.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _current.surface,
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
        borderSide: BorderSide(color: _current.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF4A4870)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFF2F0FA)),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: Color(0xFFF2F0FA),
          fontWeight: FontWeight.w800,
          fontSize: 34),
      headlineLarge: TextStyle(
          color: Color(0xFFF2F0FA),
          fontWeight: FontWeight.w800,
          fontSize: 24),
      headlineMedium: TextStyle(
          color: Color(0xFFF2F0FA),
          fontWeight: FontWeight.w700,
          fontSize: 20),
      titleLarge: TextStyle(
          color: Color(0xFFF2F0FA),
          fontWeight: FontWeight.w700,
          fontSize: 18),
      bodyLarge: TextStyle(
          color: Color(0xFFF2F0FA), fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(
          color: Color(0xFF8A88AA), fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: Color(0xFF4A4870), fontSize: 12),
    ),
  );
}
