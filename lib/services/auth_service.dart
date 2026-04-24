import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if a username is already taken
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // Sign Up with Unique Username Enforcement
  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String country,
  }) async {
    try {
      final uname = username.toLowerCase();
      
      // 1. Pre-check availability
      if (!await isUsernameAvailable(uname)) {
        throw "Username already taken";
      }

      // 2. Create Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 3. Create Firestore Profile with timestamp for tie-breaking
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'username': uname,
          'email': email,
          'country': country,
          'xp': 0,
          'level': 1,
          'lastCompletionTimestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow;
    }
  }

  // Login with Username lookup
  Future<User?> login({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Find email by username
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw "Username not found";
      }

      String email = query.docs.first.get('email');

      // 2. Sign in with email
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user stream
  Stream<User?> get user => _auth.authStateChanges();
}
