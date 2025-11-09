import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/offer_model.dart';

class OfferService {
  static final OfferService instance = OfferService._init();
  OfferService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<Offer?> createOffer(Offer offer) async {
    final db = await _db;
    final id = await db.insert('offers', offer.toMap());
    return offer.copyWith(idOffer: id);
  }

  Future<Offer?> getOfferById(int idOffer) async {
    final db = await _db;
    final res =
        await db.query('offers', where: 'id_offer = ?', whereArgs: [idOffer]);
    if (res.isNotEmpty) return Offer.fromMap(res.first);
    return null;
  }

  Future<List<Offer>> getAllOffers() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final res = await db.query('offers',
        where: 'expiresAt IS NULL OR expiresAt > ?',
        whereArgs: [now],
        orderBy: 'createdAt DESC');
    return res.map((m) => Offer.fromMap(m)).toList();
  }

  Future<List<Offer>> getOffersByUserId(int userId) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final res = await db.query('offers',
        where: 'userId = ? AND (expiresAt IS NULL OR expiresAt > ?)',
        whereArgs: [userId, now],
        orderBy: 'createdAt DESC');
    return res.map((m) => Offer.fromMap(m)).toList();
  }

  Future<int> updateOffer(Offer offer) async {
    final db = await _db;
    return await db.update('offers', offer.toMap(),
        where: 'id_offer = ?', whereArgs: [offer.idOffer]);
  }

  Future<int> deleteOffer(int idOffer) async {
    final db = await _db;
    return await db
        .delete('offers', where: 'id_offer = ?', whereArgs: [idOffer]);
  }
}
