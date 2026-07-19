import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/orbit_state.dart';
import '../screens/home/dm_screen.dart';

// ── Background message handler (top-level, outside any class) ─────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs on Android.
  debugPrint('🔔 [BG] ${message.notification?.title}: ${message.notification?.body}');
}

// Global navigator key so NotificationService can show SnackBars from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── NotificationService ────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  static const _vapidKey =
      'BLbP7XwfptWDBjzJR1UlwUZbpZAPjsrhdRGxElj6h2n844gbo9I72PZ'
      'DSVpypeGckgHgJLPpPnjfSkknkn10QQY';

  // Called once from main() after Firebase.initializeApp
  Future<void> init() async {
    if (!kIsWeb) {
      // Register background handler (mobile only)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }

    // Request permission (iOS asks the user; Android 13+ also needs this)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');

    // Store token in Firestore whenever it refreshes
    await _saveToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveToken());

    // Handle notification tap when app is in foreground (shows a banner)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle tap when app was in background / terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check if app was launched from a notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handlePayload(initial.data);
  }

  Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _fcm.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (token == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔔 Token save error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage msg) {
    debugPrint('🔔 [FG] ${msg.notification?.title}: ${msg.notification?.body}');
    final mode = OrbitState().notifMode;
    if (mode == 'off') return;

    if (mode == 'sound') {
      _playChime();
      return;
    }

    // mode == 'push' (default) — show banner + system sound
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final title = msg.notification?.title ?? '';
    final body = msg.notification?.body ?? '';
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('$title — $body'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
    _playChime();
  }

  Future<void> _playChime() async {
    if (kIsWeb) return; // asset audio not supported on web
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/sounds/pulse_ping.mp3');
      await player.play();
      // Dispose after playback finishes
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      debugPrint('🔔 Chime error: $e');
    }
  }

  void _onMessageOpenedApp(RemoteMessage msg) => _handlePayload(msg.data);

  void _handlePayload(Map<String, dynamic> data) {
    debugPrint('🔔 Tapped notification payload: $data');
    if (data['type'] == 'dm') {
      final senderUid  = data['senderUid']  as String? ?? '';
      final senderName = data['senderName'] as String? ?? 'User';
      // Wait one frame so the navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = navigatorKey.currentState;
        if (nav == null) return;
        nav.push(MaterialPageRoute(
          builder: (_) => _DmScreenProxy(
            targetUid:   senderUid,
            displayName: senderName,
          ),
        ));
      });
    }
  }

  // ── Send a DM notification to another user ──────────────────────────────────
  // Writes a job to /notifications — a Cloud Function (or your backend) reads
  // it and calls the FCM HTTP v1 API to actually push the notification.
  // This avoids exposing your server key in client code.

  Future<void> sendDmNotification({
    required String recipientUid,
    required String senderName,
    required String messageText,
    required String dmId,
  }) async {
    try {
      final tokenSnap = await _db
          .collection('users')
          .doc(recipientUid)
          .collection('tokens')
          .get();

      if (tokenSnap.docs.isEmpty) return;

      final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _db.collection('_notifications').add({
        'to': recipientUid,
        'tokens': tokenSnap.docs.map((d) => d['token'] as String).toList(),
        'title': senderName,
        'body': messageText.length > 80
            ? '${messageText.substring(0, 80)}…'
            : messageText,
        'data': {
          'type': 'dm',
          'dmId': dmId,
          'senderUid': senderUid,
          'senderName': senderName,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      debugPrint('🔔 sendDmNotification error: $e');
    }
  }

  // Re-save token when user signs in (in case they signed in after init)
  Future<void> onUserSignedIn() => _saveToken();
}

// ── Thin proxy: resolves DM screen from notification payload ───────────────────
class _DmScreenProxy extends StatelessWidget {
  final String targetUid;
  final String displayName;
  const _DmScreenProxy({
    required this.targetUid,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return DMScreen(
      username: '@${displayName.toLowerCase().replaceAll(' ', '.')}',
      displayName: displayName,
      targetUid: targetUid,
    );
  }
}
