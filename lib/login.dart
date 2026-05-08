import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'helpers/auth_background.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: AuthBackground(
        child: SafeArea(
        child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
    child: Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'Login ', style: TextStyle(color: Colors.red)),
                        TextSpan(text: 'To Your Account', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.29),
                    child: Text(
                      'Enter given detail to login to your account',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  SizedBox(height: 70),

                  // Email
                  Text('Phone number', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  TextField(
                    controller: authProvider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Example23@gmail.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF9A9A9A)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Password
                  Text('Password', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  TextField(
                    controller: authProvider.passwordController,
                    obscureText: authProvider.obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF9A9A9A)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(authProvider.obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: authProvider.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Forgot Password?',
                          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                  SizedBox(height: 33),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                        final email = authProvider.emailController.text.trim();
                        final password = authProvider.passwordController.text;

                        // EMAIL VALIDATION
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Email is required")),
                          );
                          return;
                        }

                        if (!email.contains("@") || !email.contains(".")) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Enter a valid email")),
                          );
                          return;
                        }

                        // PASSWORD VALIDATION
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Password is required")),
                          );
                          return;
                        }

                        if (password.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Password must be at least 6 characters")),
                          );
                          return;
                        }

                        // CALL ORIGINAL LOGIN FUNCTION
                        await authProvider.login(context);
                      },                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCF3232),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: authProvider.isLoading
                          ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text('Login', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 55),
                  Center(child: Text("OR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  SizedBox(height: 43),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : () {},
                      icon: Image.network('https://www.google.com/favicon.ico', width: 24, height: 24),
                      label: Text('Continue with google', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                  SizedBox(height: 85),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 13),
                        children: [
                          TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.black54)),
                          TextSpan(
                            text: "Create Account",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.pushReplacementNamed(context, '/create'),
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
    ));
  }
}