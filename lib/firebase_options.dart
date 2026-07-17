import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // reuse iOS config for macOS (same bundle)
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA-qXcXK9ujcMkSf0-91pAmuy5IVXhUqI8',
    appId: '1:500091326393:web:cf47d49588b8ccb5',
    messagingSenderId: '500091326393',
    projectId: 'aura-4e337',
    authDomain: 'aura-4e337.firebaseapp.com',
    storageBucket: 'aura-4e337.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDq33tHMpg-Bi-Ertbw9MG3XZNB-Q7fd4I',
    appId: '1:500091326393:android:6c856ad5eee745718eb068',
    messagingSenderId: '500091326393',
    projectId: 'aura-4e337',
    storageBucket: 'aura-4e337.appspot.com',
  );

  // ── iOS ──────────────────────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDq33tHMpg-Bi-Ertbw9MG3XZNB-Q7fd4I',
    appId: '1:500091326393:ios:20cc2452f27936008eb068',
    messagingSenderId: '500091326393',
    projectId: 'aura-4e337',
    storageBucket: 'aura-4e337.appspot.com',
    iosBundleId: 'com.orbit.app',
  );
}
