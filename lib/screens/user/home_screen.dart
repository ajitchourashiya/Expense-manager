import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/expense_tile.dart';
import '../../widgets/user_header.dart';
import '../../widgets/banner_ad.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('========================================');
    debugPrint('[HOME] UserHomeScreen BUILD');
    debugPrint('========================================');

    final uid = context.watch<AuthProvider>().currentUser?.uid;

    debugPrint('[HOME] UID: $uid');

    // ============================================================
    // AUTH CHECK
    // ============================================================

    if (uid == null) {
      debugPrint('[HOME] ❌ UID IS NULL');

      return const Scaffold(
        body: Center(
          child: Text(
            'User not authenticated.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    debugPrint('[HOME] ✅ UID AVAILABLE');
    debugPrint('[HOME] Starting Firestore expense stream...');

    return StreamBuilder<List<Expense>>(
      stream: FirestoreService().userExpenses(uid),

      builder: (context, snap) {
        debugPrint('========================================');
        debugPrint('[HOME] FIRESTORE STREAM BUILDER');
        debugPrint('[HOME] Connection: ${snap.connectionState}');
        debugPrint('[HOME] Has data: ${snap.hasData}');
        debugPrint('[HOME] Has error: ${snap.hasError}');

        if (snap.hasError) {
          debugPrint('[HOME] ❌ FIRESTORE ERROR');
          debugPrint('[HOME] ${snap.error}');
        }

        final list = snap.data ?? [];

        debugPrint('[HOME] Expenses count: ${list.length}');

        // ========================================================
        // DATE CALCULATIONS
        // ========================================================

        final now = DateTime.now();

        final today = list
            .where(
              (e) => _same(
            e.expenseDate,
            now,
          ),
        )
            .toList();

        final week = list
            .where(
              (e) =>
          e.expenseDate.isAfter(
            now.subtract(
              Duration(
                days: now.weekday - 1,
              ),
            ),
          ) &&
              e.expenseDate.isBefore(
                now.add(
                  const Duration(days: 1),
                ),
              ),
        )
            .toList();

        final month = list
            .where(
              (e) =>
          e.expenseDate.year == now.year &&
              e.expenseDate.month == now.month,
        )
            .toList();

        double sum(List<Expense> expenses) {
          return expenses.fold(
            0,
                (total, expense) => total + expense.amount,
          );
        }

        debugPrint(
          '[HOME] Today: ${today.length} | '
              'Week: ${week.length} | '
              'Month: ${month.length}',
        );

        // ========================================================
        // SCREEN
        // ========================================================

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                UserHeader(
                  title: 'Good ${_greeting()},',
                  subtitle: DateFormat(
                    'EEEE, dd MMMM yyyy',
                  ).format(now),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TODAY'S SPENDING
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x336366F1),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's spending",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '₹${NumberFormat('#,##0.00').format(sum(today))}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white70,
                            size: 17,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            '${today.length} expense${today.length == 1 ? '' : 's'} recorded today',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // STATS
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Till\nYesterday',
                        value:
                        '₹${NumberFormat('#,##0').format(sum(week))}',
                        icon: Icons.date_range_rounded,
                        accent: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: StatCard(
                        label: 'This month',
                        value:
                        '₹${NumberFormat('#,##0').format(sum(month))}',
                        icon: Icons.calendar_month_rounded,
                        accent: AppColors.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // RECENT EXPENSES HEADER
                // ==================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    Text(
                      '${list.length} total',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // EXPENSE LIST
                // ==================================================

                if (list.isEmpty)
                  const EmptyState(
                    title: 'No expenses yet',
                    message:
                    'Add your first expense to start building your personal report.',
                  )
                else
                  ...list.take(5).map(
                        (expense) => ExpenseTile(
                      expense: expense,

                      // EDIT
                      onEdit: () {
                        _showEditDialog(
                          context,
                          expense,
                        );
                      },

                      // DELETE
                      onDelete: () {
                        _confirmDelete(
                          context,
                          expense,
                        );
                      },
                    ),
                  ),

                // ==================================================
                // ADMOB BANNER
                //
                // IMPORTANT:
                // Banner is OUTSIDE list.isEmpty condition.
                // It will now load even when there are 0 expenses.
                // ==================================================

                const SizedBox(height: 20),

                Builder(
                  builder: (context) {
                    debugPrint(
                      '========================================',
                    );
                    debugPrint(
                      '[HOME] 🚀 CREATING BannerAdWidget',
                    );
                    debugPrint(
                      '[HOME] Expense count: ${list.length}',
                    );
                    debugPrint(
                      '========================================',
                    );

                    return const BannerAdWidget();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // EDIT DIALOG
  // ==============================================================

  static Future<void> _showEditDialog(
      BuildContext context,
      Expense expense,
      ) async {
    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );

    final descriptionController = TextEditingController(
      text: expense.description,
    );

    String paymentMethod = expense.paymentMethod.isEmpty
        ? 'cash'
        : expense.paymentMethod.toLowerCase();

    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Text(
                'Edit Expense',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amount
                    TextField(
                      controller: amountController,
                      enabled: !saving,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixIcon: Icon(
                          Icons.currency_rupee_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment method
                    DropdownButtonFormField<String>(
                      initialValue:
                      paymentMethod == 'online' ||
                          paymentMethod == 'cash'
                          ? paymentMethod
                          : 'cash',
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text('Cash'),
                        ),
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          paymentMethod = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                        'e.g. Food, fuel, groceries...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            bottom: 45,
                          ),
                          child: Icon(
                            Icons.notes_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                    final amount = double.tryParse(
                      amountController.text
                          .replaceAll(',', '')
                          .trim(),
                    );

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid amount.',
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                    });

                    try {
                      await FirestoreService()
                          .updateExpense(
                        expenseId: expense.id,
                        amount: amount,
                        description:
                        descriptionController.text,
                        paymentMethod:
                        paymentMethod,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Expense updated successfully.',
                          ),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() {
                        saving = false;
                      });

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();
  }

  // ==============================================================
  // DELETE CONFIRMATION
  // ==============================================================

  static Future<void> _confirmDelete(
      BuildContext context,
      Expense expense,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Delete Expense?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this expense? '
                'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirestoreService().deleteExpense(
        expense.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expense deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ==============================================================
  // HELPERS
  // ==============================================================

  static bool _same(
      DateTime a,
      DateTime b,
      ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static String _greeting() {
    final hour = DateTime.now().hour;

    return hour < 12
        ? 'Morning'
        : hour < 17
        ? 'Afternoon'
        : 'Evening';
  }
}
