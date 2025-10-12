import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/SMSService.dart';
import '../screens/login_screen.dart';
import '../services/UserService.dart';
import '../theme/app_theme.dart';

class VerifySMSController {
  final BuildContext context;
  final UserService userService = UserService.instance;

  final Function(VoidCallback) setState;
  final String phoneNumber;
  final String userName;
  final String email;

  VerifySMSController({
    required this.context,
    required this.setState,
    required this.phoneNumber,
    required this.userName,
    required this.email,
  });

  bool isVerified = false;
  bool isLoading = false;
  bool smsSent = false;
  bool showPasswordSection = false;
  String? generatedCode;
  int resendCountdown = 0;

  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> sendVerificationSMS() async {
    if (!SMSService.isConfigured()) {
      showMessage('SMS service not configured. Please add your Brevo API key.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      generatedCode = SMSService.generateVerificationCode();

      bool success = await SMSService.sendVerificationSMS(
        phoneNumber: phoneNumber,
        verificationCode: generatedCode!,
      );

      setState(() {
        smsSent = success;
        isLoading = false;
      });

      if (success) {
        showMessage('Verification code sent to $phoneNumber');
        startResendCountdown();
      } else {
        showMessage('Failed to send SMS. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage('Error sending SMS: $e', isError: true);
    }
  }

  void startResendCountdown() {
    setState(() => resendCountdown = 60);

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => resendCountdown--);
      return resendCountdown > 0;
    });
  }

  Future<void> verifyCode(List<TextEditingController> codeControllers, List<FocusNode> focusNodes) async {
    final enteredCode = codeControllers.map((c) => c.text).join();

    if (enteredCode.length != 6) {
      showMessage('Please enter the complete 6-digit code', isError: true);
      return;
    }

    if (enteredCode != generatedCode) {
      showMessage('Invalid verification code. Please try again.', isError: true);
      for (var controller in codeControllers) {
        controller.clear();
      }
      focusNodes[0].requestFocus();
      return;
    }

    setState(() {
      isVerified = true;
      showPasswordSection = true;
    });

    showMessage('Code verified! Please enter your new password.');
  }

  Future<void> updatePassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showMessage('Please fill in both password fields', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      showMessage('Password must be at least 6 characters long', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await userService.updateUserPassword(
        email: email,
        newPassword: newPassword,
      );

      setState(() => isLoading = false);

      showSuccessDialog();
    } catch (e) {
      setState(() => isLoading = false);
      showMessage('Failed to update password: $e', isError: true);
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Password Updated!'),
          ],
        ),
        content: const Text(
          'Your password has been updated successfully. You can now login with your new password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void showMessage(String message, {bool isError = false}) {
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

  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }
}