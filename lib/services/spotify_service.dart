import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Spotify Service (PKCE OAuth, no secret needed) ────────────────────────────

class SpotifyService {
  static final SpotifyService _i = SpotifyService._();
  factory SpotifyService() => _i;
  SpotifyService._();

  static const _clientId = '646b3fefc3ec4e9488ebaae076159dc6';
  static const _redirectUri = 'orbit://callback';
  static const _scopes = [
    'user-read-currently-playing',
    'user-read-playback-state',
    'user-read-recently-played',
    'user-top-read',
    'user-library-read',
  ];

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  bool get isConnected => _accessToken != null;

  // ── Load persisted tokens ─────────────────────────────────────────────────

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _accessToken = p.getString('spotify_access_token');
    _refreshToken = p.getString('spotify_refresh_token');
    final exp = p.getString('spotify_expires_at');
    if (exp != null) _expiresAt = DateTime.tryParse(exp);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    if (_accessToken != null) await p.setString('spotify_access_token', _accessToken!);
    if (_refreshToken != null) await p.setString('spotify_refresh_token', _refreshToken!);
    if (_expiresAt != null) await p.setString('spotify_expires_at', _expiresAt!.toIso8601String());
  }

  Future<void> disconnect() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('spotify_access_token');
    await p.remove('spotify_refresh_token');
    await p.remove('spotify_expires_at');
  }

  // ── PKCE helpers ──────────────────────────────────────────────────────────

  String _generateCodeVerifier() {
    final rand = Random.secure();
    final bytes = List<int>.generate(96, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  // ── Auth flow ─────────────────────────────────────────────────────────────

  Future<bool> connect() async {
    // Custom URI schemes (orbit://) don't work in browsers.
    // Spotify connection is available on Android and iOS only.
    if (kIsWeb) return false;
    try {
      final verifier = _generateCodeVerifier();
      final challenge = _generateCodeChallenge(verifier);
      final state = base64UrlEncode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));

      final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
        'client_id': _clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': challenge,
        'state': state,
        'scope': _scopes.join(' '),
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'orbit',
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      if (code == null) return false;

      // Exchange code for tokens
      final tokenRes = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': verifier,
        },
      );

      if (tokenRes.statusCode == 200) {
        final data = jsonDecode(tokenRes.body);
        _accessToken = data['access_token'] as String;
        _refreshToken = data['refresh_token'] as String?;
        _expiresAt = DateTime.now().add(Duration(seconds: data['expires_in'] as int));
        await _save();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Token refresh ─────────────────────────────────────────────────────────

  Future<bool> _ensureToken() async {
    if (_accessToken == null) return false;
    if (_expiresAt != null && DateTime.now().isAfter(_expiresAt!.subtract(const Duration(minutes: 2)))) {
      return _refresh();
    }
    return true;
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': _clientId,
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _accessToken = data['access_token'] as String;
        if (data['refresh_token'] != null) _refreshToken = data['refresh_token'] as String;
        _expiresAt = DateTime.now().add(Duration(seconds: data['expires_in'] as int));
        await _save();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getNowPlaying() async {
    if (!await _ensureToken()) return null;
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final item = data['item'] as Map<String, dynamic>?;
        if (item == null) return null;
        final artists = (item['artists'] as List?)
            ?.map((a) => a['name'] as String)
            .join(', ') ?? '';
        final album = item['album'] as Map<String, dynamic>?;
        final artUrl = (album?['images'] as List?)?.isNotEmpty == true
            ? (album!['images'] as List).first['url'] as String?
            : null;
        return {
          'song': item['name'] as String,
          'artist': artists,
          'artUrl': artUrl,
          'previewUrl': item['preview_url'] as String?,
          'spotifyUrl': (item['external_urls'] as Map?)?['spotify'] as String?,
          'isPlaying': data['is_playing'] as bool? ?? false,
          'progressMs': data['progress_ms'] as int? ?? 0,
          'durationMs': item['duration_ms'] as int? ?? 0,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (!await _ensureToken()) return [];
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('https://api.spotify.com/v1/search').replace(
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': '10',
          'market': 'IN',
        },
      );
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $_accessToken'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tracks = (data['tracks']['items'] as List)
            .where((t) => t != null)
            .map<Map<String, dynamic>>((t) {
          final artists = (t['artists'] as List)
              .map((a) => a['name'] as String)
              .join(', ');
          final album = t['album'] as Map<String, dynamic>;
          final images = album['images'] as List?;
          return {
            'song': t['name'] as String,
            'artist': artists,
            'artUrl': images?.isNotEmpty == true ? images!.first['url'] as String? : null,
            'previewUrl': t['preview_url'] as String?,
            'spotifyUrl': (t['external_urls'] as Map?)?['spotify'] as String?,
            'durationMs': t['duration_ms'] as int? ?? 0,
          };
        }).toList();
        return tracks;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopTracks({int limit = 20}) async {
    if (!await _ensureToken()) return [];
    try {
      final res = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/top/tracks?limit=$limit&time_range=short_term'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['items'] as List).map<Map<String, dynamic>>((t) {
          final artists = (t['artists'] as List).map((a) => a['name'] as String).join(', ');
          return {
            'song': t['name'] as String,
            'artist': artists,
            'genres': <String>[],
          };
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Compute a simple compatibility score (0–100) between two track lists
  int compatibilityScore(List<Map<String, dynamic>> myTracks, List<String> theirTags) {
    if (myTracks.isEmpty || theirTags.isEmpty) return 50;
    final myArtists = myTracks.map((t) => (t['artist'] as String).toLowerCase()).toSet();
    final theirLower = theirTags.map((t) => t.toLowerCase()).toSet();
    final shared = myArtists.intersection(theirLower).length;
    return (50 + shared * 8).clamp(30, 98);
  }
}
