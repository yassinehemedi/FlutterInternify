// File: services/sms_service.dart

import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// SMS Service using Infobip API
class SMSService {
  // ================== CONFIG ==================
  static const String _apiKey = 'd3f09d4b2aab23936bea5e2d11f2ac24-f507039c-3912-4af8-a5d6-fcbad9bbe1fa';
  static const String _baseUrl = 'https://xk4nwe.api.infobip.com';
  // Example: 'https://pevvme.api.infobip.com'

  // ================== GENERATE VERIFICATION CODE ==================
  static String generateVerificationCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // 100000 to 999999
    return code.toString();
  }

  // ================== SEND SMS ==================
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
            "from": "Internify", // max 11 chars or number
            "destinations": [
              {"to": formattedPhone}
            ],
            "text":
            "Your Internify verification code is: $verificationCode\nThis code expires in 10 minutes.\nDo not share this code with anyone."
          }
        ]
      };

      print('📡 Sending SMS to: $formattedPhone');
      print('🌐 URL: $url');
      print('🧾 Headers: ${{
        'Authorization': 'App $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }}');
      print('📦 Body: ${jsonEncode(body)}');

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

  // ================== FORMAT PHONE ==================
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

  // ================== CHECK CONFIG ==================
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _baseUrl.isNotEmpty;
  }
}
