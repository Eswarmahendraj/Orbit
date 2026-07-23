import 'package:flutter/foundation.dart';

/// Singleton ChangeNotifier that tracks what's currently playing.
/// Spotify / Apple Music integrations call [setTrack] when playback changes.
/// Falls back gracefully to nothing (card shows a "connect music" prompt).
class NowPlayingService extends ChangeNotifier {
  static final NowPlayingService _i = NowPlayingService._();
  factory NowPlayingService() => _i;
  NowPlayingService._();

  String? track;
  String? artist;
  String? artUrl;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  bool get hasTrack => track != null && track!.isNotEmpty;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  void setTrack(
    String newTrack,
    String newArtist, {
    String? newArtUrl,
    Duration? newDuration,
  }) {
    track = newTrack;
    artist = newArtist;
    artUrl = newArtUrl;
    duration = newDuration ?? Duration.zero;
    isPlaying = true;
    notifyListeners();
  }

  void updatePosition(Duration pos) {
    position = pos;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    isPlaying = playing;
    notifyListeners();
  }

  void clear() {
    track = null;
    artist = null;
    artUrl = null;
    isPlaying = false;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
  }

  /// Seed with demo data so UI renders even without music integration.
  void seedDemo() {
    if (hasTrack) return;
    setTrack(
      'Golden Hour',
      'JVKE',
      newDuration: const Duration(minutes: 3, seconds: 20),
    );
  }
}
