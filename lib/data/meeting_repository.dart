import '../models/meeting_item.dart';
import 'app_database.dart';

class MeetingRepository {
  Future<List<MeetingItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('meetings', orderBy: 'starts_at ASC');
    return rows.map(MeetingItem.fromMap).toList();
  }

  Future<MeetingItem> create(MeetingItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    final id = await db.insert('meetings', data);
    return item.copyWith(id: id);
  }

  Future<void> update(MeetingItem item) async {
    if (item.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    await db.update('meetings', data, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }
}
