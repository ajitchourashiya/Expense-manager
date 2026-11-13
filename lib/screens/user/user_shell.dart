import 'package:flutter/material.dart';
import 'package:floating_bottom_bar/animated_bottom_navigation_bar.dart';

import '../../core/theme.dart' as app_theme;

import '../../services/interstitial_ad_service.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'add_expense_screen.dart';
import 'profile_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int index = 0;

  late final FloatingBottomBarController _controller;

  @override
  void initState() {
    super.initState();

    _controller = FloatingBottomBarController(
      initialIndex: 0,
    );
  }

  void _changePage(int value) {
    if (value < 0 || value > 3) return;

    if (index != value) InterstitialAdService.instance.showIfReady();
    setState(() {
      index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = app_theme.AppColors.primary;
    const slate = app_theme.AppColors.slate;

    final pages = <Widget>[
      const UserHomeScreen(),
      const AddExpenseScreen(),
      const UserReportsScreen(),
      const UserProfileScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,

      body: IndexedStack(
        index: index,
        children: pages,
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedBottomNavigationBar(
          controller: _controller,

          barColor: Colors.white,

          bottomBar: [
            BottomBarItem(
              icon: const Icon(
                Icons.home_rounded,
                color: app_theme.AppColors.slate,
                size: 21,
              ),
              iconSelected: const Icon(
                Icons.home_rounded,
                color: app_theme.AppColors.primary,
                size: 21,
              ),
              title: 'Home',
              dotColor: app_theme.AppColors.primary,
              onTap: (_) {
                _changePage(0);
              },
            ),

            BottomBarItem(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: app_theme.AppColors.slate,
                size: 21,
              ),
              iconSelected: const Icon(
                Icons.add_circle_rounded,
                color: app_theme.AppColors.primary,
                size: 21,
              ),
              title: 'Add',
              dotColor: app_theme.AppColors.primary,
              onTap: (_) {
                _changePage(1);
              },
            ),

            BottomBarItem(
              icon: const Icon(
                Icons.bar_chart_rounded,
                color: app_theme.AppColors.slate,
                size: 21,
              ),
              iconSelected: const Icon(
                Icons.bar_chart_rounded,
                color: app_theme.AppColors.primary,
                size: 21,
              ),
              title: 'Reports',
              dotColor: app_theme.AppColors.primary,
              onTap: (_) {
                _changePage(2);
              },
            ),

            BottomBarItem(
              icon: const Icon(
                Icons.person_outline_rounded,
                color: app_theme.AppColors.slate,
                size: 21,
              ),
              iconSelected: const Icon(
                Icons.person_rounded,
                color: app_theme.AppColors.primary,
                size: 21,
              ),
              title: 'Profile',
              dotColor: app_theme.AppColors.primary,
              onTap: (_) {
                _changePage(3);
              },
            ),
          ],

          bottomBarCenterModel: BottomBarCenterModel(
            centerBackgroundColor: app_theme.AppColors.primary,

            centerIcon: const FloatingCenterButton(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),

            centerIconChild: [
              FloatingCenterButtonChild(
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 23,
                ),
                onTap: () {
                  _changePage(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
