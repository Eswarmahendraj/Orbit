import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ── StorageService ─────────────────────────────────────────────────────────────
// Wraps Firebase Cloud Storage uploads with progress tracking.
//
// Paths used:
//   profile_photos/{uid}/avatar.jpg   — user profile photo
//   moments/{uid}/{momentId}.jpg/mp4  — moment media
//   campfire/{campfireId}/{fileId}    — campfire media

class StorageService {
  static final StorageService _i = StorageService._();
  factory StorageService() => _i;
  StorageService._();

  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Upload profile photo ───────────────────────────────────────────────────
  // Returns the public download URL, or null on failure.
  // [onProgress] receives 0.0–1.0.

  Future<String?> uploadProfilePhoto(
    File file, {
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) return null;
    final uid = _uid;
    if (uid == null) return null;

    try {
      final ref = _storage.ref('profile_photos/$uid/avatar.jpg');
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      await task;
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  // ── Web-safe upload using raw bytes (works on all platforms) ─────────────
  Future<String?> uploadProfilePhotoBytes(
    Uint8List bytes, {
    String contentType = 'image/jpeg',
    void Function(double)? onProgress,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final ref = _storage.ref('profile_photos/$uid/avatar.jpg');
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Upload moment media (photo or video) ──────────────────────────────────

  Future<String?> uploadMomentMedia(
    File file,
    String momentId, {
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) return null;
    final uid = _uid;
    if (uid == null) return null;

    final ext = file.path.split('.').last.toLowerCase();
    final contentType = ['mp4', 'mov', 'avi'].contains(ext)
        ? 'video/mp4'
        : 'image/jpeg';

    try {
      final ref = _storage.ref('moments/$uid/$momentId.$ext');
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Upload campfire media ──────────────────────────────────────────────────

  Future<String?> uploadCampfireMedia(
    File file,
    String campfireId,
    String fileId, {
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) return null;
    final uid = _uid;
    if (uid == null) return null;

    final ext = file.path.split('.').last.toLowerCase();
    try {
      final ref = _storage.ref('campfire/$campfireId/$fileId.$ext');
      final task = ref.putFile(file);

      if (onProgress != null) {
        task.snapshotEvents.listen((snap) {
          if (snap.totalBytes > 0) {
            onProgress(snap.bytesTransferred / snap.totalBytes);
          }
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Delete a file by its download URL ────────────────────────────────────

  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }
}
