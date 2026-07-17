// ── Apple Music Service (web stub) ───────────────────────────────────────────
// music_kit and dart:io are not available on web — all methods are no-ops.

class AppleMusicService {
  static final AppleMusicService _i = AppleMusicService._();
  factory AppleMusicService() => _i;
  AppleMusicService._();

  bool get isSupported => false;
  bool get isAuthorized => false;

  Future<void> load() async {}
  Future<bool> authorize() async => false;
  Future<Map<String, dynamic>?> getNowPlaying() async => null;
  Stream<Map<String, dynamic>?> get nowPlayingStream => const Stream.empty();
  void disconnect() {}
}
