import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/user/user_shell.dart';
import 'theme.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const userHome = '/user-home';
  static const adminHome = '/admin-home';

  static List<GetPage<dynamic>> get pages => [
        GetPage(name: login, page: () => const LoginScreen()),
        GetPage(name: register, page: () => const RegisterScreen()),
        GetPage(name: userHome, page: () => const UserShell()),
        GetPage(name: adminHome, page: () => const AdminShell()),
      ];
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spendly',
      theme: AppTheme.light,
      getPages: AppRoutes.pages,
      home: const AuthBootstrap(),
    );
  }
}

/// One startup decision only. There is no Firebase auth-state navigation
/// listener here, so registration cannot race against the Login/Register UI.
class AuthBootstrap extends StatefulWidget {
  const AuthBootstrap({super.key});

  @override
  State<AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends State<AuthBootstrap> {
  bool _splashDone = false;
  bool _checking = false;
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _runSplash();
  }

  Future<void> _runSplash() async {
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() => _splashDone = true);
    _restore();
  }

  Future<void> _restore() async {
    if (_checking || _routed) return;
    _checking = true;

    debugPrint('[NAV] BOOT -> CHECK AUTHENTICATION');

    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.restoreAuthenticatedUser();

    if (!mounted || _routed) return;
    _routed = true;

    if (!loggedIn || auth.currentUser == null) {
      debugPrint('[NAV] BOOT -> LOGIN');
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (auth.currentUser!.isSuperAdmin || auth.currentUser!.isAdmin) {
      debugPrint('[NAV] BOOT -> ADMIN');
      Get.offAllNamed(AppRoutes.adminHome);
    } else {
      debugPrint('[NAV] BOOT -> USER');
      Get.offAllNamed(AppRoutes.userHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onFinished: () {
          if (!mounted) return;
          if (!_splashDone) {
            setState(() => _splashDone = true);
            _restore();
          }
        },
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
