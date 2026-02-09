import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin email list
  static const List<String> adminEmails = [
    'cse_0182310012101007@lus.ac.bd', // Asif
    'cse_0182310012101039@lus.ac.bd', // Hridoy
    'jahanispa02@gmail.com', // Ispa
  ];

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is admin
  bool isAdmin(String email) {
    return adminEmails.contains(email.toLowerCase());
  }

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);

      // Send email verification
      await result.user?.sendEmailVerification();

      // Save user to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email.toLowerCase(),
        'name': name,
        'isAdmin': isAdmin(email),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user name from Firestore
  Future<String?> getUserName() async {
    if (currentUser == null) return null;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return doc.get('name') as String?;
    } catch (e) {
      return currentUser?.displayName;
    }
  }

  // Password validation (8-12 characters)
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (password.length > 12) {
      return 'Password must be at most 12 characters';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}
