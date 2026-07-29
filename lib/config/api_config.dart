// ─────────────────────────────────────────────────────────────────────────────
// Orbit AI — Claude API Configuration
//
// API key can be set two ways:
//   1. Hard-coded below (for development)
//   2. Entered via Settings → AI Features in the app (saves to SharedPreferences)
//
// Get a free key at https://console.anthropic.com
// ⚠️  Never commit real keys to a public repo.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Hard-coded fallback (replace for development builds)
  static const String _staticKey = 'YOUR_CLAUDE_API_KEY_HERE';

  /// Runtime key loaded from SharedPreferences (set via Settings → AI Features)
  static String? _runtimeKey;

  /// Using Haiku — fastest and most cost-efficient Claude model
  static const String claudeModel = 'claude-haiku-4-5-20251001';

  /// Claude Messages API endpoint
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';

  /// Anthropic API version header
  static const String claudeApiVersion = '2023-06-01';

  /// Returns the active API key (runtime → static fallback)
  static String get claudeApiKey =>
      (_runtimeKey != null && _runtimeKey!.isNotEmpty)
          ? _runtimeKey!
          : _staticKey;

  /// True if any valid key is available
  static bool get isConfigured {
    final key = claudeApiKey;
    return key.isNotEmpty && key != 'YOUR_CLAUDE_API_KEY_HERE';
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  static const _prefKey = 'claude_api_key';

  /// Call once at app startup (in main) to restore a previously saved key.
  static Future<void> loadKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _runtimeKey = prefs.getString(_prefKey);
    } catch (_) {}
  }

  /// Save a new key to SharedPreferences and activate it immediately.
  static Future<void> saveKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key.trim().isEmpty) {
        await prefs.remove(_prefKey);
        _runtimeKey = null;
      } else {
        await prefs.setString(_prefKey, key.trim());
        _runtimeKey = key.trim();
      }
    } catch (_) {}
  }

  /// Remove the saved key (reverts to static fallback).
  static Future<void> clearKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      _runtimeKey = null;
    } catch (_) {}
  }
}
