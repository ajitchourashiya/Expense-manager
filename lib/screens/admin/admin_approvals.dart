import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class AdminApprovals extends StatelessWidget {
  const AdminApprovals({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FirestoreService();

    return SafeArea(
      child: StreamBuilder<List<AppUser>>(
        stream: store.pendingUsers(),
        builder: (context, snapshot) {
          final users = [...(snapshot.data ?? [])];
          users.sort((a, b) {
            final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registration approvals',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  users.isEmpty
                      ? 'No registrations are waiting for approval.'
                      : '${users.length} registration${users.length == 1 ? '' : 's'} waiting for review.',
                  style: const TextStyle(color: AppColors.slate),
                ),
                const SizedBox(height: 22),
                if (users.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 42,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 52,
                          color: AppColors.success,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'All caught up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'New registrations will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.slate),
                        ),
                      ],
                    ),
                  )
                else
                  ...users.map((user) => _RegistrationCard(
                        user: user,
                        onApprove: () => _approve(context, store, user),
                        onReject: () => _reject(context, store, user),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    FirestoreService store,
    AppUser user,
  ) async {
    try {
      await store.approveUser(user.uid);
      if (context.mounted) {
        _message(context, '${user.name} has been approved.', AppColors.success);
      }
    } catch (e) {
      if (context.mounted) {
        _message(context, 'Could not approve registration: $e', AppColors.danger);
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    FirestoreService store,
    AppUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject registration?'),
        content: Text(
          'This will prevent ${user.name.isEmpty ? 'this user' : user.name} from signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await store.rejectUser(user.uid);
      if (context.mounted) {
        _message(context, '${user.name} has been rejected.', AppColors.danger);
      }
    } catch (e) {
      if (context.mounted) {
        _message(context, 'Could not reject registration: $e', AppColors.danger);
      }
    }
  }

  void _message(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }
}

class _RegistrationCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RegistrationCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty ? 'U' : user.name.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: .10),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'Unnamed user' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone.isEmpty ? 'No mobile number' : user.phone,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Registered ${user.createdAt == null ? 'recently' : DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt!)}',
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              if (compact) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
