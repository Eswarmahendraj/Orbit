import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles AURA's sound-only notification system.
/// No banners, no pop-ups, no badges — just the AURA tone.
class NotificationService {
  static final _player = AudioPlayer();
  static final _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Request permission (Android 13+)
    await _fcm.requestPermission(
      alert: false,   // No visual alerts
      badge: false,   // No badge count
      sound: true,    // Sound only
    );

    // Get FCM token and save to Firestore
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);

    // Refresh token
    _fcm.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages — play sound only, no notification UI
    FirebaseMessaging.onMessage.listen((msg) async {
      await _playAuraSound(msg.data['soundType'] ?? 'default');
    });

    // Background/terminated handled by FCM natively
    // We configure it to be silent-push (no visual) in AndroidManifest
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': token,
    });
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

  /// Send a push notification to a user (server-side call via Cloud Functions)
  /// This method documents the payload structure for your backend.
  ///
  /// FCM payload:
  /// {
  ///   "to": "<fcm_token>",
  ///   "data": {
  ///     "soundType": "pulse" | "birthday" | "nudge" | "milestone" | "default"
  ///   },
  ///   "android": {
  ///     "priority": "normal",
  ///     "notification": null   // No visual notification
  ///   }
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
    // No 'notification' key = silent push, sound handled in-app
  };
}
