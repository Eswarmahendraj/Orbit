import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Email Sign Up ──────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createUserDoc(cred.user!.uid, name: name, email: email);
    return cred;
  }

  // ── Phone Sign Up ──────────────────────────────────────────
  Future<void> sendOtp({
    required String phone,
    required Function(PhoneAuthCredential) onAutoVerified,
    required Function(String, int?) onCodeSent,
    required Function(FirebaseAuthException) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: onAutoVerified,
      verificationFailed: onError,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
    required String name,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    final cred = await _auth.signInWithCredential(credential);
    if (cred.additionalUserInfo?.isNewUser == true) {
      await _createUserDoc(cred.user!.uid,
          name: name, phone: cred.user!.phoneNumber);
    }
    return cred;
  }

  // ── Email Sign In ──────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    await _setOnlineStatus(false);
    await _auth.signOut();
  }

  // ── Create Firestore user document ────────────────────────
  Future<void> _createUserDoc(String uid,
      {required String name, String? email, String? phone}) async {
    final auraName = _generateAuraName();
    await _db.collection('users').doc(uid).set({
      'name': name,
      'auraName': auraName,
      'email': email,
      'phone': phone,
      'photoUrl': null,
      'interests': [],
      'currentMood': 'calm',
      'auraColor': 0xFF6C63FF,
      'spotifyTrack': null,
      'isOnline': true,
      'birthday': null,
      'rootedConnections': [],
      'closeCircle': [],
      'showLikesCount': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid)
          .update({'isOnline': isOnline});
    }
  }

  // ── Generate unique ambient Aura name ─────────────────────
  String _generateAuraName() {
    const adjectives = [
      'Midnight', 'Silver', 'Amber', 'Velvet', 'Neon',
      'Hollow', 'Quiet', 'Golden', 'Misty', 'Cosmic',
      'Deep', 'Pale', 'Azure', 'Crimson', 'Ivory',
    ];
    const nouns = [
      'Birch', 'Echo', 'Drift', 'Pulse', 'Glow',
      'Ember', 'Tide', 'Bloom', 'Storm', 'Haze',
      'Wisp', 'Flare', 'Shore', 'Spark', 'Veil',
    ];
    adjectives.shuffle();
    nouns.shuffle();
    return '${adjectives.first} ${nouns.first}';
  }
}
