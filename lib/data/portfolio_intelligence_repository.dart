import 'app_database.dart';

class ProjectBaseline {
  final int? id;
  final String project;
  final double baselineProgress;
  final DateTime? baselineFinish;
  final double baselineCost;
  final DateTime createdAt;
  const ProjectBaseline({this.id, required this.project, required this.baselineProgress, this.baselineFinish, required this.baselineCost, required this.createdAt});
  factory ProjectBaseline.fromMap(Map<String, Object?> m) => ProjectBaseline(id: m['id'] as int?, project: '${m['project'] ?? ''}', baselineProgress: (m['baseline_progress'] as num?)?.toDouble() ?? 0, baselineFinish: m['baseline_finish'] == null ? null : DateTime.tryParse('${m['baseline_finish']}'), baselineCost: (m['baseline_cost'] as num?)?.toDouble() ?? 0, createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now());
}

class CostSnapshot {
  final int? id;
  final String project;
  final DateTime date;
  final double planned;
  final double actual;
  final double forecast;
  const CostSnapshot({this.id, required this.project, required this.date, required this.planned, required this.actual, required this.forecast});
  factory CostSnapshot.fromMap(Map<String, Object?> m) => CostSnapshot(id: m['id'] as int?, project: '${m['project'] ?? ''}', date: DateTime.parse('${m['snapshot_date']}'), planned: (m['planned_cost'] as num?)?.toDouble() ?? 0, actual: (m['actual_cost'] as num?)?.toDouble() ?? 0, forecast: (m['forecast_cost'] as num?)?.toDouble() ?? 0);
}

class ExecutiveDigest {
  final int? id;
  final String title;
  final String summary;
  final String highlights;
  final String attention;
  final String nextActions;
  final DateTime createdAt;
  const ExecutiveDigest({this.id, required this.title, required this.summary, required this.highlights, required this.attention, required this.nextActions, required this.createdAt});
  factory ExecutiveDigest.fromMap(Map<String, Object?> m) => ExecutiveDigest(id: m['id'] as int?, title: '${m['title'] ?? ''}', summary: '${m['summary'] ?? ''}', highlights: '${m['highlights'] ?? ''}', attention: '${m['attention'] ?? ''}', nextActions: '${m['next_actions'] ?? ''}', createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now());
}

