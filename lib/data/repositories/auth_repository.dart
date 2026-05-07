import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => auth.signOut();
}
