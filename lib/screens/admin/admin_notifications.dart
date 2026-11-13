import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/firestore_service.dart';
import 'admin_approvals.dart';

class AdminNotifications extends StatelessWidget {
  const AdminNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          StreamBuilder<int>(
            stream: store.unreadNotificationCount(),
            builder: (context, snap) {
              if ((snap.data ?? 0) == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: store.markAllNotificationsRead,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: store.adminNotifications().map((items) => items),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 58, color: AppColors.slate),
                    SizedBox(height: 14),
                    Text(
                      'No notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'New registrations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final read = data['read'] == true;
              final created = data['createdAt'];
              final date = created is Timestamp ? created.toDate() : null;

              return InkWell(
                onTap: () async {
                  await store.markNotificationRead(doc.id);
                  if (data['type'] == 'registration' && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: AdminApprovals(),
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: read
                        ? Colors.white
                        : AppColors.primary.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: read
                          ? AppColors.border
                          : AppColors.primary.withValues(alpha: .18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (data['title'] ?? 'Notification').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!read)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              (data['message'] ?? '').toString(),
                              style: const TextStyle(
                                color: AppColors.slate,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              date is DateTime
                                  ? DateFormat('dd MMM, hh:mm a').format(date)
                                  : 'Just now',
                              style: const TextStyle(
                                color: AppColors.slate,
                                fontSize: 11,
                              ),
                            ),
                            if (data['type'] == 'registration') ...[
                              const SizedBox(height: 10),
                              const Text(
                                'Tap to review registration →',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
