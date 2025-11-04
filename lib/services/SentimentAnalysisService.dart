import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Sentiment Analysis Service - LLM-Powered Only
/// Calls Python API to analyze reclamations
class SentimentAnalysisService {

  // 🔥 API Configuration - Set to your computer's IP
  // Your IP from ipconfig: 192.168.236.1
  static String _apiUrl = 'http://192.168.1.111:8000/analyze_priority';
  static const Duration _apiTimeout = Duration(seconds: 60);

  /// Change API URL dynamically (useful for testing)
  static void setApiUrl(String url) {
    _apiUrl = url;
    print('🔧 API URL updated to: $_apiUrl');
  }

  /// Main sentiment analysis - Calls LLM API ONLY
  static Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    if (text.trim().isEmpty) {
      print('⚠️ Empty text provided, returning neutral defaults');
      return _createResult('neutral', 3, 0.5, 'empty-text', 'medium');
    }

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 LLM ANALYSIS STARTED');
      print('📝 Text: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      print('🌐 API URL: $_apiUrl');
      print('⏰ Timeout: $_apiTimeout');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Call Python LLM API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': text}),
      ).timeout(_apiTimeout);

      print('📡 HTTP Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ LLM ANALYSIS SUCCESS!');
        print('🎯 Priority: ${data['priority']}');
        print('😊 Sentiment: ${data['sentiment']}');
        print('🤖 Method: LLM-based');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Map priority to stars (for compatibility)
        final stars = _priorityToStars(data['priority'] ?? 'medium');

