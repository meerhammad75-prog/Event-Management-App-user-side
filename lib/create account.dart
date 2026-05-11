import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class CreateScreen extends StatelessWidget {
  static const routeName = '/create';

  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.black45;
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    InputDecoration inputDecoration({required String hint, Widget? suffix}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCC2222)),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // ── Title ──
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      children: [
                        const TextSpan(
                          text: 'Create ',
                          style: TextStyle(color: Color(0xFFCC2222)),
                        ),
                        TextSpan(
                          text: 'Account',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width * 0.33,
                    ),
                    child: Text(
                      'Enter given detail to create your account',
                      style: TextStyle(color: subtleColor, fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // ── Email ──
                  Text(
                    'Email',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: authProvider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: textColor),
                    decoration: inputDecoration(hint: 'Example23@gmail.com'),
                  ),

                  const SizedBox(height: 20),

                  // ── Password ──
                  Text(
                    'Password',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: authProvider.passwordController,
                    obscureText: authProvider.obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: inputDecoration(
                      hint: 'Enter your password',
                      suffix: IconButton(
                        icon: Icon(
                          authProvider.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: subtleColor,
                        ),
                        onPressed: authProvider.togglePasswordVisibility,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Confirm Password ──
                  Text(
                    'Confirm Password',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: authProvider.confirmPasswordController,
                    obscureText: authProvider.obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: inputDecoration(
                      hint: 'Re-enter your password',
                      suffix: IconButton(
                        icon: Icon(
                          authProvider.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: subtleColor,
                        ),
                        onPressed: authProvider.togglePasswordVisibility,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Continue button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                        await authProvider.createAccount(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF3232),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Continue',
                          style: TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 33),

                  // ── OR ──
                  Center(
                    child: Text(
                      'OR',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Google button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : () {},
                      icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 24,
                          height: 24),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 14, color: subtleColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Login link ──
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: subtleColor),
                          ),
                          TextSpan(
                            text: 'Login',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFCF3232),
                              color: Color(0xFFCF3232),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}