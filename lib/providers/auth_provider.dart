import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // Role stored here after login or signup
  String _role = 'User';
  String get role => _role;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  // ─────────────────────────────
  // SIGN UP
  // ─────────────────────────────
  Future<void> createAccount(BuildContext context, String selectedRole) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar(context, 'Please fill all fields');
      return;
    }
    if (password != confirm) {
      _showSnackbar(context, 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      _showSnackbar(context, 'Password must be at least 6 characters');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      // 2. Save user + role to Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': 'No Name',
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        _showSnackbar(context, 'Account created! Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showSnackbar(context, _errorMessage(e.code));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // LOGIN
  // ─────────────────────────────
  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showSnackbar(context, 'Email is required');
      return;
    }
    if (password.isEmpty) {
      _showSnackbar(context, 'Password is required');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch role from Firestore after login
      final uid = userCredential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _role = doc.data()?['role'] ?? 'User';
      }

      notifyListeners();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showSnackbar(context, _errorMessage(e.code));
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // LOGOUT
  // ─────────────────────────────
  Future<void> logout() async {
    _role = 'User';
    notifyListeners();
    await _auth.signOut();
  }

  // ─────────────────────────────
  // HELPERS
  // ─────────────────────────────
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Something went wrong. Try again';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}