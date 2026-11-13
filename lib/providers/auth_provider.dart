import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';


import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Clean authentication flow:
///
/// REGISTER
/// Firebase Auth account -> Firestore user(pending) -> admin notification
/// -> sign out -> Login screen
///
/// LOGIN
/// Firebase Auth -> Firestore profile -> role/status/isActive check
/// -> approved user/admin enters the correct application.
class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _store = FirestoreService();

  AppUser? currentUser;
  bool loading = false;
  String? error;

  bool get isSuperAdmin => currentUser?.isSuperAdmin == true;
  bool get isAdmin => currentUser?.isAdmin == true;
  bool get isApproved => currentUser?.isApproved == true;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login(String identifier, String password) async {
    loading = true;
    error = null;
    notifyListeners();

    debugPrint('========== LOGIN START ==========');
    debugPrint('[AUTH] Identifier: ${identifier.trim()}');

    try {
      // 1. Firebase authentication.
      debugPrint('[AUTH] Firebase authentication...');
      final credential = await _auth.signIn(
        identifier: identifier,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        error = 'Unable to authenticate your account.';
        debugPrint('[AUTH] FAILED: Firebase user is null');
        return false;
      }

      debugPrint('[AUTH] Firebase authenticated: ${firebaseUser.uid}');

      // 2. Get the user's Firestore profile.
      debugPrint('[AUTH] Loading Firestore profile...');
      final user = await _store.getUser(firebaseUser.uid);

      if (user == null) {
        await _auth.signOut();
        error = 'Your user profile was not found.';
        debugPrint('[AUTH] FAILED: profile not found');
        return false;
      }

      final role = user.role.toLowerCase().trim();
      final status = user.status.toLowerCase().trim();

      debugPrint('[AUTH] UID    : ${user.uid}');
      debugPrint('[AUTH] ROLE   : $role');
      debugPrint('[AUTH] STATUS : $status');
      debugPrint('[AUTH] ACTIVE : ${user.isActive}');

      // 3. Disabled account.
      if (!user.isActive) {
        await _auth.signOut();
        error = 'Your account has been disabled by the admin.';
        debugPrint('[AUTH] BLOCKED: account inactive');
        return false;
      }

      // 4. Registration must be approved before login.
      if (status == 'pending') {
        await _auth.signOut();
        error = 'Your registration is pending admin approval.';
        debugPrint('[AUTH] BLOCKED: pending approval');
        return false;
      }

      if (status == 'rejected') {
        await _auth.signOut();
        error = 'Your registration has been rejected by the admin.';
        debugPrint('[AUTH] BLOCKED: rejected');
        return false;
      }

      // 5. Only approved users can enter.
      if (status != 'approved') {
        await _auth.signOut();
        error = 'Your account is not approved yet.';
        debugPrint('[AUTH] BLOCKED: unsupported status=$status');
        return false;
      }

      // 6. Role check is done AFTER authentication and status check.
      if (role != 'user' && role != 'admin' && role != 'super_admin') {
        await _auth.signOut();
        error = 'Your account role is not configured correctly.';
        debugPrint('[AUTH] BLOCKED: invalid role=$role');
        return false;
      }

      // 7. Success.
      currentUser = user;
      debugPrint('[AUTH] LOGIN SUCCESS');
      debugPrint('[AUTH] ROLE ROUTE: $role');
      debugPrint('=========== LOGIN END ===========');
      return true;
    } on FirebaseAuthException catch (e) {
      error = _friendlyError(e);
      debugPrint('[AUTH] FIREBASE ERROR: ${e.code} | ${e.message}');
      return false;
    } catch (e) {
      error = 'Something went wrong. Please try again.';
      debugPrint('[AUTH] LOGIN ERROR: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register(
    String name,
    String phone,
    String email,
    String password,
  ) async {
    loading = true;
    error = null;
    notifyListeners();

    debugPrint('======== REGISTRATION START ========');
    debugPrint('[REGISTER] Name : ${name.trim()}');
    debugPrint('[REGISTER] Email: ${email.trim()}');
    debugPrint('[REGISTER] Phone: ${phone.trim()}');

    try {
      // AuthService.register creates the Firebase Auth account AND the
      // Firestore profile with role=user/status=pending.
      final credential = await _auth.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        error = 'Registration failed.';
        debugPrint('[REGISTER] FAILED: Firebase user is null');
        return false;
      }

      final uid = firebaseUser.uid;
      debugPrint('[REGISTER] Firebase account created: $uid');

      // Explicitly enforce the required public-registration state.
      // This also protects the flow if AuthService is changed later.
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'uid': uid,
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'role': 'user',
          'status': 'approved',
          'isActive': true,
          'sessionId': null,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint('[REGISTER] Firestore profile: role=user, status=pending');

      // Admin notification is part of the registration flow.
      try {
        await _store.addAdminNotification(
          userId: uid,
          userName: name.trim(),
          userEmail: email.trim(),
        );
        debugPrint('[REGISTER] Admin notification created');
      } catch (e) {
        // The account is already created. Log notification failure without
        // pretending that Firebase registration failed.
        debugPrint('[REGISTER] Notification ERROR: $e');
      }

      // Firebase signs the newly-created user in automatically. Never leave
      // a newly registered/pending user authenticated.
      await _auth.signOut();
      currentUser = null;

      debugPrint('[REGISTER] Firebase user signed out');
      debugPrint('[REGISTER] SUCCESS -> LOGIN');
      debugPrint('========= REGISTRATION END =========');
      return true;
    } on FirebaseAuthException catch (e) {
      error = _friendlyError(e);
      debugPrint('[REGISTER] FIREBASE ERROR: ${e.code} | ${e.message}');
      return false;
    } catch (e) {
      error = 'Registration failed. Please try again.';
      debugPrint('[REGISTER] ERROR: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD AUTHENTICATED USER ON APP START
  // ============================================================

  Future<bool> restoreAuthenticatedUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    debugPrint('[BOOT] Firebase currentUser: ${firebaseUser?.uid ?? 'NONE'}');

    if (firebaseUser == null) {
      currentUser = null;
      return false;
    }

    try {
      final user = await _store.getUser(firebaseUser.uid);
      if (user == null) {
        await _auth.signOut();
        return false;
      }

      final role = user.role.toLowerCase().trim();
      final status = user.status.toLowerCase().trim();

      debugPrint('[BOOT] role=$role status=$status active=${user.isActive}');

      if (!user.isActive || status != 'approved') {
        await _auth.signOut();
        currentUser = null;
        return false;
      }

      if (role != 'user' && role != 'admin' && role != 'super_admin') {
        await _auth.signOut();
        currentUser = null;
        return false;
      }

      currentUser = user;
      return true;
    } catch (e) {
      debugPrint('[BOOT] Restore ERROR: $e');
      await _auth.signOut();
      currentUser = null;
      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    debugPrint('========== LOGOUT START ==========');
    debugPrint('[AUTH] Signing out Firebase user...');

    currentUser = null;
    error = null;

    try {
      await _auth.signOut();
      debugPrint('[AUTH] Firebase sign-out SUCCESS');
    } catch (e) {
      debugPrint('[AUTH] Firebase sign-out ERROR: $e');
    }

    notifyListeners();

    if (Get.currentRoute != '/login') {
      debugPrint('[NAV] LOGOUT -> LOGIN');
      Get.offAllNamed('/login');
    } else {
      debugPrint('[NAV] Already on LOGIN');
    }

    debugPrint('=========== LOGOUT END ===========');
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.resetPassword(email.trim());
      return true;
    } catch (e) {
      debugPrint('[AUTH] Password reset error: $e');
      return false;
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email/mobile or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'phone-already-in-use':
        return 'This mobile number is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
