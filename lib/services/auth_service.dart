// Auth service — UI stub (no Firebase SDK required)
// Real Firebase integration will be added when firebase_auth is in pubspec.yaml

class AuthService {
  // ── Email Sign Up ──────────────────────────────────────────
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // TODO: implement with firebase_auth
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ── Phone OTP ─────────────────────────────────────────────
  Future<void> sendOtp({
    required String phone,
    required Function(dynamic) onAutoVerified,
    required Function(String, int?) onCodeSent,
    required Function(dynamic) onError,
  }) async {
    // TODO: implement with firebase_auth
    await Future.delayed(const Duration(milliseconds: 500));
    onCodeSent('demo-verification-id', null);
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
    required String name,
  }) async {
    // TODO: implement with firebase_auth
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ── Email Sign In ──────────────────────────────────────────
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: implement with firebase_auth
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
