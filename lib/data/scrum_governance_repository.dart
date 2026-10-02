import 'app_database.dart';

class ScrumGovernanceRepository {
  Future<List<Map<String, Object?>>> reviews() async {
    final db = await AppDatabase.instance.database;
    return db.query('sprint_reviews', orderBy: 'created_at DESC');
  }

  Future<void> addReview({required int sprintId, required String summary, required String accepted, required String rejected, required String feedback}) async {
    final db = await AppDatabase.instance.database;
    await db.insert('sprint_reviews', {
      'sprint_id': sprintId,
      'summary': summary,
      'accepted': accepted,
      'rejected': rejected,
      'feedback': feedback,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> dod() async {
    final db = await AppDatabase.instance.database;
    return db.query('definition_of_done', orderBy: 'id ASC');
  }

  Future<void> addDod(String title) async {
    final db = await AppDatabase.instance.database;
    await db.insert('definition_of_done', {'title': title, 'is_done': 0, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<void> toggleDod(int id, bool done) async {
    final db = await AppDatabase.instance.database;
    await db.update('definition_of_done', {'is_done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> capacity() async {
    final db = await AppDatabase.instance.database;
    return db.query('team_capacity', orderBy: 'member_name ASC');
  }

  Future<void> addCapacity({required int sprintId, required String member, required double hours, required double focusFactor}) async {
    final db = await AppDatabase.instance.database;
    await db.insert('team_capacity', {
      'sprint_id': sprintId,
      'member_name': member,
      'available_hours': hours,
      'focus_factor': focusFactor,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> impediments() async {
    final db = await AppDatabase.instance.database;
    return db.query('impediments', orderBy: "CASE status WHEN 'open' THEN 0 ELSE 1 END, created_at DESC");
  }

  Future<void> addImpediment({required int sprintId, required String title, required String owner, required String severity, String note = ''}) async {
    final db = await AppDatabase.instance.database;
    await db.insert('impediments', {
      'sprint_id': sprintId,
      'title': title,
      'owner': owner,
      'severity': severity,
      'status': 'open',
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> closeImpediment(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update('impediments', {'status': 'closed'}, where: 'id = ?', whereArgs: [id]);
  }
}
