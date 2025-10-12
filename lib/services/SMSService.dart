// ==================== SMS SERVICE ====================
// File: services/sms_service.dart

import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// SMS Service using Infobip API
class SMSService {
  // Infobip API configuration
  static const String _apiKey = 'c5c984d58926ebf869d87652577cb968-ec87a5ab-ab79-44f5-b0e9-aed045d5c2cb';
  static const String _baseUrl = 'https://pevvme.api.infobip.com';
  // e.g., 'https://YOUR_ENVIRONMENT.api.infobip.com'

  /// Generate 6-digit verification code
  static String generateVerificationCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000 to 999999
    return code.toString();
  }

  /// Send SMS verification code via Infobip
  static Future<bool> sendVerificationSMS({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);

      final url = Uri.parse('$_baseUrl/sms/2/text/advanced');

      final body = {
        "messages": [
          {
            "from": "Internify", // Sender name (max 11 chars) or number
            "destinations": [
              {"to": formattedPhone}
            ],
            "text":
            "Your Internify verification code is: $verificationCode\nThis code expires in 10 minutes.\nDo not share this code with anyone."
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'App $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SMS sent successfully to $formattedPhone');
        print('Response: ${response.body}');
        return true;
      } else {
        print('❌ Failed to send SMS: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Format phone number to international format
  static String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('216')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+216$cleaned';
      }
    }
    return cleaned;
  }

  /// Check if SMS service is configured
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _baseUrl.isNotEmpty;
  }


}
