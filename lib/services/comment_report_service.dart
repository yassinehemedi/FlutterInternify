import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/comment_report_model.dart';
import 'comment_service.dart';

class CommentReportService {
  static final CommentReportService instance = CommentReportService._init();
  CommentReportService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<CommentReport?> createReport(CommentReport r) async {
    final db = await _db;
    // prevent duplicates (unique constraint will also prevent it)
    final existing = await db.query('comment_reports',
        where: 'commentId = ? AND reporterId = ?',
        whereArgs: [r.commentId, r.reporterId]);
    if (existing.isNotEmpty) return CommentReport.fromMap(existing.first);

    final id = await db.insert('comment_reports', r.toMap());
    final created = r.copyWith(idReport: id);

    // after creating, check unique reporters count for this comment
    final countRes = await db.rawQuery(
        'SELECT COUNT(DISTINCT reporterId) as c FROM comment_reports WHERE commentId = ?',
        [r.commentId]);
    final count = Sqflite.firstIntValue(countRes) ?? 0;

    if (count >= 3) {
      // delete the comment if 3 or more unique reports
      try {
        await CommentService.instance.deleteComment(r.commentId);
      } catch (e) {
        // ignore deletion failure
      }
    }

    return created;
  }

  Future<List<CommentReport>> getReportsByCommentId(int commentId) async {
    final db = await _db;
    final res = await db.query('comment_reports',
        where: 'commentId = ?',
        whereArgs: [commentId],
        orderBy: 'createdAt DESC');
    return res.map((m) => CommentReport.fromMap(m)).toList();
  }

  Future<int> getReportCount(int commentId) async {
    final db = await _db;
    final res = await db.rawQuery(
        'SELECT COUNT(DISTINCT reporterId) as c FROM comment_reports WHERE commentId = ?',
        [commentId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<bool> hasUserReported(int commentId, int userId) async {
    final db = await _db;
    final res = await db.query('comment_reports',
        where: 'commentId = ? AND reporterId = ?',
        whereArgs: [commentId, userId]);
    return res.isNotEmpty;
  }
}
