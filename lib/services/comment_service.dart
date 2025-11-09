import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/comment_model.dart';

class CommentService {
  static final CommentService instance = CommentService._init();
  CommentService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<CommentModel?> createComment(CommentModel comment) async {
    final db = await _db;
    final id = await db.insert('comments', comment.toMap());
    return comment.copyWith(idComment: id);
  }

  Future<CommentModel?> getCommentById(int id) async {
    final db = await _db;
    final res = await db.query('comments', where: 'id_comment = ?', whereArgs: [id]);
    if (res.isNotEmpty) return CommentModel.fromMap(res.first);
    return null;
  }

  Future<List<CommentModel>> getCommentsByOfferId(int offerId) async {
    final db = await _db;
    final res = await db.query('comments', where: 'offerId = ?', whereArgs: [offerId], orderBy: 'createdAt DESC');
    return res.map((m) => CommentModel.fromMap(m)).toList();
  }

  Future<int> updateComment(CommentModel comment) async {
    final db = await _db;
    return await db.update('comments', comment.toMap(), where: 'id_comment = ?', whereArgs: [comment.idComment]);
  }

  Future<int> deleteComment(int id) async {
    final db = await _db;
    return await db.delete('comments', where: 'id_comment = ?', whereArgs: [id]);
  }
}
