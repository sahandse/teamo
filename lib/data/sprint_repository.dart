import '../models/sprint_item.dart';
import 'app_database.dart';

class SprintRepository {
  Future<List<SprintItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('sprints', orderBy: 'start_date DESC');
    return rows.map(SprintItem.fromMap).toList();
  }

  Future<SprintItem> create(SprintItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    final id = await db.insert('sprints', data);
    return item.copyWith(id: id);
  }

  Future<void> update(SprintItem item) async {
    if (item.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    await db.update('sprints', data, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('sprints', where: 'id = ?', whereArgs: [id]);
  }
}