        // Return LLM results ONLY
        return {
          'sentiment': data['sentiment'] ?? 'neutral',
          'stars': stars,
          'confidence': 0.9, // High confidence since it's from LLM
          'priority': data['priority'] ?? 'medium',
          'method': 'llm-api',
        };
      } else {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ LLM API ERROR');
        print('💥 Status Code: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        print('⚠️ FALLING BACK TO NEUTRAL DEFAULTS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Return neutral defaults on API error
        return _createResult('neutral', 3, 0.3, 'api-error', 'medium');
      }

    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💥 LLM API EXCEPTION');
      print('❌ Error: $e');
      print('📍 Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      print('⚠️ Returning neutral defaults');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Return neutral defaults on exception
      return _createResult('neutral', 3, 0.3, 'api-exception', 'medium');
    }
  }

  /// Convert priority to star rating
  static int _priorityToStars(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 1; // Critical = 1 star
      case 'medium':
        return 3; // Medium = 3 stars
      case 'low':
        return 5; // Low priority/positive = 5 stars
      default:
        return 3;
    }
  }

  /// Create result map
  static Map<String, dynamic> _createResult(
      String sentiment,
      int stars,
      double confidence,
      String method,
      String priority,
      ) {
    return {
      'sentiment': sentiment,
      'stars': stars,
      'confidence': confidence.clamp(0.0, 1.0),
      'method': method,
      'priority': priority,
    };
  }

  /// Update complaint in database with LLM analysis
  static Future<void> analyzeAndUpdateComplaint(
      Database db,
      int complaintId,
      String complaintText,
      ) async {
    print('\n📋 Analyzing complaint #$complaintId');

    final analysis = await analyzeSentiment(complaintText);

    print('💾 Updating database for complaint #$complaintId');
    print('   - Sentiment: ${analysis['sentiment']}');
    print('   - Priority: ${analysis['priority']}');
    print('   - Stars: ${analysis['stars']}');
    print('   - Method: ${analysis['method']}');

    await db.update(
      'reclamations',
      {
        'sentiment': analysis['sentiment'],
        'stars': analysis['stars'],
        'confidence': analysis['confidence'],
        'priority': analysis['priority'],
        'analysis_method': analysis['method'],
        'analyzed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [complaintId],
    );

    print('✅ Database updated for complaint #$complaintId\n');
  }

  /// Analyze all pending complaints using LLM
  static Future<int> analyzeAllPending(Database db) async {
    print('\n🚀 Starting batch analysis of pending complaints...');

    final complaints = await db.query(
      'reclamations',
      where: 'sentiment IS NULL OR sentiment = ?',
      whereArgs: [''],
    );

    print('📊 Found ${complaints.length} pending complaints');

    int analyzed = 0;
    int failed = 0;

    for (var i = 0; i < complaints.length; i++) {
      final complaint = complaints[i];
      final id = complaint['id'] as int;
      final text = complaint['description'] as String? ?? '';

      print('\n[${ i + 1}/${complaints.length}] Processing complaint #$id');

      if (text.isNotEmpty) {
        try {
          await analyzeAndUpdateComplaint(db, id, text);
          analyzed++;
          print('✅ Success ($analyzed/${complaints.length})');
        } catch (e) {
          failed++;
          print('❌ Failed: $e');
        }

        // Small delay to avoid overwhelming API
        await Future.delayed(Duration(milliseconds: 500));
      } else {
        print('⚠️ Skipped (empty text)');
      }
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📈 BATCH ANALYSIS COMPLETE');
    print('✅ Analyzed: $analyzed');
    print('❌ Failed: $failed');
    print('📊 Total: ${complaints.length}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return analyzed;
  }

  /// Get sentiment statistics
  static Future<Map<String, int>> getSentimentStats(Database db) async {
    final results = await db.rawQuery('''
      SELECT sentiment, COUNT(*) as count
      FROM reclamations
      WHERE sentiment IS NOT NULL
      GROUP BY sentiment
    ''');

    final stats = {
      'positive': 0,
      'neutral': 0,
      'negative': 0,
      ...Map.fromEntries(
        results.map((r) => MapEntry(
          r['sentiment'] as String,
          r['count'] as int,
        )),
      ),
    };

    print('📊 Sentiment Statistics:');
    stats.forEach((key, value) {
      print('   - ${key.toUpperCase()}: $value');
    });

    return stats;
  }

  /// Get complaints by priority
  static Future<List<Map<String, dynamic>>> getComplaintsByPriority(
      Database db,
      String priority,
      ) async {
    final results = await db.query(
      'reclamations',
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'analyzed_at DESC',
    );

    print('🔍 Found ${results.length} complaints with priority: $priority');
    return results;
  }

  /// Get CRITICAL complaints only (high priority + negative)
  static Future<List<Map<String, dynamic>>> getCriticalComplaints(Database db) async {
    final results = await db.query(
      'reclamations',
      where: 'priority = ? AND sentiment = ?',
      whereArgs: ['high', 'negative'],
      orderBy: 'analyzed_at DESC',
    );

    print('🚨 Found ${results.length} CRITICAL complaints');
    return results;
  }

  /// Test LLM connection with detailed diagnostics
  static Future<bool> testConnection() async {
    print('\n🧪 Testing LLM API connection...');
    print('🌐 Target: $_apiUrl');

    try {
      // Test 1: Check health endpoint first
      final healthUrl = _apiUrl.replaceAll('/analyze_priority', '/health');
      print('\n📡 Step 1: Testing health endpoint...');
      print('   URL: $healthUrl');

      final healthStart = DateTime.now();
      final healthResponse = await http.get(Uri.parse(healthUrl))
          .timeout(Duration(seconds: 5));
      final healthTime = DateTime.now().difference(healthStart).inMilliseconds;

      print('   Status: ${healthResponse.statusCode}');
      print('   Time: ${healthTime}ms');
      print('   Body: ${healthResponse.body}');

      if (healthResponse.statusCode != 200) {
        print('❌ Health check failed!');
        return false;
      }

      print('✅ Health check passed!');

      // Test 2: Try actual analysis with short text
      print('\n📡 Step 2: Testing analysis endpoint...');
      final analysisStart = DateTime.now();
      final testText = 'Test';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': testText}),
      ).timeout(Duration(seconds: 60));

      final analysisTime = DateTime.now().difference(analysisStart).inMilliseconds;

      print('   Status: ${response.statusCode}');
      print('   Time: ${analysisTime}ms');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['priority'] != null && data['sentiment'] != null) {
          print('✅ LLM API is working correctly!');
          print('⚡ Average response time: ${analysisTime}ms');

          if (analysisTime > 30000) {
            print('⚠️ WARNING: API is very slow (>${analysisTime/1000}s)');
            print('   Consider increasing timeout or optimizing API');
          }

          return true;
        }
      }

      print('⚠️ Unexpected response format');
      return false;

    } catch (e) {
      print('❌ Connection test failed: $e');
      print('\n💡 Troubleshooting:');
      print('   1. Check if FastAPI is running: uvicorn main:app --host 0.0.0.0 --port 8000');
      print('   2. Verify IP address in code matches your computer\'s IP');
      print('   3. Ensure phone and computer are on same WiFi');
      print('   4. Check firewall settings on your computer');
      return false;
    }
  }
}

// Easy extension to use
extension SentimentExtension on String {
  Future<Map<String, dynamic>> get sentiment async =>
      await SentimentAnalysisService.analyzeSentiment(this);
}