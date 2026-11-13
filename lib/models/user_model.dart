import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final bool isActive;
  final String? sessionId;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.status = 'approved',
    this.isActive = true,
    this.sessionId,
    this.createdAt,
  });

  bool get isSuperAdmin => role.toLowerCase().trim() == 'super_admin';
  bool get isAdmin => role.toLowerCase().trim() == 'admin';
  bool get isApproved => status.toLowerCase().trim() == 'approved' && isActive;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final raw = map['createdAt'];
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      status: (map['status'] ?? ((map['role'] == 'admin' || map['role'] == 'super_admin') ? 'approved' : 'pending')).toString(),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      sessionId: map['sessionId']?.toString(),
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'isActive': isActive,
        'sessionId': sessionId,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}
