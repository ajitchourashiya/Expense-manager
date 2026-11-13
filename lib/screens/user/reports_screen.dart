import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/report_export_service.dart';
import '../../services/interstitial_ad_service.dart';
import '../../widgets/banner_ad.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/expense_tile.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  int tab = 0;
  bool exporting = false;

  Future<void> _export(List<Expense> items, bool isPdf, bool share) async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      await InterstitialAdService.instance.showIfReady(force: true);
      final file = isPdf ? await ReportExportService.pdf(items, _label()) : await ReportExportService.excel(items, _label());
      if (share) await ReportExportService.share(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(share ? "Share sheet opened" : "Report created: ${file.path}")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally { if (mounted) setState(() => exporting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUser?.uid;

    if (uid == null) {
      return const SizedBox();
    }

    return StreamBuilder<List<Expense>>(
      stream: FirestoreService().userExpenses(uid),
      builder: (context, snap) {
        final all = snap.data ?? [];

        final filtered = _filter(all);

        final total = filtered.fold<double>(
          0,
              (sum, expense) => sum + expense.amount,
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // PAGE TITLE
                // =================================================

                const PageTitle(
                  title: 'Reports',
                  subtitle: 'Your spending at a glance.',
                ),

                const SizedBox(height: 22),

                // =================================================
                // TABS
                // =================================================

                _tabs(),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Export & share', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text('Export ${filtered.length} transactions for ${_label().toLowerCase()}.', style: const TextStyle(color: AppColors.slate)),
                    const SizedBox(height: 12),
                    if (exporting) const LinearProgressIndicator(),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      FilledButton.icon(onPressed: exporting ? null : () => _export(filtered, true, false), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('PDF')),
                      FilledButton.icon(onPressed: exporting ? null : () => _export(filtered, false, false), icon: const Icon(Icons.table_chart_outlined), label: const Text('Excel')),
                      OutlinedButton.icon(onPressed: exporting ? null : () => _export(filtered, true, true), icon: const Icon(Icons.share_outlined), label: const Text('Share PDF')),
                      OutlinedButton.icon(onPressed: exporting ? null : () => _export(filtered, false, true), icon: const Icon(Icons.share_outlined), label: const Text('Share Excel')),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
                const BannerAdWidget(),
                const SizedBox(height: 16),

                // =================================================
                // SUMMARY CARD
                // =================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(),
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '₹${NumberFormat('#,##0.00').format(total)}',
                        style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${filtered.length} transaction'
                            '${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =================================================
                // TRANSACTIONS HEADER
                // =================================================

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    Text(
                      DateFormat('dd MMM yyyy')
                          .format(DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // =================================================
                // TRANSACTIONS
                // =================================================

                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'Nothing here yet',
                    message:
                    'No expenses match the selected period.',
                  )
                else
                  ...filtered.map(
                        (expense) => ExpenseTile(
                      expense: expense,

                      // ==========================================
                      // EDIT
                      // ==========================================

                      onEdit: () {
                        _showEditDialog(
                          context,
                          expense,
                        );
                      },

                      // ==========================================
                      // DELETE
                      // ==========================================

                      onDelete: () {
                        _confirmDelete(
                          context,
                          expense,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // TABS
  // ===============================================================

  Widget _tabs() {
    const labels = [
      'Today',
      'This Week',
      'This Month',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(
          labels.length,
              (i) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    tab = i;
                  });
                },
                child: AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: tab == i
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(12),
                    boxShadow: tab == i
                        ? const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 10,
                      ),
                    ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: tab == i
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: tab == i
                          ? AppColors.primary
                          : AppColors.slate,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===============================================================
  // FILTER
  // ===============================================================

  List<Expense> _filter(List<Expense> expenses) {
    final now = DateTime.now();

    // =============================================================
    // TODAY
    // =============================================================

    if (tab == 0) {
      return expenses
          .where(
            (expense) =>
        expense.expenseDate.year == now.year &&
            expense.expenseDate.month == now.month &&
            expense.expenseDate.day == now.day,
      )
          .toList();
    }

    // =============================================================
    // THIS WEEK
    // =============================================================

    if (tab == 1) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(
        Duration(
          days: now.weekday - 1,
        ),
      );

      final end = start.add(
        const Duration(days: 7),
      );

      return expenses
          .where(
            (expense) =>
        !expense.expenseDate.isBefore(start) &&
            expense.expenseDate.isBefore(end),
      )
          .toList();
    }

    // =============================================================
    // THIS MONTH
    // =============================================================

    return expenses
        .where(
          (expense) =>
      expense.expenseDate.year == now.year &&
          expense.expenseDate.month == now.month,
    )
        .toList();
  }

  // ===============================================================
  // LABEL
  // ===============================================================

  String _label() {
    return [
      'Today',
      'Current week',
      'Current month',
    ][tab];
  }

  // ===============================================================
  // EDIT DIALOG
  // ===============================================================

  static Future<void> _showEditDialog(
      BuildContext context,
      Expense expense,
      ) async {
    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );

    final descriptionController =
    TextEditingController(
      text: expense.description,
    );

    String paymentMethod =
    expense.paymentMethod.isEmpty
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
                borderRadius:
                BorderRadius.circular(20),
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
                    // =================================================
                    // AMOUNT
                    // =================================================

                    TextField(
                      controller: amountController,
                      enabled: !saving,
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                      const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixIcon: Icon(
                          Icons
                              .currency_rupee_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // PAYMENT METHOD
                    // =================================================

                    DropdownButtonFormField<String>(
                      initialValue:
                      paymentMethod == 'online' ||
                          paymentMethod == 'cash'
                          ? paymentMethod
                          : 'cash',
                      decoration:
                      const InputDecoration(
                        labelText: 'Payment Method',
                        prefixIcon: Icon(
                          Icons
                              .account_balance_wallet_rounded,
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
                          paymentMethod =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // DESCRIPTION
                    // =================================================

                    TextField(
                      controller:
                      descriptionController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration:
                      const InputDecoration(
                        labelText: 'Description',
                        hintText:
                        'e.g. Food, fuel, groceries...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding:
                          EdgeInsets.only(
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

              // =====================================================
              // ACTIONS
              // =====================================================

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
                    final amount =
                    double.tryParse(
                      amountController.text
                          .replaceAll(',', '')
                          .trim(),
                    );

                    if (amount == null ||
                        amount <= 0) {
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
                        expenseId:
                        expense.id,
                        amount: amount,
                        description:
                        descriptionController
                            .text
                            .trim(),
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
                            e
                                .toString()
                                .replaceFirst(
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
                    child:
                    CircularProgressIndicator(
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

  // ===============================================================
  // DELETE CONFIRMATION
  // ===============================================================

  static Future<void> _confirmDelete(
      BuildContext context,
      Expense expense,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
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
                backgroundColor:
                AppColors.danger,
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
            e
                .toString()
                .replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }
}