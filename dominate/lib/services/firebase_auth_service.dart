import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  static FirebaseAuthService get instance => _instance ??= FirebaseAuthService._();

  FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously (for temporary players)
  Future<User?> signInAnonymously() async {
    try {
      debugPrint('Attempting anonymous sign-in...');
      final userCredential = await _auth.signInAnonymously();
      debugPrint('Anonymous sign-in successful: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      return null;
    }
  }

  // Create account with email and password
  Future<User?> createAccount(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Handle error
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Delete user profile from Firestore first
        await _firestore.collection('profiles').doc(user.uid).delete();
        // Then delete Firebase user
        await user.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Convert anonymous account to permanent account
  Future<User?> linkWithEmailAndPassword(String email, String password) async {
    try {
      if (currentUser != null && currentUser!.isAnonymous) {
        final credential = EmailAuthProvider.credential(email: email, password: password);
        final userCredential = await currentUser!.linkWithCredential(credential);
        return userCredential.user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Firebase Auth error message
  String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}