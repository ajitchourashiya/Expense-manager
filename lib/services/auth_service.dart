import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> signIn({
    required String identifier,
    required String password,
  }) async {
    final value = identifier.trim();

    var email = value;

    // ----------------------------------------------------------
    // LOGIN USING MOBILE NUMBER
    // ----------------------------------------------------------

    if (!value.contains('@')) {
      final normalized = value.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (normalized.length != 10) {
        throw FirebaseAuthException(
          code: 'invalid-phone',
          message:
          'Please enter a valid 10-digit mobile number.',
        );
      }

      final query = await _db
          .collection('users')
          .where(
        'phone',
        isEqualTo: normalized,
      )
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message:
          'No account found for this mobile number.',
        );
      }

      email = (query.docs.first.data()['email'] ?? '')
          .toString()
          .trim();

      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-user',
          message:
          'Mobile account is missing an email.',
        );
      }
    }

    // ----------------------------------------------------------
    // FIREBASE AUTH LOGIN
    // ----------------------------------------------------------

    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // PUBLIC REGISTRATION
  // ============================================================

  Future<UserCredential> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // ----------------------------------------------------------
    // NORMALIZE PHONE
    // ----------------------------------------------------------

    final normalizedPhone = phone.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (normalizedPhone.length != 10) {
      throw FirebaseAuthException(
        code: 'invalid-phone',
        message:
        'Mobile number must be exactly 10 digits.',
      );
    }

    // ----------------------------------------------------------
    // NORMALIZE EMAIL
    // ----------------------------------------------------------

    final normalizedEmail =
    email.trim().toLowerCase();

    // ----------------------------------------------------------
    // CHECK DUPLICATE PHONE
    // ----------------------------------------------------------

    final existingPhone = await _db
        .collection('users')
        .where(
      'phone',
      isEqualTo: normalizedPhone,
    )
        .limit(1)
        .get();

    if (existingPhone.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'phone-already-in-use',
        message:
        'This mobile number is already registered.',
      );
    }

    // ----------------------------------------------------------
    // CREATE FIREBASE AUTH ACCOUNT
    // ----------------------------------------------------------

    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message:
        'Unable to create Firebase account.',
      );
    }

    final uid = firebaseUser.uid;

    // ----------------------------------------------------------
    // CREATE NORMAL USER PROFILE
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    //
    // Public registration ALWAYS creates:
    //
    // role     = user
    // status   = approved
    // isActive = true
    //
    // It does NOT create admin.
    // ----------------------------------------------------------

    await _db
        .collection('users')
        .doc(uid)
        .set({
      'uid': uid,
      'name': name.trim(),
      'phone': normalizedPhone,
      'email': normalizedEmail,

      'role': 'user',

      'status': 'pending',

      'isActive': true,

      'sessionId': null,

      'createdAt':
      FieldValue.serverTimestamp(),
    });

    // ----------------------------------------------------------
    // UPDATE FIREBASE DISPLAY NAME
    // ----------------------------------------------------------

    try {
      await firebaseUser.updateDisplayName(
        name.trim(),
      );
    } catch (_) {
      // Do not fail registration because displayName failed.
    }

    return credential;
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword(
      String email,
      ) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() {
    return _auth.signOut();
  }

  // ============================================================
  // GENERATE SESSION ID
  // ============================================================

  String generateSessionId() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      24,
          (_) => random.nextInt(256),
    );

    final randomPart = bytes
        .map(
          (e) => e
          .toRadixString(16)
          .padLeft(2, '0'),
    )
        .join();

    return '${DateTime.now().microsecondsSinceEpoch}_$randomPart';
  }

  // ============================================================
  // START SINGLE DEVICE SESSION
  // ============================================================

  Future<String> startSingleDeviceSession(
      String uid,
      ) async {
    final sessionId =
    generateSessionId();

    await _db
        .collection('users')
        .doc(uid)
        .update({
      'sessionId': sessionId,
      'lastLoginAt':
      FieldValue.serverTimestamp(),
      'isActive': true,
    });

    return sessionId;
  }

  // ============================================================
  // REALTIME SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
  sessionStream(
      String uid,
      ) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  Future<void> clearSession(
      String uid,
      String sessionId,
      ) async {
    final ref = _db
        .collection('users')
        .doc(uid);

    final snapshot =
    await ref.get();

    if (!snapshot.exists) {
      return;
    }

    final data = snapshot.data();

    final currentSession =
    data?['sessionId']?.toString();

    if (currentSession == sessionId) {
      await ref.update({
        'sessionId': null,
      });
    }
  }
}