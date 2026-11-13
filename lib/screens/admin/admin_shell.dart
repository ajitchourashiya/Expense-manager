import 'package:flutter/material.dart';
import '../../services/interstitial_ad_service.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../user/add_expense_screen.dart';
import 'admin_approvals.dart';
import 'admin_dashboard.dart';
import 'admin_notifications.dart';
import 'admin_profile.dart';
import 'admin_reports.dart';
import 'admin_users.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final isNormalAdmin = context.watch<AuthProvider>().isAdmin;

    // Admins can now record their own expenses using the exact same
    // expense form as normal users. The expense is saved against the
    // currently authenticated admin UID.
    final pages = <Widget>[
      const AdminDashboard(),
      const AddExpenseScreen(),
      const AdminUsers(),
      const AdminReports(),
      if (isNormalAdmin) const AdminApprovals(),
      const AdminProfile(),
    ];

    if (index >= pages.length) {
      index = pages.length - 1;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: _buildNavigation(isNormalAdmin),
    );
  }

  Widget _buildNavigation(bool isNormalAdmin) {
    final items = <_AdminNavItem>[
      _AdminNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded),
      _AdminNavItem(Icons.add_circle_outline_rounded, Icons.add_circle_rounded),
      _AdminNavItem(Icons.groups_outlined, Icons.groups_rounded),
      _AdminNavItem(Icons.insights_outlined, Icons.insights_rounded),
      if (isNormalAdmin)
        _AdminNavItem(Icons.how_to_reg_outlined, Icons.how_to_reg_rounded),
      _AdminNavItem(Icons.person_outline_rounded, Icons.person_rounded),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180F172A),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(
                child: _buildNavItem(
                  item: items[i],
                  selected: index == i,
                  onTap: () { if (index != i) InterstitialAdService.instance.showIfReady(); setState(() => index = i); },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required _AdminNavItem item,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: .10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            selected ? item.selectedIcon : item.icon,
            size: 25,
            color: selected ? AppColors.primary : AppColors.slate,
          ),
        ),
      ),
    );
  }

  void openNotifications() {
    Get.to(() => const AdminNotifications());
  }
}

class _AdminNavItem {
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem(this.icon, this.selectedIcon);
}
