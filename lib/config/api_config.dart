// ─────────────────────────────────────────────────────────────────────────────
// Orbit AI — Claude API Configuration
//
// 1. Go to https://console.anthropic.com
// 2. Create a free account and get your API key
// 3. Replace 'YOUR_CLAUDE_API_KEY_HERE' below with your actual key
//
// ⚠️  Never commit your real API key to a public repo.
//     For production, load this from a secure backend or environment variable.
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  /// Your Claude API key from https://console.anthropic.com
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY_HERE';

  /// Using Haiku — fastest and most cost-efficient Claude model
  static const String claudeModel = 'claude-haiku-4-5-20251001';

  /// Claude Messages API endpoint
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';

  /// Anthropic API version header
  static const String claudeApiVersion = '2023-06-01';

  /// Returns true if the API key has been configured
  static bool get isConfigured =>
      claudeApiKey.isNotEmpty && claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
}
