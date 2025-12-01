import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:internify/services/in_app_notification_service.dart';

/// NotificationService
/// - Tries to send a push via FCM HTTP API if a server key and user FCM token are available
/// - Falls back to a local notification when push cannot be sent
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Provide your FCM server key via --dart-define=FCM_SERVER_KEY=your_key when running
  static const String _fcmServerKey = String.fromEnvironment('FCM_SERVER_KEY', defaultValue: '');

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  /// Notify a user about a status change
  /// userId: the target user id
  /// newStatus: textual status
  Future<void> notifyStatusChange(int userId, String newStatus, {String? title, String? body}) async {
    final titleText = title ?? 'Update on your internship request';
    final bodyText = body ?? 'The status changed to: $newStatus';
    final payload = {'type': 'demand_status', 'status': newStatus};

    // Persist in-app notification for the user
    try {
      final n = InAppNotification(userId: userId, title: titleText, body: bodyText, data: payload, isRead: false);
      await InAppNotificationService.instance.addNotificationAndNotify(n);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to save in-app notification: $e');
    }

    // Also show a local notification for immediate attention
    await _showLocalNotification(titleText, bodyText, payload);
  }

  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    const android = AndroidNotificationDetails(
      'internship_demand_channel',
      'Internship demand',
      channelDescription: 'Notifications about internship demand status',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: ios);

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platform,
      payload: jsonEncode(data),
    );
  }
}
