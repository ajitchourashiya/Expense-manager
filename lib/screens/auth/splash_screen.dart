import 'dart:async';

import 'package:app_version_update/app_version_update.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme.dart';
import 'update_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Timer? _timer;

  bool _checkingUpdate = true;
  bool _finished = false;

  static const String _packageName = 'com.riditech.cash_flow';

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.riditech.cash_flow';

  @override
  void initState() {
    super.initState();

    debugPrint('[SPLASH] CASH FLOW SPLASH STARTED');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _controller.forward();

    _verifyVersion();
  }

  // VERSION CHECK

  Future<void> _verifyVersion() async {
    if (_finished) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final installedVersion = packageInfo.version;
      final installedBuild = packageInfo.buildNumber;

      debugPrint('[UPDATE] Package: ${packageInfo.packageName}');
      debugPrint('[UPDATE] Version: $installedVersion');
      debugPrint('[UPDATE] Build: $installedBuild');

      final result = await AppVersionUpdate.checkForUpdates(
        playStoreId: _packageName,
      );

      if (!mounted) return;

      debugPrint('[UPDATE] canUpdate: ${result.canUpdate}');

      if (result.canUpdate == true) {
        _finished = true;
        _checkingUpdate = false;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UpdateScreen(
              installedVersion: installedVersion,
              installedBuild: installedBuild,
              playStoreUrl: _playStoreUrl,
            ),
          ),
        );

        return;
      }

      _checkingUpdate = false;
      await _finishSplash();
    } catch (e, stackTrace) {
      debugPrint('[UPDATE] Version check failed: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _checkingUpdate = false;
      await _finishSplash();
    }
  }

  // FINISH SPLASH

  Future<void> _finishSplash() async {
    if (!mounted || _finished) return;

    _finished = true;

    await Future.delayed(
      const Duration(seconds: 4),
    );

    if (!mounted) return;

    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    // Login theme colors
    final primaryColor = AppColors.primary;
    final backgroundColor = AppColors.ink;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withValues(alpha: 0.92),
              primaryColor.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.94,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Spacer(),

                // APP ICON
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 35,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: primaryColor,
                    size: 54,
                  ),
                ),

                const SizedBox(height: 30),

                // APP NAME
                const Text(
                  'Cash Flow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Track • Understand • Control',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 42),

                // LOADING INDICATOR
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: primaryColor.withValues(alpha: 0.90),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  _checkingUpdate
                      ? 'Checking for updates...'
                      : 'Loading...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                // FOOTER
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Developed by Riditech Solution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}