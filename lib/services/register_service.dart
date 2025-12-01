
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../services/UserService.dart';
import '../theme/app_theme.dart';
import '../screens/verify_email_screen.dart';

class RegisterController {
  /// Validate email format
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

  /// Validate password strength
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  /// Validate phone
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?\d{7,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate role
  String? validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a role';
    }
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    return null;
  }

  /// Check if passwords match
  bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    return await userService.emailExists(email.trim());
  }

  /// Register user
  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final user = User(
        name: name.trim(),
        email: email.trim(),
        password: password,
        isVerified: false,
        phone: phone.trim(),
        role: role,
      );

      return await userService.registerUser(user);
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Handle complete registration flow
  Future<void> handleRegister({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String? role,
    required Function(bool) setLoading,
  }) async {
    // Validate form
    if (!formKey.currentState!.validate()) return;

    // Check if passwords match
    if (!passwordsMatch(password, confirmPassword)) {
      showMessage(context, 'Passwords do not match', isError: true);
      return;
    }

    setLoading(true);

    try {
      // Check if email already exists
      final exists = await emailExists(email);
      if (exists) {
        showMessage(context, 'Email already registered', isError: true);
        setLoading(false);
        return;
      }

      // Register user
      final registeredUser = await registerUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role!,
      );

      if (registeredUser != null) {
        setLoading(false);

        // Navigate to email verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(
              email: registeredUser.email,
              userName: registeredUser.name,
            ),
          ),
        );
      } else {
        showMessage(context, 'Registration failed', isError: true);
        setLoading(false);
      }
    } catch (e) {
      showMessage(context, 'An error occurred: $e', isError: true);
      setLoading(false);
    }
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