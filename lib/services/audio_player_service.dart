import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton audio player — ONE instance shared across all screens.
///
/// This prevents songs from overlapping when navigating between tabs and
/// ensures audio stops when the app goes to background / is closed.
///
/// Usage:
///   await AudioPlayerService.i.play(url);       // stops anything playing first
///   await AudioPlayerService.i.pause();
///   await AudioPlayerService.i.resume();
///   AudioPlayerService.i.stopIfOwner(myKey);    // stop only if you started it
///   AudioPlayerService.i.player                 // raw player for stream listening
class AudioPlayerService with WidgetsBindingObserver {
  AudioPlayerService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final AudioPlayerService i = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  String? _currentOwner;

  AudioPlayer get player => _player;
  String? get currentOwner => _currentOwner;
  bool get isPlaying => _player.playing;

  /// Play [url], stopping whatever was playing before.
  /// [owner] is an optional key so screens can tell if they're still active.
  Future<void> play(String url, {String? owner, bool loop = false}) async {
    try {
      await _player.stop();
      _currentOwner = owner;
      await _player.setUrl(url);
      if (loop) await _player.setLoopMode(LoopMode.one);
      else await _player.setLoopMode(LoopMode.off);
      await _player.play();
    } catch (_) {}
  }

  Future<void> pause() async {
    try { await _player.pause(); } catch (_) {}
  }

  Future<void> resume() async {
    try { await _player.play(); } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _currentOwner = null;
      await _player.stop();
    } catch (_) {}
  }

  /// Stop only if [owner] is the current owner — prevents one screen from
  /// accidentally stopping audio started by another screen.
  Future<void> stopIfOwner(String owner) async {
    if (_currentOwner == owner) await stop();
  }

  bool isOwner(String owner) => _currentOwner == owner;

  // ── App lifecycle: pause audio when app goes to background / closes ────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _player.stop();
      _currentOwner = null;
    }
  }
}
