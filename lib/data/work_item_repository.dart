import '../models/work_item.dart';
import 'app_database.dart';

class WorkItemRepository {
  Future<List<WorkItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('work_items', orderBy: 'created_at DESC');
    return rows.map(WorkItem.fromMap).toList();
  }

  Future<WorkItem> create(WorkItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    final id = await db.insert('work_items', data);
    return item.copyWith(id: id);
  }

  Future<void> update(WorkItem item) async {
    if (item.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    await db.update('work_items', data, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('work_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WorkItem>> bySprint(int sprintId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('work_items', where: 'sprint_id = ?', whereArgs: [sprintId], orderBy: 'created_at DESC');
    return rows.map(WorkItem.fromMap).toList();
  }
}
