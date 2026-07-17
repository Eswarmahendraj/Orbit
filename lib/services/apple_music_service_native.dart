import 'dart:io';

// music_kit is iOS-only — guard every call behind Platform.isIOS
// ignore: depend_on_referenced_packages
import 'package:music_kit/music_kit.dart';

// ── Apple Music Service (native: Android + iOS) ───────────────────────────────
// Full functionality on iOS 15+; gracefully returns null/false on Android.

class AppleMusicService {
  static final AppleMusicService _i = AppleMusicService._();
  factory AppleMusicService() => _i;
  AppleMusicService._();

  final _kit = MusicKit();

  bool get isSupported => Platform.isIOS;
  bool _authorized = false;
  bool get isAuthorized => _authorized && isSupported;

  // ── Init: check saved authorization ────────────────────────────────────────

  Future<void> load() async {
    if (!isSupported) return;
    try {
      final status = await _kit.authorizationStatus;
      _authorized = status == MusicAuthorizationStatus.authorized;
    } catch (_) {}
  }

  // ── Request permission ─────────────────────────────────────────────────────

  Future<bool> authorize() async {
    if (!isSupported) return false;
    try {
      final status = await _kit.requestAuthorizationStatus();
      _authorized = status == MusicAuthorizationStatus.authorized;
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  // ── Now Playing ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getNowPlaying() async {
    if (!isAuthorized) return null;
    try {
      final item = await _kit.nowPlayingItem;
      if (item == null) return null;

      final state = await _kit.playbackState;
      final isPlaying = state == MusicPlayerState.playing;

      // Build artwork URL at 300×300
      String? artUrl;
      try {
        artUrl = item.artwork?.url(width: 300, height: 300);
      } catch (_) {}

      return {
        'song': item.title ?? '',
        'artist': item.artistName ?? '',
        'album': item.albumTitle ?? '',
        'artUrl': artUrl,
        'isPlaying': isPlaying,
      };
    } catch (_) {
      return null;
    }
  }

  // ── Stream: live now-playing updates ──────────────────────────────────────

  Stream<Map<String, dynamic>?> get nowPlayingStream async* {
    if (!isAuthorized) return;
    await for (final item in _kit.onNowPlayingItemChanged) {
      if (item == null) {
        yield null;
        continue;
      }
      try {
        final state = await _kit.playbackState;
        String? artUrl;
        try { artUrl = item.artwork?.url(width: 300, height: 300); } catch (_) {}
        yield {
          'song': item.title ?? '',
          'artist': item.artistName ?? '',
          'album': item.albumTitle ?? '',
          'artUrl': artUrl,
          'isPlaying': state == MusicPlayerState.playing,
        };
      } catch (_) {
        yield null;
      }
    }
  }

  void disconnect() {
    _authorized = false;
  }
}
