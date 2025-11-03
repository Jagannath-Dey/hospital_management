import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// User model for better type safety
class AppUser {
  final String uid;
  final String email;
  final String userType;
  final Map<String, dynamic> userData;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.userType,
    required this.userData,
    this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      userType: data['userType'] ?? '',
      userData: Map<String, dynamic>.from(data),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'userType': userType,
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// Registration result model
class RegistrationResult {
  final User? user;
  final AppUser? appUser;
  final bool success;
  final String? error;

  RegistrationResult({
    this.user,
    this.appUser,
    required this.success,
    this.error,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current app user with full data
  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current app user: $e');
      return null;
    }
  }

  // Sign in with email and password - returns AppUser
  Future<RegistrationResult> signInWithEmailPassword(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return RegistrationResult(
          success: false,
          error: 'Sign in failed - no user returned',
        );
      }

      // Fetch user data from Firestore
      final appUser = await _getUserDataById(credential.user!.uid);

      return RegistrationResult(
        success: true,
        user: credential.user,
        appUser: appUser,
      );
    } on FirebaseAuthException catch (e) {
      return RegistrationResult(
        success: false,
        error: _handleAuthException(e),
      );
    } catch (e) {
      debugPrint('Unexpected sign in error: $e');
      return RegistrationResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Register with email and password - IMPROVED VERSION
  Future<RegistrationResult> registerWithEmailPassword(
      String email,
      String password,
      String userType,
      Map<String, dynamic> userData,
      ) async {
    UserCredential? credential;
    String? userId;

    // Validate input
    if (email.isEmpty || password.isEmpty || userType.isEmpty) {
      return RegistrationResult(
        success: false,
        error: 'Please fill in all required fields',
      );
    }

    try {
      // Step 1: Create the user account
      debugPrint('Creating user account...');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      userId = credential.user?.uid;
      if (userId == null) {
        throw 'Failed to create user account';
      }

      debugPrint('User created with ID: $userId');

      // Step 2: Create AppUser object
      final appUser = AppUser(
        uid: userId,
        email: email,
        userType: userType,
        userData: userData,
      );

      // Step 3: Store user data with transaction for consistency
      await _storeUserData(appUser);

      debugPrint('User data stored successfully');

      return RegistrationResult(
        success: true,
        user: credential.user,
        appUser: appUser,
      );

    } on FirebaseAuthException catch (e) {
      // Cleanup if needed
      await _cleanupFailedRegistration(userId);

      return RegistrationResult(
        success: false,
        error: _handleAuthException(e),
      );
    } catch (e) {
      debugPrint('Unexpected registration error: $e');

      // Cleanup if needed
      await _cleanupFailedRegistration(userId);

      return RegistrationResult(
        success: false,
        error: 'Registration failed. Please try again.',
      );
    }
  }

  // Store user data with transaction
  Future<void> _storeUserData(AppUser appUser) async {
    final batch = _firestore.batch();

    // Main user document
    batch.set(
      _firestore.collection('users').doc(appUser.uid),
      appUser.toMap(),
    );

    // Type-specific collection
    if (appUser.userType == 'patient') {
      batch.set(
        _firestore.collection('patients').doc(appUser.uid),
        appUser.toMap(),
      );
    } else if (appUser.userType == 'doctor') {
      batch.set(
        _firestore.collection('doctors').doc(appUser.uid),
        appUser.toMap(),
      );
    }

    await batch.commit();
  }

  // Cleanup failed registration
  Future<void> _cleanupFailedRegistration(String? userId) async {
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('users').doc(userId));
      batch.delete(_firestore.collection('patients').doc(userId));
      batch.delete(_firestore.collection('doctors').doc(userId));
      await batch.commit();

      // Try to delete the auth user
      final user = _auth.currentUser;
      if (user?.uid == userId) {
        await user?.delete();
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  // Get user data by ID
  Future<AppUser?> _getUserDataById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Get user type - with proper null safety
  Future<String?> getUserType(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['userType'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user type: $e');
      return null;
    }
  }

  // Get user data - returns typed AppUser
  Future<AppUser?> getUserData(String uid) async {
    return _getUserDataById(uid);
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Sign out error: $e');
      return false;
    }
  }

  // Password reset
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    }
  }

  // Update password
  Future<String?> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    }
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  // Verify user session is valid
  Future<bool> verifySession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _auth.currentUser != null;
    } catch (e) {
      debugPrint('Session verification error: $e');
      return false;
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}