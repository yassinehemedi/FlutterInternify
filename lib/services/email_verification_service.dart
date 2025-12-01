import 'package:flutter/material.dart';
import 'package:internify/services/UserService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

import '../theme/app_theme.dart';
import '../screens/login_screen.dart';

class EmailVerificationController {
  String? _generatedToken;

  String? get generatedToken => _generatedToken;

  final UserService userService = UserService.instance;

  // Local helper: check SMTP configuration existence
  Future<bool> _isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('smtpHost') &&
        prefs.containsKey('smtpPort') &&
        prefs.containsKey('smtpUsername') &&
        prefs.containsKey('smtpPassword') &&
        prefs.containsKey('fromEmail');
  }

  // Local helper: generate a numeric code
  String _generateVerificationToken(String email) {
    final rnd = Random();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  // Local helper: send verification email using stored SMTP config
  Future<bool> _sendVerificationEmail(
      {required String recipientEmail,
      required String recipientName,
      required String verificationToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('smtpHost');
      final port = prefs.getInt('smtpPort');
      final username = prefs.getString('smtpUsername');
      final password = prefs.getString('smtpPassword');
      final from = prefs.getString('fromEmail');

      if (host == null ||
          port == null ||
          username == null ||
          password == null ||
          from == null) {
        debugPrint('EmailVerification: SMTP config not found; cannot send verification email.');
        return false;
      }

      final smtpServer = SmtpServer(host, port: port, username: username, password: password);
      final message = Message()
        ..from = Address(from, 'Internify')
        ..recipients.add(recipientEmail)
        ..subject = 'Vérification de votre email'
        ..text = 'Bonjour $recipientName,\n\nVotre code de vérification est: $verificationToken\n\nMerci.';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      debugPrint('EmailVerification send error: $e');
      return false;
    }
  }


  /// Send verification email
  Future<Map<String, dynamic>> sendVerificationEmail({
    required String email,
    required String userName,
  }) async {
    try {
      if (!await _isConfigured()) {
        // Fallback: run in TEST MODE when SMTP config is not present.
        // This prevents blocking sign-up flows in development or on devices
        // without SMTP set up. We generate and store the token locally and
        // return success so the UI can proceed (the token is included in
        // the returned message for developer/testing use).
        _generatedToken = _generateVerificationToken(email);
        debugPrint('EmailVerification: SMTP config missing; running in TEST MODE. Token: \\$_generatedToken');
        return {
          'success': true,
          'message': 'TEST MODE: Verification code is ${_generatedToken}',
        };
      }

      _generatedToken = _generateVerificationToken(email);

      bool success = await _sendVerificationEmail(
        recipientEmail: email,
        recipientName: userName,
        verificationToken: _generatedToken!,
      );

      return {
        'success': success,
        'message': success
            ? 'Verification email sent! Check your inbox.'
            : 'Failed to send email. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Verify token
  Future<Map<String, dynamic>> verifyToken({
    required String enteredToken,
    required String email,
  }) async {
    try {
      if (enteredToken.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Please enter the verification code',
        };
      }

      if (enteredToken.trim() != _generatedToken) {
        return {
          'success': false,
          'message': 'Invalid verification code. Please try again.',
        };
      }

      await userService.verifyUser(email);

      return {
        'success': true,
        'message': 'Email verified successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  /// Resend email
  Future<Map<String, dynamic>> resendEmail({
    required String email,
    required String userName,
  }) async {
    return await sendVerificationEmail(
      email: email,
      userName: userName,
    );
  }

  /// Handle send email with UI updates
  Future<void> handleSendEmail({
    required BuildContext context,
    required String email,
    required String userName,
    required Function(bool) setLoading,
    required Function(bool) setEmailSent,
  }) async {
    setLoading(true);
    final result = await sendVerificationEmail(
      email: email,
      userName: userName,
    );
    setEmailSent(result['success']);
    setLoading(false);
    showMessage(
      context,
      result['message'],
      isError: !result['success'],
    );
  }

  /// Handle verify token with UI updates
  Future<void> handleVerifyToken({
    required BuildContext context,
    required String enteredToken,
    required String email,
    required Function(bool) setLoading,
    required Function(bool) setVerified,
  }) async {
    setLoading(true);
    final result = await verifyToken(
      enteredToken: enteredToken,
      email: email,
    );
    setLoading(false);

    if (result['success']) {
      setVerified(true);
      showSuccessDialog(context, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } else {
      showMessage(context, result['message'], isError: true);
    }
  }

  /// Handle resend email with UI updates
  Future<void> handleResendEmail({
    required BuildContext context,
    required String email,
    required String userName,
    required Function(bool) setLoading,
  }) async {
    setLoading(true);
    final result = await resendEmail(
      email: email,
      userName: userName,
    );
    setLoading(false);
    showMessage(
      context,
      result['message'],
      isError: !result['success'],
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

  /// Show success dialog
  void showSuccessDialog(BuildContext context, VoidCallback onGoToLogin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text(
          'Your email has been verified successfully. You can now login to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onGoToLogin();
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }
}
