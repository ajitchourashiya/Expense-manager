import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amount = TextEditingController();
  final description = TextEditingController();

  bool saving = false;

  String paymentMethod = 'Cash';

  // Selected date
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> save() async {
    final value = double.tryParse(
      amount.text.replaceAll(',', '').trim(),
    );

    final uid = context.read<AuthProvider>().currentUser?.uid;

    if (uid == null) {
      _msg('User not logged in.');
      return;
    }

    if (value == null || value <= 0) {
      _msg('Enter a valid amount.');
      return;
    }

    setState(() => saving = true);

    try {
      await FirestoreService().addExpense(
        uid: uid,
        amount: value,
        description: description.text.trim(),
        paymentMethod: paymentMethod,
        expenseDate: selectedDate, // SELECTED DATE GOES TO FIRESTORE
      );

      amount.clear();
      description.clear();

      if (mounted) {
        setState(() {
          paymentMethod = 'Cash';
          selectedDate = DateTime.now();
        });

        _msg('Expense added successfully.');
      }
    } catch (e) {
      if (mounted) {
        _msg('Could not save expense.');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _msg(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const PageTitle(
              title: 'Add expense',
              subtitle: 'Record what you spent.',
            ),

            const SizedBox(height: 28),

            // Date Picker
            InkWell(
              onTap: saving ? null : _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Date',
                  prefixIcon: Icon(
                    Icons.calendar_month_rounded,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down_rounded,
                  ),
                ),
                child: Text(
                  DateFormat(
                    'dd MMMM yyyy',
                  ).format(selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: amount,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: '₹ ',
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(
                  Icons.payments_rounded,
                ),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'Cash',
                  child: Row(
                    children: [
                      Icon(
                        Icons.money_rounded,
                        size: 20,
                        color: Colors.green,
                      ),
                      SizedBox(width: 10),
                      Text('Cash'),
                    ],
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'Online',
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Text('Online'),
                    ],
                  ),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) {
                if (value == null) return;

                setState(() {
                  paymentMethod = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: description,
              enabled: !saving,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText:
                'e.g. Office lunch, fuel, groceries...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 58),
                  child: Icon(
                    Icons.notes_rounded,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Save Expense',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import '../../core/theme.dart';
// import '../../providers/auth_provider.dart';
// import '../../services/firestore_service.dart';
// import '../../widgets/common.dart';
//
// class AddExpenseScreen extends StatefulWidget {
//   const AddExpenseScreen({super.key});
//
//   @override
//   State<AddExpenseScreen> createState() => _AddExpenseScreenState();
// }
//
// class _AddExpenseScreenState extends State<AddExpenseScreen> {
//   final amount = TextEditingController();
//   final description = TextEditingController();
//
//   bool saving = false;
//
//   // Default payment method
//   String paymentMethod = 'Cash';
//
//   @override
//   void dispose() {
//     amount.dispose();
//     description.dispose();
//     super.dispose();
//   }
//
//   Future<void> save() async {
//     final value = double.tryParse(
//       amount.text.replaceAll(',', '').trim(),
//     );
//
//     final uid = context.read<AuthProvider>().currentUser?.uid;
//
//     if (uid == null) {
//       _msg('User not logged in.');
//       return;
//     }
//
//     if (value == null || value <= 0) {
//       _msg('Enter a valid amount.');
//       return;
//     }
//
//     setState(() => saving = true);
//
//     try {
//       await FirestoreService().addExpense(
//         uid: uid,
//         amount: value,
//         description: description.text.trim(),
//         paymentMethod: paymentMethod,
//       );
//
//       amount.clear();
//       description.clear();
//
//       if (mounted) {
//         setState(() {
//           paymentMethod = 'Cash';
//         });
//
//         _msg('Expense added successfully.');
//       }
//     } catch (e) {
//       if (mounted) {
//         _msg('Could not save expense.');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => saving = false);
//       }
//     }
//   }
//
//   void _msg(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.fromLTRB(
//           20,
//           24,
//           20,
//           120,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const PageTitle(
//               title: 'Add expense',
//               subtitle: 'Record what you spent today.',
//             ),
//
//             const SizedBox(height: 28),
//
//             // Expense date card
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(18),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(
//                   color: AppColors.border,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 48,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withValues(
//                         alpha: .1,
//                       ),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: const Icon(
//                       Icons.today_rounded,
//                       color: AppColors.primary,
//                     ),
//                   ),
//
//                   const SizedBox(width: 14),
//
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment:
//                       CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Expense date',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: AppColors.slate,
//                           ),
//                         ),
//
//                         const SizedBox(height: 3),
//
//                         Text(
//                           DateFormat(
//                             'EEEE, dd MMMM yyyy • hh:mm a',
//                           ).format(DateTime.now()),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 18),
//
//             // Amount
//             TextField(
//               controller: amount,
//               enabled: !saving,
//               keyboardType:
//               const TextInputType.numberWithOptions(
//                 decimal: true,
//               ),
//               decoration: const InputDecoration(
//                 labelText: 'Amount',
//                 prefixText: '₹ ',
//                 prefixIcon: Icon(
//                   Icons.currency_rupee_rounded,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Payment Method
//             DropdownButtonFormField<String>(
//               initialValue: paymentMethod,
//               decoration: const InputDecoration(
//                 labelText: 'Payment Method',
//                 prefixIcon: Icon(
//                   Icons.payments_rounded,
//                 ),
//               ),
//               items: const [
//                 DropdownMenuItem<String>(
//                   value: 'Cash',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.money_rounded,
//                         size: 20,
//                         color: Colors.green,
//                       ),
//                       SizedBox(width: 10),
//                       Text('Cash'),
//                     ],
//                   ),
//                 ),
//                 DropdownMenuItem<String>(
//                   value: 'Online',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.account_balance_wallet_rounded,
//                         size: 20,
//                         color: AppColors.primary,
//                       ),
//                       SizedBox(width: 10),
//                       Text('Online'),
//                     ],
//                   ),
//                 ),
//               ],
//               onChanged: saving
//                   ? null
//                   : (value) {
//                 if (value == null) return;
//
//                 setState(() {
//                   paymentMethod = value;
//                 });
//               },
//             ),
//
//             const SizedBox(height: 16),
//
//             // Description
//             TextField(
//               controller: description,
//               enabled: !saving,
//               maxLines: 4,
//               decoration: const InputDecoration(
//                 labelText: 'Description',
//                 hintText:
//                 'e.g. Office lunch, fuel, groceries...',
//                 alignLabelWithHint: true,
//                 prefixIcon: Padding(
//                   padding: EdgeInsets.only(bottom: 58),
//                   child: Icon(
//                     Icons.notes_rounded,
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Save button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: saving ? null : save,
//                 child: saving
//                     ? const SizedBox(
//                   width: 22,
//                   height: 22,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//                     : const Text(
//                   'Save Expense',
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 14),
//
//             const Text(
//               'The date, time and payment method are saved '
//                   'automatically with your expense.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: AppColors.slate,
//                 fontSize: 12.5,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';
// // import 'package:provider/provider.dart';
// //
// // import '../../core/theme.dart';
// // import '../../providers/auth_provider.dart';
// // import '../../services/firestore_service.dart';
// // import '../../widgets/common.dart';
// //
// // class AddExpenseScreen extends StatefulWidget {
// //   const AddExpenseScreen({super.key});
// //
// //   @override
// //   State<AddExpenseScreen> createState() => _AddExpenseScreenState();
// // }
// //
// // class _AddExpenseScreenState extends State<AddExpenseScreen> {
// //   final amount = TextEditingController();
// //   final description = TextEditingController();
// //
// //   bool saving = false;
// //
// //   @override
// //   void dispose() {
// //     amount.dispose();
// //     description.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> save() async {
// //     final value = double.tryParse(
// //       amount.text.replaceAll(',', '').trim(),
// //     );
// //
// //     final uid = context.read<AuthProvider>().currentUser?.uid;
// //
// //     if (uid == null || value == null || value <= 0) {
// //       _msg('Enter a valid amount.');
// //       return;
// //     }
// //
// //     setState(() => saving = true);
// //
// //     try {
// //       await FirestoreService().addExpense(
// //         uid: uid,
// //         amount: value,
// //         description: description.text,
// //       );
// //
// //       amount.clear();
// //       description.clear();
// //
// //       if (mounted) {
// //         _msg('Expense added successfully.');
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         _msg('Could not save expense.');
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() => saving = false);
// //       }
// //     }
// //   }
// //
// //   void _msg(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return SafeArea(
// //       child: SingleChildScrollView(
// //         padding: const EdgeInsets.fromLTRB(
// //           20,
// //           24,
// //           20,
// //           120,
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const PageTitle(
// //               title: 'Add expense',
// //               subtitle: 'Record what you spent today.',
// //             ),
// //
// //             const SizedBox(height: 28),
// //
// //             // Expense date card
// //             Container(
// //               width: double.infinity,
// //               padding: const EdgeInsets.all(18),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(20),
// //                 border: Border.all(
// //                   color: AppColors.border,
// //                 ),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Container(
// //                     width: 48,
// //                     height: 48,
// //                     decoration: BoxDecoration(
// //                       color: AppColors.primary.withValues(
// //                         alpha: .1,
// //                       ),
// //                       borderRadius: BorderRadius.circular(14),
// //                     ),
// //                     child: const Icon(
// //                       Icons.today_rounded,
// //                       color: AppColors.primary,
// //                     ),
// //                   ),
// //
// //                   const SizedBox(width: 14),
// //
// //                   Expanded(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           'Expense date',
// //                           style: TextStyle(
// //                             fontSize: 12,
// //                             color: AppColors.slate,
// //                           ),
// //                         ),
// //
// //                         const SizedBox(height: 3),
// //
// //                         Text(
// //                           DateFormat(
// //                             'EEEE, dd MMMM yyyy • hh:mm a',
// //                           ).format(DateTime.now()),
// //                           style: const TextStyle(
// //                             fontWeight: FontWeight.w700,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             const SizedBox(height: 18),
// //
// //             // Amount
// //             TextField(
// //               controller: amount,
// //               keyboardType: const TextInputType.numberWithOptions(
// //                 decimal: true,
// //               ),
// //               decoration: const InputDecoration(
// //                 labelText: 'Amount',
// //                 prefixText: '₹ ',
// //                 prefixIcon: Icon(
// //                   Icons.currency_rupee_rounded,
// //                 ),
// //               ),
// //             ),
// //
// //             const SizedBox(height: 16),
// //
// //             // Description
// //             TextField(
// //               controller: description,
// //               maxLines: 4,
// //               decoration: const InputDecoration(
// //                 labelText: 'Description',
// //                 hintText:
// //                 'e.g. Office lunch, fuel, groceries...',
// //                 alignLabelWithHint: true,
// //                 prefixIcon: Padding(
// //                   padding: EdgeInsets.only(bottom: 58),
// //                   child: Icon(
// //                     Icons.notes_rounded,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //
// //             const SizedBox(height: 24),
// //
// //             // Save button
// //             SizedBox(
// //               width: double.infinity,
// //               child: ElevatedButton(
// //                 onPressed: saving ? null : save,
// //                 child: saving
// //                     ? const SizedBox(
// //                   width: 22,
// //                   height: 22,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     color: Colors.white,
// //                   ),
// //                 )
// //                     : const Text(
// //                   'Save Expense',
// //                 ),
// //               ),
// //             ),
// //
// //             const SizedBox(height: 14),
// //
// //             const Text(
// //               'The date and time are captured automatically when '
// //                   'you save the expense.',
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 color: AppColors.slate,
// //                 fontSize: 12.5,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
