import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String paymentMethod;
  final DateTime expenseDate;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};

    final amountValue = data['amount'];

    double amount = 0;

    if (amountValue is num) {
      amount = amountValue.toDouble();
    }

    final expenseDateValue = data['expenseDate'];

    DateTime expenseDate = DateTime.now();

    if (expenseDateValue is Timestamp) {
      expenseDate = expenseDateValue.toDate();
    }

    final createdAtValue = data['createdAt'];

    DateTime? createdAt;

    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    }

    return Expense(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      amount: amount,
      description: data['description']?.toString() ?? '',
      paymentMethod:
      data['paymentMethod']?.toString() ?? 'cash',
      expenseDate: expenseDate,
      createdAt: createdAt,
    );
  }
}