class PortfolioIntelligenceRepository {
  String _day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<ProjectBaseline>> baselines() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('project_baselines', orderBy: 'project COLLATE NOCASE');
    return rows.map(ProjectBaseline.fromMap).toList();
  }

  Future<void> saveBaseline(ProjectBaseline item) async {
    final db = await AppDatabase.instance.database;
    final map = <String, Object?>{'project': item.project, 'baseline_progress': item.baselineProgress, 'baseline_finish': item.baselineFinish?.toIso8601String(), 'baseline_cost': item.baselineCost, 'created_at': item.createdAt.toIso8601String()};
    await db.insert('project_baselines', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> captureCostToday() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('project_budgets');
    final today = _day(DateTime.now());
    for (final row in rows) {
      await db.insert('cost_snapshots', {'project': '${row['project'] ?? ''}', 'snapshot_date': today, 'planned_cost': row['planned_cost'] ?? 0, 'actual_cost': row['actual_cost'] ?? 0, 'forecast_cost': row['forecast_cost'] ?? 0}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<CostSnapshot>> costSnapshots() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('cost_snapshots', orderBy: 'snapshot_date ASC, project ASC');
    return rows.map(CostSnapshot.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> capacityForecast() async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery('''
      SELECT member_name,
             SUM(allocation_percent) AS allocation,
             SUM(weekly_hours) AS weekly_hours,
             COUNT(DISTINCT project) AS projects
      FROM resource_allocations
      GROUP BY member_name
      ORDER BY allocation DESC, member_name ASC
    ''');
  }

  Future<List<Map<String, Object?>>> timeline() async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery('''
      SELECT p.title AS project, p.created_at AS start_date, p.due_date AS due_date,
             p.progress AS progress, p.status AS status,
             b.baseline_finish AS baseline_finish,
             b.baseline_progress AS baseline_progress
      FROM projects p
      LEFT JOIN project_baselines b ON b.project = p.title
      ORDER BY COALESCE(p.due_date, p.created_at) ASC
    ''');
  }

  Future<List<Map<String, Object?>>> criticalPath() async {
    final db = await AppDatabase.instance.database;
    final deps = await db.query('project_dependencies', where: 'status != ?', whereArgs: ['resolved']);
    final projects = await db.query('projects');
    final dueByProject = <String, DateTime?>{};
    for (final p in projects) {
      dueByProject['${p['title'] ?? ''}'] = p['due_date'] == null ? null : DateTime.tryParse('${p['due_date']}');
    }
    final scores = <String, int>{};
    for (final d in deps) {
      final project = '${d['project'] ?? ''}';
      final parent = '${d['depends_on'] ?? ''}';
      scores[project] = (scores[project] ?? 0) + 2;
      scores[parent] = (scores[parent] ?? 0) + 1;
      if ('${d['status']}' == 'blocked') scores[project] = (scores[project] ?? 0) + 3;
    }
    final rows = scores.entries.map((e) => <String, Object?>{'project': e.key, 'criticality': e.value, 'due_date': dueByProject[e.key]?.toIso8601String()}).toList();
    rows.sort((a, b) => (b['criticality'] as int).compareTo(a['criticality'] as int));
    return rows;
  }

  Future<List<ExecutiveDigest>> digests() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('executive_digests', orderBy: 'created_at DESC');
    return rows.map(ExecutiveDigest.fromMap).toList();
  }

  Future<ExecutiveDigest> generateDigest() async {
    final db = await AppDatabase.instance.database;
    final projects = await db.query('projects');
    final risks = await db.query('pmo_register', where: 'status != ?', whereArgs: ['closed']);
    final blocked = await db.query('project_dependencies', where: 'status = ?', whereArgs: ['blocked']);
    final budgets = await db.query('project_budgets');
    final overloaded = await capacityForecast();
    final overdue = projects.where((p) {
      final due = p['due_date'] == null ? null : DateTime.tryParse('${p['due_date']}');
      return due != null && due.isBefore(DateTime.now()) && '${p['status']}' != 'completed';
    }).length;
    final overBudget = budgets.where((b) => ((b['actual_cost'] as num?)?.toDouble() ?? 0) > ((b['planned_cost'] as num?)?.toDouble() ?? 0) && ((b['planned_cost'] as num?)?.toDouble() ?? 0) > 0).length;
    final overAllocated = overloaded.where((m) => ((m['allocation'] as num?)?.toDouble() ?? 0) > 100).length;
    final now = DateTime.now();
    final title = 'Executive Digest ${_day(now)}';
    final digest = ExecutiveDigest(
      title: title,
      summary: '${projects.length} پروژه • ${risks.length} ریسک/مسئله باز • ${blocked.length} وابستگی Blocked',
      highlights: '${projects.where((p) => '${p['status']}' == 'completed').length} پروژه تکمیل‌شده • ${budgets.length} بودجه فعال',
      attention: '$overdue پروژه عقب‌افتاده • $overBudget پروژه Over Budget • $overAllocated عضو Over Allocated',
      nextActions: blocked.isEmpty && risks.isEmpty ? 'ادامه پایش Portfolio و ثبت Baseline هفتگی' : 'رسیدگی به Blockerها، ریسک‌های باز و انحراف‌های بودجه/زمان',
      createdAt: now,
    );
    await db.insert('executive_digests', {'title': digest.title, 'summary': digest.summary, 'highlights': digest.highlights, 'attention': digest.attention, 'next_actions': digest.nextActions, 'created_at': digest.createdAt.toIso8601String()});
    return digest;
  }
}
