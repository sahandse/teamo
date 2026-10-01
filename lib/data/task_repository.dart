import 'package:sqflite/sqflite.dart';

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

  Future<void> seedIfEmpty() async {
    final db = await AppDatabase.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM tasks'),
        ) ??
        0;
    if (count > 0) return;

    final now = DateTime.now();
    final demo = [
      TaskItem(title: 'طراحی صفحه ورود', project: 'تیمو', status: TaskStatus.backlog, priority: TaskPriority.medium, createdAt: now),
      TaskItem(title: 'داشبورد اصلی', project: 'تیمو', status: TaskStatus.doing, priority: TaskPriority.high, createdAt: now),
      TaskItem(title: 'Drag & Drop کانبان', project: 'تیمو', status: TaskStatus.doing, priority: TaskPriority.high, createdAt: now),
      TaskItem(title: 'بازبینی UI/UX', project: 'تیمو', status: TaskStatus.review, priority: TaskPriority.medium, createdAt: now),
      TaskItem(title: 'ساخت ساختار پروژه', project: 'تیمو', status: TaskStatus.done, priority: TaskPriority.low, createdAt: now),
    ];
    for (final task in demo) {
      await create(task);
    }
  }
}
