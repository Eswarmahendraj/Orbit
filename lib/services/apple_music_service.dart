// ── Apple Music Service ───────────────────────────────────────────────────────
// Conditionally exports the native implementation (Android + iOS) on mobile,
// and a no-op stub on web (dart:io and music_kit are unavailable on web).
export 'apple_music_service_native.dart'
    if (dart.library.html) 'apple_music_service_web.dart';
