import 'package:audioplayers/audioplayers.dart';

/// Handles AURA's sound-only notification system.
/// No banners, no pop-ups, no badges — just the AURA tone.
/// Note: Firebase Messaging stub — add firebase_messaging to pubspec to enable.
class NotificationService {
  static final _player = AudioPlayer();

  static Future<void> init() async {
    // TODO: initialize firebase_messaging when added to pubspec
  }

  /// Play the AURA ambient notification tone.
  /// soundType: 'default' | 'birthday' | 'pulse' | 'nudge' | 'milestone'
  static Future<void> _playAuraSound(String soundType) async {
    final soundMap = {
      'default':   'sounds/aura_tone.mp3',
      'birthday':  'sounds/aura_birthday.mp3',
      'pulse':     'sounds/aura_pulse.mp3',
      'nudge':     'sounds/aura_nudge.mp3',
      'milestone': 'sounds/aura_milestone.mp3',
    };
    final sound = soundMap[soundType] ?? soundMap['default']!;
    await _player.play(AssetSource(sound));
  }

  /// Manually trigger a test sound (for settings preview)
  static Future<void> previewSound() async {
    await _playAuraSound('default');
  }

  /// FCM payload structure for backend reference:
  /// {
  ///   "to": "<fcm_token>",
  ///   "data": { "soundType": "pulse" | "birthday" | "nudge" | "milestone" | "default" },
  ///   "android": { "priority": "normal" }
  /// }
  static Map<String, dynamic> buildPayload({
    required String fcmToken,
    required String soundType,
    Map<String, String>? extraData,
  }) => {
    'to': fcmToken,
    'data': {
      'soundType': soundType,
      ...?extraData,
    },
    'android': {'priority': 'normal'},
  };
}
