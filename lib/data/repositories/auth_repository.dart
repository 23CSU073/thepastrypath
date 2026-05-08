import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthCanceledException implements Exception {
  const AuthCanceledException();

  @override
  String toString() => 'Sign-in cancelled.';
}

class AuthUnsupportedPlatformException implements Exception {
  const AuthUnsupportedPlatformException();

  @override
  String toString() =>
      'Google sign-in is not supported on this platform in this app build.';
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return auth.signInWithPopup(provider);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      default:
        throw const AuthUnsupportedPlatformException();
    }

    final user = await _googleSignIn.signIn();
    if (user == null) throw const AuthCanceledException();

    final googleAuth = await user.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore: sign-out is best-effort for providers.
    }
    await auth.signOut();
  }
}
