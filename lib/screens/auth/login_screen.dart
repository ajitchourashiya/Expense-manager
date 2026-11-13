import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final id = TextEditingController();
  final pass = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    id.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (id.text.trim().isEmpty || pass.text.isEmpty) {
      _msg('Enter your email/mobile and password.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(id.text.trim(), pass.text);

    if (!mounted) return;

    if (!ok) {
      debugPrint('[NAV] LOGIN FAILED -> STAY LOGIN');
      _msg(auth.error ?? 'Login failed.');
      return;
    }

    final user = auth.currentUser!;
    final role = user.role.toLowerCase().trim();

    if (role == 'admin' || role == 'super_admin') {
      debugPrint('[NAV] LOGIN SUCCESS -> ADMIN ($role)');
      Get.offAllNamed(AppRoutes.adminHome);
    } else {
      debugPrint('[NAV] LOGIN SUCCESS -> USER ($role)');
      Get.offAllNamed(AppRoutes.userHome);
    }
  }

  void _msg(String message) {
    if (!mounted) return;

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.danger),
            SizedBox(width: 10),
            Expanded(child: Text('Login failed')),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _forgot() async {
    final email = id.text.trim();
    if (!email.contains('@')) {
      _msg('Enter your email address to reset the password.');
      return;
    }

    final ok = await context.read<AuthProvider>().resetPassword(email);
    if (!mounted) return;
    _msg(ok ? 'Password reset email sent.' : 'Could not send reset email.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: AppLogo(size: 64),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Sign in to continue managing your expenses.',
                    style: TextStyle(color: AppColors.slate, fontSize: 14.5),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: id,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email or mobile number',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: pass,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgot,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => ElevatedButton(
                      onPressed: auth.loading ? null : submit,
                      child: auth.loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'NEW HERE?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () {
                      debugPrint('[NAV] LOGIN -> REGISTER');
                      Get.toNamed(AppRoutes.register);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // 2. URL define karein
                            final Uri url = Uri.parse('https://riditechsolution.in/');

                            // 3. Check karein agar URL open ho sakta hai toh launch karein
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication, // Isse browser mein sahi se khulega
                              );
                            } else {
                              throw Exception('Could not launch $url');
                            }
                          },
                          child: const Text(
                            'Developed by Riditech Solutions',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: Colors.blue, // Optional: User ko pata chale ki yeh click hone wala link hai
                              decoration: TextDecoration.underline, // Optional: Underline dene ke liye
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expense Manager • v1.0.0',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  // const Center(
                  //   child: Column(
                  //     children: [
                  //       Text(
                  //         'Developed by Intern Choice',
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.w700,
                  //           fontSize: 12.5,
                  //         ),
                  //       ),
                  //       SizedBox(height: 4),
                  //       Text(
                  //         'Expense Manager  •  v1.0.0',
                  //         style: TextStyle(
                  //           color: AppColors.slate,
                  //           fontSize: 11.5,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
