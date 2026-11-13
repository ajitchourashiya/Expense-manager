import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/app.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final TextEditingController confirmController =
  TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT REGISTRATION
  // ============================================================

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Please complete all fields.',
      );
      return;
    }

    if (phone.length != 10) {
      _showMessage(
        'Mobile number must be exactly 10 digits.',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must be at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();

    if (auth.loading) {
      return;
    }

    // ----------------------------------------------------------
    // REGISTER
    // ----------------------------------------------------------

    debugPrint('[REGISTER] Starting registration...');

    final success = await auth.register(
      name,
      phone,
      email,
      password,
    );

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (success) {
      debugPrint(
        '[REGISTER] Registration successful -> APPROVED',
      );

      await _showRegistrationSuccess();

      if (!mounted) {
        return;
      }

      // Registration complete.
      // User is sent to Login screen.
      debugPrint(
        '[NAV] REGISTER SUCCESS -> LOGIN',
      );

      Get.offAllNamed(
        AppRoutes.login,
      );

      return;
    }

    // ----------------------------------------------------------
    // FAILURE
    // ----------------------------------------------------------

    _showMessage(
      auth.error ?? 'Registration failed.',
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showRegistrationSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Successfully Registered',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // content: const Text(
          //   'Your account has been created successfully.\n\n'
          //       'Your account is already approved and you can '
          //       'login now using your registered email and password.',
          // ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'OK',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            40,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  const Text(
                    'Let’s get you started',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Your 10-digit mobile number can also '
                        'be used to sign in later.',
                    style: TextStyle(
                      color: AppColors.slate,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // NAME
                  // ==================================================

                  TextField(
                    controller: nameController,
                    textInputAction:
                    TextInputAction.next,
                    textCapitalization:
                    TextCapitalization.words,

                    decoration:
                    const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // MOBILE NUMBER
                  // ==================================================

                  TextField(
                    controller: phoneController,

                    keyboardType:
                    TextInputType.number,

                    textInputAction:
                    TextInputAction.next,

                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly,

                      LengthLimitingTextInputFormatter(
                        10,
                      ),
                    ],

                    decoration:
                    const InputDecoration(
                      labelText: 'Mobile number',
                      hintText:
                      'Enter 10-digit mobile number',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextField(
                    controller: emailController,

                    keyboardType:
                    TextInputType.emailAddress,

                    textInputAction:
                    TextInputAction.next,

                    autocorrect: false,

                    decoration:
                    const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  TextField(
                    controller: passwordController,

                    obscureText:
                    obscurePassword,

                    textInputAction:
                    TextInputAction.next,

                    decoration:
                    InputDecoration(
                      labelText: 'Password',

                      prefixIcon:
                      const Icon(
                        Icons.lock_outline_rounded,
                      ),

                      suffixIcon:
                      IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword =
                            !obscurePassword;
                          });
                        },

                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // CONFIRM PASSWORD
                  // ==================================================

                  TextField(
                    controller:
                    confirmController,

                    obscureText:
                    obscureConfirmPassword,

                    textInputAction:
                    TextInputAction.done,

                    onSubmitted: (_) {
                      final auth =
                      context.read<
                          AuthProvider>();

                      if (!auth.loading) {
                        submit();
                      }
                    },

                    decoration:
                    InputDecoration(
                      labelText:
                      'Confirm password',

                      prefixIcon:
                      const Icon(
                        Icons.verified_user_outlined,
                      ),

                      suffixIcon:
                      IconButton(
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword =
                            !obscureConfirmPassword;
                          });
                        },

                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // REGISTER BUTTON
                  // ==================================================

                  Consumer<AuthProvider>(
                    builder: (
                        context,
                        auth,
                        child,
                        ) {
                      return SizedBox(
                        width:
                        double.infinity,
                        height: 52,

                        child:
                        ElevatedButton(
                          onPressed:
                          auth.loading
                              ? null
                              : submit,

                          child: auth.loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,

                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                              Colors.white,
                            ),
                          )
                              : const Text(
                            'Create Account',

                            style:
                            TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FOOTER
                  // ==================================================

                  const Center(
                    child: Text(
                      'By creating an account, you agree '
                          'to use this app responsibly.',

                      textAlign:
                      TextAlign.center,

                      style: TextStyle(
                        color:
                        AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
//
// import '../../core/theme.dart';
// import '../../core/app.dart';
// import '../../providers/auth_provider.dart';
//
// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({
//     super.key,
//   });
//
//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final TextEditingController nameController =
//   TextEditingController();
//
//   final TextEditingController phoneController =
//   TextEditingController();
//
//   final TextEditingController emailController =
//   TextEditingController();
//
//   final TextEditingController passwordController =
//   TextEditingController();
//
//   final TextEditingController confirmController =
//   TextEditingController();
//
//   bool obscurePassword = true;
//   bool obscureConfirmPassword = true;
//
//   @override
//   void dispose() {
//     nameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmController.dispose();
//
//     super.dispose();
//   }
//
//   // ============================================================
//   // SUBMIT REGISTRATION
//   // ============================================================
//
//   Future<void> submit() async {
//     FocusScope.of(context).unfocus();
//
//     final name = nameController.text.trim();
//     final phone = phoneController.text.trim();
//     final email = emailController.text.trim();
//     final password = passwordController.text;
//     final confirmPassword = confirmController.text;
//
//     // ----------------------------------------------------------
//     // VALIDATION
//     // ----------------------------------------------------------
//
//     if (name.isEmpty ||
//         phone.isEmpty ||
//         email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty) {
//       _showMessage(
//         'Please complete all fields.',
//       );
//       return;
//     }
//
//     // EXACTLY 10 DIGITS
//     if (phone.length != 10) {
//       _showMessage(
//         'Mobile number must be exactly 10 digits.',
//       );
//       return;
//     }
//
//     if (password.length < 6) {
//       _showMessage(
//         'Password must be at least 6 characters.',
//       );
//       return;
//     }
//
//     if (password != confirmPassword) {
//       _showMessage(
//         'Passwords do not match.',
//       );
//       return;
//     }
//
//     if (!email.contains('@')) {
//       _showMessage(
//         'Please enter a valid email address.',
//       );
//       return;
//     }
//
//     final auth = context.read<AuthProvider>();
//
//     if (auth.loading) {
//       return;
//     }
//
//     // ----------------------------------------------------------
//     // REGISTER
//     // ----------------------------------------------------------
//
//     final success = await auth.register(
//       name,
//       phone,
//       email,
//       password,
//     );
//
//     if (!mounted) {
//       return;
//     }
//
//     // ----------------------------------------------------------
//     // SUCCESS
//     // ----------------------------------------------------------
//
//     if (success) {
//       await _showRegistrationSuccess();
//
//       if (!mounted) {
//         return;
//       }
//
//       // Registration is complete and Firebase is already signed out.
//       // Always clear the register route and return to Login.
//       debugPrint('[NAV] REGISTER SUCCESS -> LOGIN');
//       Get.offAllNamed(AppRoutes.login);
//
//       return;
//     }
//
//     // ----------------------------------------------------------
//     // FAILURE
//     // ----------------------------------------------------------
//
//     _showMessage(
//       auth.error ?? 'Registration failed.',
//     );
//   }
//
//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================
//
//   Future<void> _showRegistrationSuccess() async {
//     await showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(18),
//           ),
//           title: Row(
//             children: const [
//               Icon(
//                 Icons.check_circle_rounded,
//                 color: AppColors.success,
//                 size: 28,
//               ),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   'Registration Submitted',
//                 ),
//               ),
//             ],
//           ),
//           content: const Text(
//             'Your account has been created successfully '
//                 'and sent to the admin for approval.\n\n'
//                 'You can login after the admin approves your '
//                 'registration.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//               child: const Text(
//                 'OK',
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ============================================================
//   // MESSAGE
//   // ============================================================
//
//   void _showMessage(String message) {
//     if (!mounted) {
//       return;
//     }
//
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(
//         SnackBar(
//           content: Text(message),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Create account',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//
//       body: SafeArea(
//         child: SingleChildScrollView(
//           keyboardDismissBehavior:
//           ScrollViewKeyboardDismissBehavior.onDrag,
//
//           padding: const EdgeInsets.fromLTRB(
//             24,
//             10,
//             24,
//             40,
//           ),
//
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(
//                 maxWidth: 520,
//               ),
//
//               child: Column(
//                 crossAxisAlignment:
//                 CrossAxisAlignment.start,
//
//                 children: [
//                   // ==================================================
//                   // HEADER
//                   // ==================================================
//
//                   const Text(
//                     'Let’s get you started',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//
//                   const SizedBox(height: 7),
//
//                   const Text(
//                     'Your 10-digit mobile number can also '
//                         'be used to sign in later.',
//                     style: TextStyle(
//                       color: AppColors.slate,
//                     ),
//                   ),
//
//                   const SizedBox(height: 28),
//
//                   // ==================================================
//                   // NAME
//                   // ==================================================
//
//                   TextField(
//                     controller: nameController,
//                     textInputAction:
//                     TextInputAction.next,
//                     textCapitalization:
//                     TextCapitalization.words,
//
//                     decoration:
//                     const InputDecoration(
//                       labelText: 'Full name',
//                       prefixIcon: Icon(
//                         Icons.badge_outlined,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 14),
//
//                   // ==================================================
//                   // MOBILE NUMBER
//                   // ==================================================
//
//                   TextField(
//                     controller: phoneController,
//
//                     keyboardType:
//                     TextInputType.number,
//
//                     textInputAction:
//                     TextInputAction.next,
//
//                     // ONLY DIGITS
//                     inputFormatters: [
//                       FilteringTextInputFormatter
//                           .digitsOnly,
//
//                       // MAXIMUM 10 DIGITS
//                       LengthLimitingTextInputFormatter(
//                         10,
//                       ),
//                     ],
//
//                     decoration:
//                     const InputDecoration(
//                       labelText:
//                       'Mobile number',
//                       hintText:
//                       'Enter 10-digit mobile number',
//                       prefixIcon: Icon(
//                         Icons.phone_outlined,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 14),
//
//                   // ==================================================
//                   // EMAIL
//                   // ==================================================
//
//                   TextField(
//                     controller: emailController,
//
//                     keyboardType:
//                     TextInputType.emailAddress,
//
//                     textInputAction:
//                     TextInputAction.next,
//
//                     autocorrect: false,
//
//                     decoration:
//                     const InputDecoration(
//                       labelText:
//                       'Email address',
//                       prefixIcon: Icon(
//                         Icons.email_outlined,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 14),
//
//                   // ==================================================
//                   // PASSWORD
//                   // ==================================================
//
//                   TextField(
//                     controller: passwordController,
//
//                     obscureText:
//                     obscurePassword,
//
//                     textInputAction:
//                     TextInputAction.next,
//
//                     decoration:
//                     InputDecoration(
//                       labelText: 'Password',
//
//                       prefixIcon:
//                       const Icon(
//                         Icons
//                             .lock_outline_rounded,
//                       ),
//
//                       suffixIcon:
//                       IconButton(
//                         onPressed: () {
//                           setState(() {
//                             obscurePassword =
//                             !obscurePassword;
//                           });
//                         },
//
//                         icon: Icon(
//                           obscurePassword
//                               ? Icons
//                               .visibility_outlined
//                               : Icons
//                               .visibility_off_outlined,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 14),
//
//                   // ==================================================
//                   // CONFIRM PASSWORD
//                   // ==================================================
//
//                   TextField(
//                     controller:
//                     confirmController,
//
//                     obscureText:
//                     obscureConfirmPassword,
//
//                     textInputAction:
//                     TextInputAction.done,
//
//                     onSubmitted: (_) {
//                       final auth =
//                       context.read<
//                           AuthProvider>();
//
//                       if (!auth.loading) {
//                         submit();
//                       }
//                     },
//
//                     decoration:
//                     InputDecoration(
//                       labelText:
//                       'Confirm password',
//
//                       prefixIcon:
//                       const Icon(
//                         Icons
//                             .verified_user_outlined,
//                       ),
//
//                       suffixIcon:
//                       IconButton(
//                         onPressed: () {
//                           setState(() {
//                             obscureConfirmPassword =
//                             !obscureConfirmPassword;
//                           });
//                         },
//
//                         icon: Icon(
//                           obscureConfirmPassword
//                               ? Icons
//                               .visibility_outlined
//                               : Icons
//                               .visibility_off_outlined,
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // ==================================================
//                   // REGISTER BUTTON
//                   // ==================================================
//
//                   Consumer<AuthProvider>(
//                     builder: (
//                         context,
//                         auth,
//                         child,
//                         ) {
//                       return SizedBox(
//                         width:
//                         double.infinity,
//                         height: 52,
//
//                         child:
//                         ElevatedButton(
//                           onPressed:
//                           auth.loading
//                               ? null
//                               : submit,
//
//                           child: auth.loading
//                               ? const SizedBox(
//                             width: 22,
//                             height: 22,
//
//                             child:
//                             CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color:
//                               Colors.white,
//                             ),
//                           )
//                               : const Text(
//                             'Create Account',
//
//                             style:
//                             TextStyle(
//                               fontSize: 16,
//                               fontWeight:
//                               FontWeight
//                                   .w700,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // ==================================================
//                   // FOOTER
//                   // ==================================================
//
//                   const Center(
//                     child: Text(
//                       'By creating an account, you agree '
//                           'to use this app responsibly.',
//
//                       textAlign:
//                       TextAlign.center,
//
//                       style: TextStyle(
//                         color:
//                         AppColors.slate,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }