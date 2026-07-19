import 'dart:io';

// ── Apple Music Service (native stub) ────────────────────────────────────────
// music_kit removed — the 1.3.0 API no longer exposes nowPlayingItem.
// Apple Music features are unavailable until music_kit adds a stable
// now-playing API. All methods are no-ops; isSupported stays false on Android.

class AppleMusicService {
  static final AppleMusicService _i = AppleMusicService._();
  factory AppleMusicService() => _i;
  AppleMusicService._();

  bool get isSupported => Platform.isIOS;
  bool get isAuthorized => false;

  Future<void> load() async {}
  Future<bool> authorize() async => false;
  Future<Map<String, dynamic>?> getNowPlaying() async => null;
  Stream<Map<String, dynamic>?> get nowPlayingStream => const Stream.empty();
  void disconnect() {}
}
