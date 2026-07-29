import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result models
// ─────────────────────────────────────────────────────────────────────────────

class VibeResult {
  final String label;
  final String emoji;
  final String description;
  final String color;      // hex string e.g. "#7C3AED"
  final List<String> tracks;

  const VibeResult({
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
    required this.tracks,
  });

  factory VibeResult.fromJson(Map<String, dynamic> j) => VibeResult(
    label:       j['label'] as String? ?? 'mystery vibe',
    emoji:       j['emoji'] as String? ?? '✨',
    description: j['description'] as String? ?? '',
    color:       j['color'] as String? ?? '#7C3AED',
    tracks:      List<String>.from(j['tracks'] as List? ?? []),
  );

  // Fallback when API is unconfigured
  static VibeResult fallback(List<String> moodTags, String freeText) => VibeResult(
    label: 'night shift philosopher',
    emoji: '🌙',
    description: 'Big thoughts, heavy playlists. You find meaning in music that hits at 3am when the world is quiet.',
    color: '#4F8EFF',
    tracks: ['Blinding Lights — The Weeknd', 'Video Games — Lana Del Rey', 'A Case of You — Joni Mitchell'],
  );
}

class CaptionResult {
  final List<String> captions;
  final List<String> hashtags;

  const CaptionResult({required this.captions, required this.hashtags});

  factory CaptionResult.fromJson(Map<String, dynamic> j) => CaptionResult(
    captions: List<String>.from(j['captions'] as List? ?? []),
    hashtags: List<String>.from(j['hashtags'] as List? ?? []),
  );

  static CaptionResult fallback(String song, String artist) => CaptionResult(
    captions: [
      '${song} has me in a chokehold rn 🎵',
      'can\'t stop won\'t stop • ${artist} understood the assignment',
      'this song lives in my head rent-free and I am NOT complaining',
    ],
    hashtags: ['#${song.replaceAll(' ', '').toLowerCase()}', '#${artist.replaceAll(' ', '').toLowerCase()}', '#orbit', '#nowplaying', '#vibes'],
  );
}

class PlaylistResult {
  final String moodLabel;
  final String emoji;
  final String description;
  final String playlistName;
  final String vibeSummary;
  final List<String> tracks;

  const PlaylistResult({
    required this.moodLabel,
    required this.emoji,
    required this.description,
    required this.playlistName,
    required this.vibeSummary,
    required this.tracks,
  });

  factory PlaylistResult.fromJson(Map<String, dynamic> j) => PlaylistResult(
    moodLabel:    j['mood_label'] as String? ?? 'lost in sound',
    emoji:        j['emoji'] as String? ?? '🎵',
    description:  j['description'] as String? ?? '',
    playlistName: j['playlist_name'] as String? ?? 'Orbit Mix',
    vibeSummary:  j['vibe_summary'] as String? ?? '',
    tracks:       List<String>.from(j['tracks'] as List? ?? []),
  );

