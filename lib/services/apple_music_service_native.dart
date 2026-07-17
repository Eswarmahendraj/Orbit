import 'dart:io';

// music_kit 1.3.0 — API changed significantly from earlier versions.
// nowPlayingItem / playbackState removed; sealed auth status classes.
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
      // MusicAuthorizationStatus is a sealed class in 1.3.0 — check via toString
      _authorized = status.toString().contains('authorized');
    } catch (_) {}
  }

  // ── Request permission ─────────────────────────────────────────────────────

  Future<bool> authorize() async {
    if (!isSupported) return false;
    try {
      final status = await _kit.requestAuthorizationStatus();
      _authorized = status.toString().contains('authorized');
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  // ── Now Playing ────────────────────────────────────────────────────────────
  // music_kit 1.3.0 removed nowPlayingItem — returns null (no song info API).
  // The UI will fall back to "Connect Apple Music" state gracefully.

  Future<Map<String, dynamic>?> getNowPlaying() async => null;

  // ── Stream: player state changes ──────────────────────────────────────────

  Stream<Map<String, dynamic>?> get nowPlayingStream async* {
    if (!isAuthorized) return;
    try {
      await for (final state in _kit.onMusicPlayerStateChanged) {
        final isPlaying = state.playbackStatus.toString().contains('playing');
        yield {'isPlaying': isPlaying};
      }
    } catch (_) {}
  }

  void disconnect() {
    _authorized = false;
  }
}
