import 'dart:convert';
import 'dart:async';
import '../database/db_helper.dart';

class InAppNotification {
  final int? id;
  final int? userId;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  InAppNotification({this.id, this.userId, this.title, this.body, this.data, this.isRead = false, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'data': data == null ? null : jsonEncode(data),
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InAppNotification.fromMap(Map<String, dynamic> map) {
    return InAppNotification(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      title: map['title'] as String?,
      body: map['body'] as String?,
      data: map['data'] != null ? jsonDecode(map['data'] as String) as Map<String, dynamic> : null,
      isRead: (map['isRead'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

class InAppNotificationService {
  InAppNotificationService._();
  static final InAppNotificationService instance = InAppNotificationService._();

  final _dbHelper = DatabaseHelper.instance;
  final StreamController<int> _unreadController = StreamController<int>.broadcast();

  Stream<int> get unreadCountStream => _unreadController.stream;

  Future<int> addNotification(InAppNotification n) async {
    final db = await _dbHelper.database;
    return await db.insert('in_app_notifications', n.toMap());
  }

  Future<void> _notifyUnreadCount(int userId) async {
    final count = await getUnreadCount(userId);
    _unreadController.add(count);
  }

  Future<List<InAppNotification>> getNotificationsForUser(int userId, {int limit = 50}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('in_app_notifications', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC', limit: limit);
    return maps.map((m) => InAppNotification.fromMap(m)).toList();
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM in_app_notifications WHERE userId = ? AND isRead = 0', [userId]);
    if (res.isEmpty) return 0;
    final val = res.first['c'];
    if (val is int) return val;
    if (val is int?) return val ?? 0;
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<void> markAllRead(int userId) async {
    final db = await _dbHelper.database;
    await db.update('in_app_notifications', {'isRead': 1}, where: 'userId = ?', whereArgs: [userId]);
    _notifyUnreadCount(userId);
  }

  Future<void> markAsRead(int notificationId, int userId) async {
    final db = await _dbHelper.database;
    await db.update('in_app_notifications', {'isRead': 1}, where: 'id = ?', whereArgs: [notificationId]);
    await _notifyUnreadCount(userId);
  }

  // Call this after adding a notification to update listeners
  Future<void> addNotificationAndNotify(InAppNotification n) async {
    await addNotification(n);
    if (n.userId != null) await _notifyUnreadCount(n.userId!);
  }
}
