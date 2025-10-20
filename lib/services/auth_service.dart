import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      // Step 1: Authenticate user
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) throw Exception('Failed to retrieve user');

      // Step 2: Look up Firestore user document
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('User record not found in Firestorez :p');
      }

      // Step 3: Extract role (or privilege field)
      final data = userDoc.data() as Map<String, dynamic>;
      final role = data['role'] ?? 'user';

      // Step 4: Return both user and role
      return {
        'user': user,
        'role': role,
      };

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
