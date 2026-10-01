import '../models/project_item.dart';
import 'app_database.dart';

class ProjectRepository {
  Future<List<ProjectItem>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('projects', orderBy: 'created_at DESC');
    return rows.map(ProjectItem.fromMap).toList();
  }

  Future<ProjectItem> create(ProjectItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    final id = await db.insert('projects', data);
    return item.copyWith(id: id);
  }

  Future<void> update(ProjectItem item) async {
    if (item.id == null) return;
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    await db.update('projects', data, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}
