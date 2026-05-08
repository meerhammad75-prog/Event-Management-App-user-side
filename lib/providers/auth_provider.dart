import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';
  static const String _isLoggedInKey = 'is_logged_in';

  // ================= VALIDATION =================

  String? validateEmail(String email) {
    if (email.isEmpty) return "Email is required";

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      return "Enter a valid email";
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) return "Password is required";
    if (password.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  // ================= CREATE ACCOUNT =================

  Future<void> createAccount(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, emailController.text);
    await prefs.setString(_userPasswordKey, passwordController.text);
    await prefs.setBool(_isLoggedInKey, false);

    isLoading = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account created successfully!")),
      );

      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ================= LOGIN =================

  Future<void> login(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_userEmailKey);
    final savedPassword = prefs.getString(_userPasswordKey);

    if (savedEmail == emailController.text &&
        savedPassword == passwordController.text) {
      await prefs.setBool(_isLoggedInKey, true);

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful!")),
        );

        emailController.clear();
        passwordController.clear();

        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid email or password")),
        );
      }
    }
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
    
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}