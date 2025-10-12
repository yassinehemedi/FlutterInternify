import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Email Service using Brevo SMTP
/// Sends verification emails using SMTP protocol
class EmailService {
  // Brevo SMTP Configuration
  static const String _smtpHost = 'smtp-relay.brevo.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = '855381002@smtp-brevo.com';
  static const String _smtpPassword = 'b5zjfnKRVtc6XpQm';

  // Your verified sender email
  static const String _senderEmail = 'yassinehemedi2@gmail.com';
  static const String _senderName = 'Internify Team';

  /// Generate verification token
  static String generateVerificationToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$email$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  /// Send verification email via Brevo SMTP
  static Future<bool> sendVerificationEmail({
    required String recipientEmail,
    required String recipientName,
    required String verificationToken,
  }) async {
    try {
      // Configure SMTP server
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false, // TLS is used instead
        allowInsecure: false,
      );

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Verify Your Internify Account'
        ..text = 'Your verification code is: $verificationToken. This code expires in 24 hours.'
        ..html = _getEmailTemplate(recipientName, verificationToken);

      // Send the email
      final sendReport = await send(message, smtpServer);

      print('✅ Email sent successfully to $recipientEmail');
      print('Response: ${sendReport.toString()}');
      return true;

    } on MailerException catch (e) {
      print('❌ Failed to send email: ${e.message}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }

  /// HTML email template
  static String _getEmailTemplate(String recipientName, String token) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f7fa;
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #003366 0%, #0066CC 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 32px;
            margin-bottom: 10px;
            font-weight: 700;
        }
        .header p {
            font-size: 16px;
            opacity: 0.9;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            margin-bottom: 20px;
            color: #333;
        }
        .message {
            color: #666;
            margin-bottom: 25px;
            line-height: 1.8;
        }
        .token-container {
            background: linear-gradient(135deg, #f0f4f8 0%, #e8f4f8 100%);
            border: 2px dashed #003366;
            border-radius: 10px;
            padding: 30px;
            margin: 30px 0;
            text-align: center;
        }
        .token-label {
            font-size: 14px;
            color: #666;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: 600;
        }
        .token {
            font-size: 32px;
            font-weight: bold;
            color: #003366;
            letter-spacing: 4px;
            font-family: 'Courier New', monospace;
            word-break: break-all;
            padding: 15px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,51,102,0.1);
        }
        .instructions {
            background-color: #e8f4f8;
            border-left: 4px solid #003366;
            padding: 20px;
            margin: 25px 0;
            border-radius: 6px;
        }
        .instructions h3 {
            color: #003366;
            margin-bottom: 12px;
            font-size: 16px;
        }
        .instructions ol {
            margin-left: 20px;
            color: #555;
        }
        .instructions li {
            margin: 8px 0;
        }
        .warning {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 6px;
            padding: 15px;
            margin: 25px 0;
            color: #856404;
        }
        .warning strong {
            display: block;
            margin-bottom: 5px;
        }
        .footer {
            background-color: #f5f7fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
        }
        .footer p {
            font-size: 13px;
            color: #666;
            margin: 5px 0;
        }
        .security-note {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            color: #888;
            font-size: 13px;
            line-height: 1.6;
        }
        @media only screen and (max-width: 600px) {
            .email-wrapper {
                border-radius: 0;
            }
            .header {
                padding: 30px 20px;
            }
            .header h1 {
                font-size: 24px;
            }
            .content {
                padding: 30px 20px;
            }
            .token {
                font-size: 24px;
                letter-spacing: 2px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <h1>🎉 Welcome to Internify!</h1>
            <p>Your journey starts here</p>
        </div>
        
        <div class="content">
            <div class="greeting">
                Hi <strong>$recipientName</strong>,
            </div>
            
            <div class="message">
                <p>Thank you for registering with <strong>Internify</strong>! We're thrilled to have you join our community.</p>
                <p style="margin-top: 15px;">To complete your registration and activate your account, please use the verification code below:</p>
            </div>
            
            <div class="token-container">
                <div class="token-label">Your Verification Code</div>
                <div class="token">$token</div>
            </div>
            
            <div class="instructions">
                <h3>📱 How to Verify Your Account:</h3>
                <ol>
                    <li>Open the <strong>Internify</strong> app on your device</li>
                    <li>Tap and hold to copy the verification code above</li>
                    <li>Paste the code in the verification screen</li>
                    <li>Click the <strong>"Verify Email"</strong> button</li>
                </ol>
            </div>
            
            <div class="warning">
                <strong>⚠️ Important:</strong>
                This verification code will expire in <strong>24 hours</strong>. Please complete your verification before then.
            </div>
            
            <div class="message">
                <p>If you didn't create an account with Internify, you can safely ignore this email.</p>
            </div>
            
            <div class="security-note">
                <p><strong>Security Tip:</strong> Never share your verification code with anyone. Internify will never ask for this code via phone or email.</p>
            </div>
            
            <div style="margin-top: 40px; color: #666;">
                <p>Best regards,</p>
                <p><strong>The Internify Team</strong></p>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>© 2025 Internify. All rights reserved.</strong></p>
            <p>This is an automated email. Please do not reply to this message.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Check if SMTP is configured
  static bool isConfigured() {
    return _smtpUsername.isNotEmpty &&
        _smtpPassword.isNotEmpty &&
        _senderEmail.isNotEmpty;
  }
}