import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import '../../widgets/expense_tile.dart';
import 'admin_approvals.dart';
import 'admin_notifications.dart';

class AdminDashboard extends StatelessWidget {
const AdminDashboard({
super.key,
});

@override
Widget build(BuildContext context) {
final store = FirestoreService();

final auth = context.watch<AuthProvider>();

final AppUser? currentUser = auth.currentUser;

// ============================================================
// CURRENT LOGGED-IN USER
// ============================================================

final String? currentUid = currentUser?.uid;

// ============================================================
// ROLE
//
// NORMAL ADMIN:
//   Only his own data.
//
// SUPER ADMIN:
//   All users / all expenses.
// ============================================================

final bool isSuperAdmin = auth.isSuperAdmin;

// ============================================================
// USER STREAM
// ============================================================
//
// For normal admin we do NOT call allUsers().
//
// We already have the logged-in user's profile in AuthProvider.
//
// For super_admin we can still show all users.
// ============================================================

final Stream<List<AppUser>> usersStream;

if (isSuperAdmin) {
usersStream = store.allUsers();
} else if (currentUser != null) {
usersStream = Stream.value(
<AppUser>[
currentUser,
],
);
} else {
usersStream = Stream.value(
<AppUser>[],
);
}

// ============================================================
// EXPENSE STREAM
// ============================================================
//
// THIS IS THE MAIN FIX.
//
// Normal admin:
//   userExpenses(currentUid)
//
// Super admin:
//   allExpenses()
// ============================================================

final Stream<List<Expense>> expenseStream;

if (isSuperAdmin) {
expenseStream = store.allExpenses();
} else if (currentUid != null) {
expenseStream = store.userExpenses(
currentUid,
);
} else {
expenseStream = Stream.value(
<Expense>[],
);
}

return StreamBuilder<List<AppUser>>(
stream: usersStream,
builder: (context, userSnapshot) {
final users =
userSnapshot.data ?? <AppUser>[];

return StreamBuilder<List<Expense>>(
stream: expenseStream,
builder: (context, expenseSnapshot) {
final expenses =
expenseSnapshot.data ?? <Expense>[];

final now = DateTime.now();

// ====================================================
// TODAY'S EXPENSES
// ====================================================

final today = expenses
    .where(
(expense) =>
_sameDate(
expense.expenseDate,
now,
),
)
    .toList();

// ====================================================
// THIS MONTH'S EXPENSES
// ====================================================

final month = expenses
    .where(
(expense) =>
expense.expenseDate.year ==
now.year &&
expense.expenseDate.month ==
now.month,
)
    .toList();

// ====================================================
// TOTAL FUNCTION
// ====================================================

double sum(
List<Expense> items,
) {
return items.fold<double>(
0,
(total, expense) {
return total + expense.amount;
},
);
}

final todayTotal = sum(today);
final monthTotal = sum(month);

// ====================================================
// UI
// ====================================================

return SafeArea(
child: SingleChildScrollView(
padding:
const EdgeInsets.fromLTRB(
20,
24,
20,
120,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ==================================================
// HEADER
// ==================================================

_Header(
isAdmin: auth.isAdmin,
onNotifications:
auth.isAdmin
? () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const AdminNotifications(),
),
);
}
    : null,
),

const SizedBox(height: 24),

// ==================================================
// STAT CARDS
// ==================================================

GridView.count(
crossAxisCount: 2,
shrinkWrap: true,
physics:
const NeverScrollableScrollPhysics(),
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 1.55,
children: [
// ----------------------------------------------
// USERS
// ----------------------------------------------

StatCard(
label: isSuperAdmin
? 'Total users'
    : 'My profile',
value: isSuperAdmin
? '${users.length}'
    : '1',
icon:
Icons.groups_rounded,
accent:
AppColors.primary,
),

// ----------------------------------------------
// TODAY
// ----------------------------------------------

StatCard(
label: isSuperAdmin
? 'Today'
    : 'My today',
value:
'₹${NumberFormat('#,##0').format(todayTotal)}',
icon:
Icons.today_rounded,
accent:
AppColors.secondary,
),

// ----------------------------------------------
// MONTH
// ----------------------------------------------

StatCard(
label: isSuperAdmin
? 'This month'
    : 'My month',
value:
'₹${NumberFormat('#,##0').format(monthTotal)}',
icon: Icons
    .calendar_month_rounded,
accent:
AppColors.warning,
),

// ----------------------------------------------
// EXPENSE COUNT
// ----------------------------------------------

StatCard(
label: isSuperAdmin
? 'All expenses'
    : 'My expenses',
value:
'${expenses.length}',
icon: Icons
    .receipt_long_rounded,
accent:
AppColors.success,
),
],
),

// ==================================================
// REGISTRATION APPROVALS
// ==================================================
//
// Existing admin approval flow is preserved.
//
// This section does NOT affect expense filtering.
// ==================================================

if (auth.isAdmin) ...[
const SizedBox(height: 22),

StreamBuilder<List<AppUser>>(
stream:
store.pendingUsers(),
builder:
(context, pendingSnapshot) {
final count =
pendingSnapshot
    .data
    ?.length ??
0;

return InkWell(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const AdminApprovals(),
),
);
},
borderRadius:
BorderRadius.circular(
22,
),
child: Container(
width: double.infinity,
padding:
const EdgeInsets.all(
18,
),
decoration:
BoxDecoration(
gradient:
const LinearGradient(
colors: [
Color(
0xFF0F172A,
),
Color(
0xFF1E3A8A,
),
],
),
borderRadius:
BorderRadius.circular(
22,
),
),
child: Row(
children: [
Container(
width: 46,
height: 46,
decoration:
BoxDecoration(
color: Colors
    .white
    .withValues(
alpha: .10,
),
borderRadius:
BorderRadius
    .circular(
14,
),
),
child:
const Icon(
Icons
    .how_to_reg_rounded,
color:
Colors.white,
),
),

const SizedBox(
width: 13,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
const Text(
'Registration approvals',
style:
TextStyle(
color:
Colors.white,
fontWeight:
FontWeight
    .w800,
fontSize:
15,
),
),
const SizedBox(
height: 4,
),
Text(
count == 0
? 'No pending registrations'
    : '$count registration${count == 1 ? '' : 's'} waiting for you',
style:
const TextStyle(
color: Colors
    .white70,
fontSize:
12.5,
),
),
],
),
),

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 11,
vertical: 8,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
12,
),
),
child: Text(
'$count',
style:
const TextStyle(
color:
AppColors
    .ink,
fontWeight:
FontWeight
    .w800,
),
),
),
],
),
),
);
},
),
],