  static PlaylistResult fallback(String spokenText) => PlaylistResult(
    moodLabel: 'mystery frequency',
    emoji: '🌀',
    description: 'Your vibe is its own genre. Here\'s something that might resonate.',
    playlistName: 'Uncharted Territory',
    vibeSummary: 'A mix that matches your signal.',
    tracks: [
      'Golden Hour — JVKE',
      'luther — Kendrick Lamar & SZA',
      'Espresso — Sabrina Carpenter',
      'As It Was — Harry Styles',
      'Blinding Lights — The Weeknd',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AiService — all Claude API calls
// ─────────────────────────────────────────────────────────────────────────────

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // ── Low-level Claude call ─────────────────────────────────────────────────

  Future<String?> _call(String prompt, {int maxTokens = 1024}) async {
    if (!ApiConfig.isConfigured) return null;

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.claudeApiUrl),
        headers: {
          'x-api-key':         ApiConfig.claudeApiKey,
          'anthropic-version': ApiConfig.claudeApiVersion,
          'content-type':      'application/json',
        },
        body: jsonEncode({
          'model':      ApiConfig.claudeModel,
          'max_tokens': maxTokens,
          'messages':   [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final content = data['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return (content.first as Map)['text'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extract the first JSON object from a text that may contain extra prose
  Map<String, dynamic>? _extractJson(String? text) {
    if (text == null) return null;
    // Find the outermost { ... } block
    final start = text.indexOf('{');
    final end   = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    try {
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Vibe Check ────────────────────────────────────────────────────────────

  /// [moodTags] selected mood keywords. [freeText] optional typed description.
  Future<VibeResult> analyzeVibe({
    required List<String> moodTags,
    String freeText = '',
  }) async {
    final moodLine = moodTags.isNotEmpty
        ? 'Selected mood tags: ${moodTags.join(', ')}.'
        : '';
    final textLine = freeText.isNotEmpty
        ? 'User described their feeling as: "$freeText".'
        : '';

    final prompt = '''
You are the personality engine behind Orbit, a Gen Z music social app.

$moodLine
$textLine

Based on this, return a JSON object (and ONLY the JSON, no other text) with:
- "label": a fun Gen Z music personality label, 2-4 words, all lowercase (e.g. "dark academia girlie", "hyperpop menace", "main character syndrome")
- "emoji": one emoji that represents this vibe perfectly
- "description": 2-3 sentences in a witty, relatable Gen Z tone describing this musical personality type
- "color": a hex color string that represents this vibe (e.g. "#7C3AED")
- "tracks": an array of exactly 3 song suggestions in the format "Song Title — Artist Name" that would perfectly fit this vibe

Example format:
{"label":"night owl romantic","emoji":"🌙","description":"...","color":"#4F8EFF","tracks":["Song — Artist","Song — Artist","Song — Artist"]}
''';

    final raw = await _call(prompt, maxTokens: 512);
    final json = _extractJson(raw);
    if (json != null) {
      try { return VibeResult.fromJson(json); } catch (_) {}
    }
    return VibeResult.fallback(moodTags, freeText);
  }

  // ── AI Caption for Drops ──────────────────────────────────────────────────

  Future<CaptionResult> suggestCaption({
    required String song,
    required String artist,
  }) async {
    final prompt = '''
You are the content brain behind Orbit, a Gen Z music social app.

A user is posting a short video Drop about the song "$song" by "$artist".

Return ONLY a JSON object with:
- "captions": an array of exactly 3 short, authentic, Gen Z-style captions for this song post. Use emojis. Keep each under 90 characters. Make them feel real, not corporate. Mix styles: one emotional, one hype, one ironic/funny.
- "hashtags": an array of 5 relevant hashtags starting with # (include the song name, artist, and relevant vibe tags)

Example format:
{"captions":["...","...","..."],"hashtags":["#tag1","#tag2","#tag3","#tag4","#tag5"]}
''';

    final raw = await _call(prompt, maxTokens: 400);
    final json = _extractJson(raw);
    if (json != null) {
      try { return CaptionResult.fromJson(json); } catch (_) {}
    }
    return CaptionResult.fallback(song, artist);
  }

  // ── Meme Text Suggest ────────────────────────────────────────────────────

  /// Returns {top, bottom} meme text generated from a song.
  Future<({String top, String bottom})> suggestMemeText({
    required String song,
    required String artist,
  }) async {
    final prompt = '''
You are a meme genius behind Orbit, a Gen Z music social app.

A user is making a meme about the song "$song" by "$artist".

Write funny, relatable meme text in two parts that captures the vibe of this song:
- "top": the setup line (5-8 words, Gen Z humor, relatable, lowercase)
- "bottom": the punchline that completes the joke (5-8 words, lowercase)

Return ONLY a JSON object, nothing else:
{"top":"...","bottom":"..."}

Make it genuinely funny and specific to the song's vibe. No corporate cringe.
''';

    final raw = await _call(prompt, maxTokens: 200);
    final json = _extractJson(raw);
    if (json != null) {
      try {
        return (
          top:    (json['top']    as String? ?? '').toLowerCase(),
          bottom: (json['bottom'] as String? ?? '').toLowerCase(),
        );
      } catch (_) {}
    }
    return (
      top:    'when $song comes on',
      bottom: 'and you forget every problem',
    );
  }

  // ── Voice → Playlist ──────────────────────────────────────────────────────

  Future<PlaylistResult> voiceToPlaylist(String spokenText) async {
    if (spokenText.trim().isEmpty) return PlaylistResult.fallback(spokenText);

    final prompt = '''
You are the AI DJ behind Orbit, a Gen Z music social app.

A user described how they're feeling right now: "$spokenText"

Read between the lines. Understand the emotional subtext. Then return ONLY a JSON object with:
- "mood_label": a creative Gen Z label for this emotional state (2-4 words, lowercase)
- "emoji": one emoji that captures this feeling
- "description": 1-2 sentences empathetically capturing their vibe
- "playlist_name": a creative, evocative playlist name (not generic)
- "vibe_summary": one sentence describing the sound of this playlist
- "tracks": array of exactly 8 song suggestions in format "Song Title — Artist Name" that perfectly match this emotional state. Mix popular and deep cuts.

Return only the JSON, nothing else.
''';

    final raw = await _call(prompt, maxTokens: 700);
    final json = _extractJson(raw);
    if (json != null) {
      try { return PlaylistResult.fromJson(json); } catch (_) {}
    }
    return PlaylistResult.fallback(spokenText);
  }
}
