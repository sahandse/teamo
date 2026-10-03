import '../models/task_item.dart';
import 'app_database.dart';

class TaskRepository {
  Future<List<TaskItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tasks', orderBy: 'created_at DESC');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<TaskItem> create(TaskItem task) async {
    final db = await AppDatabase.instance.database;
    final data = task.toMap()..remove('id');
    final id = await db.insert('tasks', data);
    return task.copyWith(id: id);
  }

  Future<void> update(TaskItem task) async {
    if (task.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = task.toMap()..remove('id');
    await db.update('tasks', data, where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
