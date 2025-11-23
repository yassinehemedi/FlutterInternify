import 'package:http/http.dart' as http;
import 'dart:convert';

/// Sentiment Analysis Service - Simple sentiment detection
/// Analyzes comments and returns: positive, neutral, or negative
class SentimentAnalysisService {

  // 🔥 Update this with your computer's IP address
  static String _apiUrl = 'http://192.168.7.136:8001/analyze_sentiment';
  static const Duration _apiTimeout = Duration(seconds: 30);

  /// Change API URL dynamically
  static void setApiUrl(String url) {
    _apiUrl = url;
    print('🔧 API URL updated to: $_apiUrl');
  }

  /// Analyze sentiment of a comment
  /// Returns: 'positive', 'neutral', or 'negative'
  static Future<String> analyzeSentiment(String comment) async {
    if (comment.trim().isEmpty) {
      print('⚠️ Empty comment provided, returning neutral');
      return 'neutral';
    }

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 SENTIMENT ANALYSIS STARTED');
      print('📝 Comment: ${comment.substring(0, comment.length > 100 ? 100 : comment.length)}...');
      print('🌐 API URL: $_apiUrl');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      ).timeout(_apiTimeout);

      print('📡 HTTP Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sentiment = data['sentiment'] ?? 'neutral';

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ SENTIMENT ANALYSIS SUCCESS!');
        print('😊 Sentiment: $sentiment');
        print('⏱️ Processing time: ${data['processing_time']}s');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return sentiment;
      } else {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ API ERROR');
        print('💥 Status Code: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        print('⚠️ Returning neutral as fallback');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return 'neutral';
      }

    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💥 API EXCEPTION');
      print('❌ Error: $e');
      print('📍 Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      print('⚠️ Returning neutral as fallback');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return 'neutral';
    }
  }

  /// Get detailed sentiment analysis with metadata
  static Future<Map<String, dynamic>> analyzeSentimentDetailed(String comment) async {
    if (comment.trim().isEmpty) {
      return {
        'sentiment': 'neutral',
        'comment': comment,
        'processing_time': 0.0,
      };
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': comment}),
      ).timeout(_apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'sentiment': 'neutral',
          'comment': comment,
          'processing_time': 0.0,
          'error': 'API returned status ${response.statusCode}',
        };
      }

    } catch (e) {
      return {
        'sentiment': 'neutral',
        'comment': comment,
        'processing_time': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    print('\n🧪 Testing Sentiment API connection...');
    print('🌐 Target: $_apiUrl');

    try {
      // Test health endpoint
      final healthUrl = _apiUrl.replaceAll('/analyze_sentiment', '/health');
      print('\n📡 Step 1: Testing health endpoint...');
      print('   URL: $healthUrl');

      final healthStart = DateTime.now();
      final healthResponse = await http.get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));
      final healthTime = DateTime.now().difference(healthStart).inMilliseconds;

      print('   Status: ${healthResponse.statusCode}');
      print('   Time: ${healthTime}ms');
      print('   Body: ${healthResponse.body}');

      if (healthResponse.statusCode != 200) {
        print('❌ Health check failed!');
        return false;
      }

      print('✅ Health check passed!');

      // Test actual analysis
      print('\n📡 Step 2: Testing sentiment analysis...');
      final analysisStart = DateTime.now();
      const testComment = 'This is great!';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comment': testComment}),
      ).timeout(const Duration(seconds: 30));

      final analysisTime = DateTime.now().difference(analysisStart).inMilliseconds;

      print('   Status: ${response.statusCode}');
      print('   Time: ${analysisTime}ms');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sentiment'] != null) {
          print('✅ Sentiment API is working correctly!');
          print('⚡ Response time: ${analysisTime}ms');
          return true;
        }
      }

      print('⚠️ Unexpected response format');
      return false;

    } catch (e) {
      print('❌ Connection test failed: $e');
      print('\n💡 Troubleshooting:');
      print('   1. Start the API: python -m uvicorn main:app --host 0.0.0.0 --port 8000');
      print('   2. Update the IP address in the code');
      print('   3. Ensure phone and computer are on same WiFi');
      print('   4. Check firewall settings');
      return false;
    }
  }

  /// Get sentiment emoji
  static String getSentimentEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return '😊';
      case 'negative':
        return '😞';
      case 'neutral':
      default:
        return '😐';
    }
  }

  /// Get sentiment color (for UI)
  static String getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return '#4CAF50'; // Green
      case 'negative':
        return '#F44336'; // Red
      case 'neutral':
      default:
        return '#9E9E9E'; // Gray
    }
  }
}

// Extension for easy usage
extension SentimentExtension on String {
  Future<String> get sentiment async =>
      await SentimentAnalysisService.analyzeSentiment(this);
}