const SizedBox(height: 28),

// ==================================================
// ACTIVITY TITLE
// ==================================================

Text(
isSuperAdmin
? 'Today’s activity'
    : 'My activity today',
style: const TextStyle(
fontSize: 18,
fontWeight:
FontWeight.w800,
),
),

const SizedBox(height: 12),

// ==================================================
// ACTIVITY
// ==================================================

if (today.isEmpty)
EmptyState(
title:
'No activity today',
message: isSuperAdmin
? 'No user has recorded an expense today.'
    : 'You have not recorded an expense today.',
)
else
...today
    .take(8)
    .map(
(expense) =>
ExpenseTile(
expense: expense,
userName:
isSuperAdmin
? _userName(
users,
expense.userId,
)
    : null,
),
),
],
),
),
);
},
);
},
);
}

// ================================================================
// FIND USER NAME
// ================================================================

String _userName(
List<AppUser> users,
String uid,
) {
for (final user in users) {
if (user.uid == uid) {
return user.name;
}
}

return 'User';
}

// ================================================================
// SAME DATE
// ================================================================

bool _sameDate(
DateTime first,
DateTime second,
) {
return first.year == second.year &&
first.month == second.month &&
first.day == second.day;
}
}

// ==================================================================
// HEADER
// ==================================================================

class _Header extends StatelessWidget {
final bool isAdmin;
final VoidCallback? onNotifications;

const _Header({
required this.isAdmin,
this.onNotifications,
});

@override
Widget build(BuildContext context) {
final store = FirestoreService();

return Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'Admin dashboard',
style: TextStyle(
fontSize: 26,
fontWeight:
FontWeight.w800,
),
),

const SizedBox(height: 4),

Text(
DateFormat(
'EEEE, dd MMMM yyyy',
).format(
DateTime.now(),
),
style: const TextStyle(
color: AppColors.slate,
fontSize: 13.5,
),
),
],
),
),

if (onNotifications != null)
StreamBuilder<int>(
stream:
store.unreadNotificationCount(),
builder: (
context,
snapshot,
) {
final count =
snapshot.data ?? 0;

return Stack(
clipBehavior:
Clip.none,
children: [
Container(
width: 46,
height: 46,
decoration:
BoxDecoration(
color: AppColors.primary
    .withValues(
alpha: .10,
),
borderRadius:
BorderRadius.circular(
14,
),
),
child: IconButton(
onPressed:
onNotifications,
icon:
const Icon(
Icons
    .notifications_none_rounded,
color:
AppColors.primary,
),
),
),

if (count > 0)
Positioned(
right: -3,
top: -4,
child: Container(
constraints:
const BoxConstraints(
minWidth: 19,
),
height: 19,
padding:
const EdgeInsets
    .symmetric(
horizontal: 5,
),
decoration:
const BoxDecoration(
color:
AppColors.danger,
shape:
BoxShape.circle,
),
alignment:
Alignment.center,
child: Text(
count > 99
? '99+'
    : '$count',
style:
const TextStyle(
color:
Colors.white,
fontSize: 9,
fontWeight:
FontWeight.w800,
),
),
),
),
],
);
},
),
],
);
}
}