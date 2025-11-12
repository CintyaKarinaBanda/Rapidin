// ignore_for_file: all
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes (stream)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password is too weak');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with that email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  // Get user token (for API calls if needed)
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
