import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'helpers/auth_background.dart';

class CreateScreen extends StatelessWidget {
  static const routeName = '/create';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'Create ',
                            style: TextStyle(color: Colors.red),
                          ),
                          TextSpan(
                            text: 'Account',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: EdgeInsets.only(
                        right: MediaQuery.of(context).size.width * 0.33,
                      ),
                      child: const Text(
                        'Enter given detail to create your account',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 70),

                    const Text('Email',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: authProvider.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Example23@gmail.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          const BorderSide(color: Color(0xFF9A9A9A)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text('Password',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: authProvider.passwordController,
                      obscureText: authProvider.obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            authProvider.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: authProvider.togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text('Confirm Password',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: authProvider.confirmPasswordController,
                      obscureText: authProvider.obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Re-enter your password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            authProvider.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: authProvider.togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                          final email =
                          authProvider.emailController.text.trim();
                          final password =
                              authProvider.passwordController.text;
                          final confirmPassword = authProvider
                              .confirmPasswordController.text;

                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Email is required")),
                            );
                            return;
                          }

                          if (!email.contains("@") ||
                              !email.contains(".")) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Enter a valid email")),
                            );
                            return;
                          }

                          if (password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text("Password is required")),
                            );
                            return;
                          }

                          if (password.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Password must be at least 6 characters")),
                            );
                            return;
                          }

                          if (confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Confirm password is required")),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text("Passwords do not match")),
                            );
                            return;
                          }

                          await authProvider.createAccount(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF3232),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 33),

                    const Center(child: Text("OR")),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading ? null : () {},
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 24,
                          height: 24,
                        ),
                        label: const Text(
                          'Continue with google',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            TextSpan(
                              text: "Login",
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFCF3232),
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    Navigator.pushReplacementNamed(
                                        context, '/login'),
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
      ),
    );
  }
}