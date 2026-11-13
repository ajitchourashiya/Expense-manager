import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // USER
  // ============================================================

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return AppUser.fromMap(
      uid,
      doc.data()!,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(
      String uid,
      ) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  // ============================================================
  // EXPENSES
  // ============================================================

  Stream<List<Expense>> userExpenses(String uid) {
    return _db
        .collection('expenses')
        .where(
      'userId',
      isEqualTo: uid,
    )
        .orderBy(
      'expenseDate',
      descending: true,
    )
        .snapshots()
        .map<List<Expense>>(
          (snap) {
        return snap.docs
            .map<Expense>(
              (doc) => Expense.fromDoc(doc),
        )
            .toList();
      },
    );
  }

  Stream<List<Expense>> allExpenses() {
    return _db
        .collection('expenses')
        .orderBy(
      'expenseDate',
      descending: true,
    )
        .snapshots()
        .map<List<Expense>>(
          (snap) {
        return snap.docs
            .map<Expense>(
              (doc) => Expense.fromDoc(doc),
        )
            .toList();
      },
    );
  }

  // ============================================================
  // ADD EXPENSE
  // ============================================================

  Future<void> addExpense({
    required String uid,
    required double amount,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    await _db.collection('expenses').add({
      'userId': uid,
      'amount': amount,
      'description': description.trim(),
      'paymentMethod': paymentMethod.toLowerCase(),

      // User selected date
      'expenseDate': Timestamp.fromDate(
        expenseDate,
      ),

      // Actual record creation time
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE EXPENSE
  // Allowed for 3 calendar days after creation.
  //
  // Example:
  // Created on 3 Oct
  // Can edit on 3, 4, 5, 6 Oct
  // From 7 Oct -> locked
  // ============================================================

  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String description,
    required String paymentMethod,
  }) async {
    final ref = _db
        .collection('expenses')
        .doc(expenseId);

    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Expense not found.');
    }

    final data = snap.data();

    if (data == null) {
      throw Exception('Expense data not found.');
    }

    final createdAtTimestamp =
    data['createdAt'] as Timestamp?;

    if (createdAtTimestamp == null) {
      throw Exception(
        'Creation date not found.',
      );
    }

    final createdAt =
    createdAtTimestamp.toDate();

    final today = DateTime.now();

    final createdDay = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    final currentDay = DateTime(
      today.year,
      today.month,
      today.day,
    );

    // 3 calendar days:
    // Created 3 Oct -> allowed through 6 Oct
    final expiryDay = createdDay.add(
      const Duration(days: 4),
    );

    if (!currentDay.isBefore(expiryDay)) {
      throw Exception(
        'This expense can no longer be edited.',
      );
    }

    await ref.update({
      'amount': amount,
      'description': description.trim(),
      'paymentMethod': paymentMethod.toLowerCase(),
    });
  }

  // ============================================================
  // DELETE EXPENSE
  // Allowed for 3 calendar days after creation.
  // ============================================================

  Future<void> deleteExpense(
      String expenseId,
      ) async {
    final ref = _db
        .collection('expenses')
        .doc(expenseId);

    final snap = await ref.get();

    if (!snap.exists) {
      throw Exception('Expense not found.');
    }

    final data = snap.data();

    if (data == null) {
      throw Exception('Expense data not found.');
    }

    final createdAtTimestamp =
    data['createdAt'] as Timestamp?;

    if (createdAtTimestamp == null) {
      throw Exception(
        'Creation date not found.',
      );
    }

    final createdAt =
    createdAtTimestamp.toDate();

    final today = DateTime.now();

    final createdDay = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    final currentDay = DateTime(
      today.year,
      today.month,
      today.day,
    );

    // Created 3 Oct -> delete allowed through 6 Oct
    final expiryDay = createdDay.add(
      const Duration(days: 4),
    );

    if (!currentDay.isBefore(expiryDay)) {
      throw Exception(
        'This expense can no longer be deleted.',
      );
    }

    await ref.delete();
  }

  // ============================================================
  // USERS
  // ============================================================

  Stream<List<AppUser>> allUsers() {
    return _db
        .collection('users')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map<List<AppUser>>(
          (snap) {
        return snap.docs
            .map<AppUser>(
              (doc) => AppUser.fromMap(
            doc.id,
            doc.data(),
          ),
        )
            .toList();
      },
    );
  }

  Stream<List<AppUser>> pendingUsers() {
    return _db
        .collection('users')
        .where(
      'status',
      isEqualTo: 'pending',
    )
        .snapshots()
        .map<List<AppUser>>(
          (snap) {
        return snap.docs
            .map<AppUser>(
              (doc) => AppUser.fromMap(
            doc.id,
            doc.data(),
          ),
        )
            .toList();
      },
    );
  }

  // ============================================================
  // APPROVE / REJECT USER
  // ============================================================

  Future<void> approveUser(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({
      'role': 'user',
      'status': 'approved',
      'isActive': true,
      'approvedAt':
      FieldValue.serverTimestamp(),
    });

    await markRegistrationNotificationRead(
      uid,
    );
  }

  Future<void> rejectUser(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({
      'role': 'user',
      'status': 'rejected',
      'isActive': false,
      'rejectedAt':
      FieldValue.serverTimestamp(),
    });

    await markRegistrationNotificationRead(
      uid,
    );
  }

  // ============================================================
  // ADMIN NOTIFICATIONS
  // ============================================================

  Future<void> addAdminNotification({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    await _db
        .collection('admin_notifications')
        .add({
      'type': 'registration',
      'title': 'New registration request',
      'message':
      '$userName has registered and is waiting for approval.',
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'read': false,
      'createdAt':
      FieldValue.serverTimestamp(),
    });
  }

  Stream<
      List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>> adminNotifications() {
    return _db
        .collection('admin_notifications')
        .orderBy(
      'createdAt',
      descending: true,
    )
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs,
    );
  }

  Stream<int> unreadNotificationCount() {
    return _db
        .collection('admin_notifications')
        .where(
      'read',
      isEqualTo: false,
    )
        .snapshots()
        .map(
          (snap) => snap.docs.length,
    );
  }

  Future<void> markRegistrationNotificationRead(
      String userId,
      ) async {
    final snap = await _db
        .collection('admin_notifications')
        .where(
      'userId',
      isEqualTo: userId,
    )
        .where(
      'read',
      isEqualTo: false,
    )
        .get();

    if (snap.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.update(
        doc.reference,
        {
          'read': true,
        },
      );
    }

    await batch.commit();
  }

  Future<void> markNotificationRead(
      String id,
      ) {
    return _db
        .collection('admin_notifications')
        .doc(id)
        .update({
      'read': true,
    });
  }

  Future<void> markAllNotificationsRead() async {
    final snap = await _db
        .collection('admin_notifications')
        .where(
      'read',
      isEqualTo: false,
    )
        .get();

    if (snap.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.update(
        doc.reference,
        {
          'read': true,
        },
      );
    }

    await batch.commit();
  }
}
