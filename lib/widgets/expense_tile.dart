import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String? userName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.userName,
    this.onEdit,
    this.onDelete,
  });

  // ===============================================================
  // EDIT / DELETE ALLOWED FOR 7 CALENDAR DAYS
  // ===============================================================

  bool get canModify {
    if (expense.createdAt == null) {
      return false;
    }

    final created = expense.createdAt!;

    final createdDay = DateTime(
      created.year,
      created.month,
      created.day,
    );

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final difference = today.difference(createdDay).inDays;

    return difference >= 0 && difference < 7;
  }

  // ===============================================================
  // OPEN DETAILS BOTTOM SHEET
  // ===============================================================

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return _ExpenseDetailsSheet(
          expense: expense,
          userName: userName,
          canModify: canModify,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = expense.description.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _openDetails(context);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // =====================================================
            // ICON
            // =====================================================

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: .08,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            // =====================================================
            // DESCRIPTION + DATE
            // =====================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description.isEmpty
                        ? 'Expense'
                        : description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${DateFormat('dd MMM, hh:mm a').format(expense.expenseDate)}'
                        '${userName == null ? '' : ' • $userName'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // =====================================================
            // AMOUNT
            // =====================================================

            Text(
              '₹${NumberFormat('#,##0.00').format(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),

            // =====================================================
            // EDIT + DELETE
            // =====================================================

            if (canModify) ...[
              const SizedBox(width: 2),

              IconButton(
                tooltip: 'Edit expense',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
                visualDensity: VisualDensity.compact,
              ),

              IconButton(
                tooltip: 'Delete expense',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 21,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ] else ...[
              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slate,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ===============================================================
// EXPENSE DETAILS BOTTOM SHEET
// ===============================================================

class _ExpenseDetailsSheet extends StatelessWidget {
  final Expense expense;
  final String? userName;
  final bool canModify;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ExpenseDetailsSheet({
    required this.expense,
    required this.userName,
    required this.canModify,
    required this.onEdit,
    required this.onDelete,
  });

  // ===============================================================
  // PAYMENT METHOD DISPLAY
  // ===============================================================

  String get paymentMethod {
    final method = expense.paymentMethod.trim();

    if (method.isEmpty) {
      return 'Not specified';
    }

    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';

      case 'online':
        return 'Online';

      case 'upi':
        return 'UPI';

      case 'card':
        return 'Card';

      case 'bank':
      case 'bank transfer':
        return 'Bank Transfer';

      default:
        return method;
    }
  }

  IconData get paymentMethodIcon {
    switch (expense.paymentMethod.trim().toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;

      case 'online':
      case 'upi':
        return Icons.account_balance_wallet_outlined;

      case 'card':
        return Icons.credit_card_outlined;

      case 'bank':
      case 'bank transfer':
        return Icons.account_balance_outlined;

      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = expense.description.trim();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // DRAG HANDLE
              // =====================================================

              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DCE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =====================================================
              // HEADER
              // =====================================================

              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: .08,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Text(
                      'Expense Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =====================================================
              // AMOUNT
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .06,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: .10,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '₹${NumberFormat('#,##0.00').format(expense.amount)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // DESCRIPTION
              // =====================================================

              _DetailBox(
                icon: Icons.description_outlined,
                title: 'Description',
                value: description.isEmpty
                    ? 'No description'
                    : description,
              ),

              const SizedBox(height: 12),

              // =====================================================
              // DATE & TIME
              // =====================================================

              _DetailBox(
                icon: Icons.calendar_today_outlined,
                title: 'Date & Time',
                value: DateFormat(
                  'dd MMMM yyyy, hh:mm a',
                ).format(expense.expenseDate),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // PAYMENT METHOD
              // =====================================================

              _DetailBox(
                icon: paymentMethodIcon,
                title: 'Payment Method',
                value: paymentMethod,
              ),

              // =====================================================
              // USER
              // =====================================================

              if (userName != null &&
                  userName!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),

                _DetailBox(
                  icon: Icons.person_outline_rounded,
                  title: 'Added by',
                  value: userName!.trim(),
                ),
              ],

              // =====================================================
              // ACTION BUTTONS
              // =====================================================

              if (canModify &&
                  (onEdit != null || onDelete != null)) ...[
                const SizedBox(height: 24),

                Row(
                  children: [
                    // EDIT
                    if (onEdit != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit!();
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                          ),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                            ),
                            minimumSize: const Size(
                              0,
                              52,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                    if (onEdit != null &&
                        onDelete != null)
                      const SizedBox(width: 10),

                    // DELETE
                    if (onDelete != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete!();
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                          ),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.danger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(
                              0,
                              52,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Edit or delete is available for 7 days after creation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate.withValues(
                        alpha: .8,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


// ===============================================================
// DETAIL BOX
// ===============================================================

class _DetailBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}