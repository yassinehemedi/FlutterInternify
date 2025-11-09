
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'UserService.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/SmsScreen.dart';

class LoginController {
  /// Validate email format
  ///
  final UserService userService = UserService.instance;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  /// Login user
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      return await userService.loginUser(
        email.trim(),
        password,
      );
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      return await userService.getUserByEmail(email.trim());
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Handle complete login flow
  Future<void> handleLogin({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String email,
    required String password,
    required Function(bool) setLoading,
  }) async {
    // Validate form
    if (!formKey.currentState!.validate()) return;

    setLoading(true);

    try {
      // Attempt to login
      final user = await loginUser(
        email: email,
        password: password,
      );

      if (user != null) {
        // Check if email is verified
        if (!user.isVerified) {
          setLoading(false);
          showMessage(
            context,
            'Please verify your email before logging in',
            isError: true,
          );
          return;
        }

        // Login successful
        setLoading(false);
        showSuccessDialog(context, user);
      } else {
        setLoading(false);
        showMessage(context, 'Invalid email or password', isError: true);
      }
    } catch (e) {
      setLoading(false);
      showMessage(context, 'An error occurred: $e', isError: true);
    }
  }

  /// Handle forgot password flow
  Future<void> handleForgotPassword({
    required BuildContext context,
    required String email,
  }) async {
    if (email.isEmpty) {
      showMessage(context, 'Please enter your email first', isError: true);
      return;
    }

    final user = await getUserByEmail(email);

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifySMSScreen(
            phoneNumber: user.phone ?? '',
            userName: user.name,
            email: user.email,
          ),
        ),
      );
    } else {
      showMessage(context, 'No account found with this email', isError: true);
    }
  }

  /// Show success dialog
  void showSuccessDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Welcome, ${user.name}!'),
            ),
          ],
        ),
        content: const Text(
          'You have successfully logged into your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Show snackbar message
  void showMessage(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.accentBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
