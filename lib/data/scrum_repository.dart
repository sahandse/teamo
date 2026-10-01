import 'app_database.dart';

class SprintSnapshot {
  final int? id;
  final int sprintId;
  final DateTime date;
  final int totalPoints;
  final int remainingPoints;
  final int donePoints;

  const SprintSnapshot({this.id, required this.sprintId, required this.date, required this.totalPoints, required this.remainingPoints, required this.donePoints});

  factory SprintSnapshot.fromMap(Map<String, Object?> map) => SprintSnapshot(
        id: map['id'] as int?,
        sprintId: map['sprint_id'] as int,
        date: DateTime.parse(map['snapshot_date'] as String),
        totalPoints: map['total_points'] as int,
        remainingPoints: map['remaining_points'] as int,
        donePoints: map['done_points'] as int,
      );
}

class DailyScrumEntry {
  final int? id;
  final int sprintId;
  final DateTime date;
  final String yesterday;
  final String today;
  final String blockers;
  const DailyScrumEntry({this.id, required this.sprintId, required this.date, this.yesterday = '', this.today = '', this.blockers = ''});
}

class RetrospectiveEntry {
  final int? id;
  final int sprintId;
  final String wentWell;
  final String improve;
  final String actions;
  final DateTime createdAt;
  const RetrospectiveEntry({this.id, required this.sprintId, this.wentWell = '', this.improve = '', this.actions = '', required this.createdAt});
}

class ScrumRepository {
  String _dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> syncSprintPoints(int sprintId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('work_items', columns: ['story_points', 'status'], where: 'sprint_id = ?', whereArgs: [sprintId]);
    var total = 0;
    var done = 0;
    for (final row in rows) {
      final points = (row['story_points'] as int?) ?? 0;
      total += points;
      if (row['status'] == 'done') done += points;
    }
    await db.update('sprints', {'planned_points': total, 'completed_points': done}, where: 'id = ?', whereArgs: [sprintId]);
  }

  Future<SprintSnapshot> captureToday(int sprintId) async {
    final db = await AppDatabase.instance.database;
    await syncSprintPoints(sprintId);
    final rows = await db.query('work_items', columns: ['story_points', 'status'], where: 'sprint_id = ?', whereArgs: [sprintId]);
    var total = 0;
    var done = 0;
    for (final row in rows) {
      final points = (row['story_points'] as int?) ?? 0;
      total += points;
      if (row['status'] == 'done') done += points;
    }
    final remaining = total - done;
    final today = _dayKey(DateTime.now());
    await db.insert('sprint_snapshots', {
      'sprint_id': sprintId,
      'snapshot_date': today,
      'total_points': total,
      'remaining_points': remaining,
      'done_points': done,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    final result = await db.query('sprint_snapshots', where: 'sprint_id = ? AND snapshot_date = ?', whereArgs: [sprintId, today], limit: 1);
    return SprintSnapshot.fromMap(result.first);
  }

  Future<List<SprintSnapshot>> snapshots(int sprintId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('sprint_snapshots', where: 'sprint_id = ?', whereArgs: [sprintId], orderBy: 'snapshot_date ASC');
    return rows.map(SprintSnapshot.fromMap).toList();
  }

  Future<void> saveDaily(DailyScrumEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert('daily_scrums', {
      'sprint_id': entry.sprintId,
      'entry_date': _dayKey(entry.date),
      'yesterday': entry.yesterday,
      'today': entry.today,
      'blockers': entry.blockers,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<DailyScrumEntry>> dailyEntries(int sprintId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('daily_scrums', where: 'sprint_id = ?', whereArgs: [sprintId], orderBy: 'entry_date DESC');
    return rows.map((m) => DailyScrumEntry(id: m['id'] as int?, sprintId: m['sprint_id'] as int, date: DateTime.parse(m['entry_date'] as String), yesterday: (m['yesterday'] as String?) ?? '', today: (m['today'] as String?) ?? '', blockers: (m['blockers'] as String?) ?? '')).toList();
  }

  Future<void> saveRetro(RetrospectiveEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert('retrospectives', {
      'sprint_id': entry.sprintId,
      'went_well': entry.wentWell,
      'improve': entry.improve,
      'actions': entry.actions,
      'created_at': entry.createdAt.toIso8601String(),
    });
  }

  Future<List<RetrospectiveEntry>> retros(int sprintId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('retrospectives', where: 'sprint_id = ?', whereArgs: [sprintId], orderBy: 'created_at DESC');
    return rows.map((m) => RetrospectiveEntry(id: m['id'] as int?, sprintId: m['sprint_id'] as int, wentWell: (m['went_well'] as String?) ?? '', improve: (m['improve'] as String?) ?? '', actions: (m['actions'] as String?) ?? '', createdAt: DateTime.parse(m['created_at'] as String))).toList();
  }
}
