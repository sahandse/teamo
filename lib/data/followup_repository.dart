import '../models/followup_item.dart';
import 'app_database.dart';

class FollowupRepository {
  Future<List<FollowupItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('followups', orderBy: 'created_at DESC');
    return rows.map(FollowupItem.fromMap).toList();
  }

  Future<FollowupItem> create(FollowupItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    final id = await db.insert('followups', data);
    return item.copyWith(id: id);
  }

  Future<void> update(FollowupItem item) async {
    if (item.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    await db.update('followups', data, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }
}
