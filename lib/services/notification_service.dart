import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<NotificationModel?> createNotification(NotificationModel n) async {
    final db = await _db;
    final id = await db.insert('notifications', n.toMap());
    return n.copyWith(idNotification: id);
  }

  Future<List<NotificationModel>> getNotificationsByRecipient(int userId) async {
    final db = await _db;
    final res = await db.query('notifications', where: 'recipientId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return res.map((m) => NotificationModel.fromMap(m)).toList();
  }

  Future<int> markAsRead(int id) async {
    final db = await _db;
    return await db.update('notifications', {'isRead': 1}, where: 'id_notification = ?', whereArgs: [id]);
  }

  Future<int> deleteNotification(int id) async {
    final db = await _db;
    return await db.delete('notifications', where: 'id_notification = ?', whereArgs: [id]);
  }

  Future<int> getUnreadCount(int userId) async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM notifications WHERE recipientId = ? AND isRead = 0', [userId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
