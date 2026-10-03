import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class ScenarioPlan {
  final int? id;
  final String title;
  final String project;
  final double budgetDelta;
  final int scheduleDeltaDays;
  final double capacityDelta;
  final double riskDelta;
  final String note;
  final DateTime createdAt;
  const ScenarioPlan({this.id, required this.title, required this.project, required this.budgetDelta, required this.scheduleDeltaDays, required this.capacityDelta, required this.riskDelta, required this.note, required this.createdAt});
  factory ScenarioPlan.fromMap(Map<String, Object?> m) => ScenarioPlan(id: m['id'] as int?, title: '${m['title'] ?? ''}', project: '${m['project'] ?? ''}', budgetDelta: (m['budget_delta'] as num?)?.toDouble() ?? 0, scheduleDeltaDays: (m['schedule_delta_days'] as num?)?.toInt() ?? 0, capacityDelta: (m['capacity_delta'] as num?)?.toDouble() ?? 0, riskDelta: (m['risk_delta'] as num?)?.toDouble() ?? 0, note: '${m['note'] ?? ''}', createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now());
}

class EvmEntry {
  final int? id;
  final String project;
  final double pv;
  final double ev;
  final double ac;
  final double bac;
  final DateTime statusDate;
  const EvmEntry({this.id, required this.project, required this.pv, required this.ev, required this.ac, required this.bac, required this.statusDate});
  double get cpi => ac == 0 ? 0 : ev / ac;
  double get spi => pv == 0 ? 0 : ev / pv;
  double get cv => ev - ac;
  double get sv => ev - pv;
  double get eac => cpi <= 0 ? bac : bac / cpi;
  factory EvmEntry.fromMap(Map<String, Object?> m) => EvmEntry(id: m['id'] as int?, project: '${m['project'] ?? ''}', pv: (m['pv'] as num?)?.toDouble() ?? 0, ev: (m['ev'] as num?)?.toDouble() ?? 0, ac: (m['ac'] as num?)?.toDouble() ?? 0, bac: (m['bac'] as num?)?.toDouble() ?? 0, statusDate: DateTime.tryParse('${m['status_date']}') ?? DateTime.now());
}

class PortfolioPriority {
  final int? id;
  final String project;
  final double strategy;
  final double valueScore;
  final double riskScore;
  final double effortScore;
  final bool mandatory;
  final String note;
  const PortfolioPriority({this.id, required this.project, required this.strategy, required this.valueScore, required this.riskScore, required this.effortScore, required this.mandatory, required this.note});
  double get score {
    final risk = riskScore.clamp(0, 10).toDouble();
    final effort = effortScore.clamp(0, 10).toDouble();
    return (strategy * 0.35) + (valueScore * 0.35) + ((10.0 - risk) * 0.15) + ((10.0 - effort) * 0.15) + (mandatory ? 2.0 : 0.0);
  }
  factory PortfolioPriority.fromMap(Map<String, Object?> m) => PortfolioPriority(id: m['id'] as int?, project: '${m['project'] ?? ''}', strategy: (m['strategy'] as num?)?.toDouble() ?? 0, valueScore: (m['value_score'] as num?)?.toDouble() ?? 0, riskScore: (m['risk_score'] as num?)?.toDouble() ?? 0, effortScore: (m['effort_score'] as num?)?.toDouble() ?? 0, mandatory: (m['mandatory'] as num?)?.toInt() == 1, note: '${m['note'] ?? ''}');
}

class BenefitItem {
  final int? id;
  final String project;
  final String title;
  final String owner;
  final double target;
  final double current;
  final String unit;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;
  const BenefitItem({this.id, required this.project, required this.title, required this.owner, required this.target, required this.current, required this.unit, this.dueDate, required this.status, required this.createdAt});
  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1).toDouble();
  factory BenefitItem.fromMap(Map<String, Object?> m) => BenefitItem(id: m['id'] as int?, project: '${m['project'] ?? ''}', title: '${m['title'] ?? ''}', owner: '${m['owner'] ?? ''}', target: (m['target'] as num?)?.toDouble() ?? 0, current: (m['current'] as num?)?.toDouble() ?? 0, unit: '${m['unit'] ?? '%'}', dueDate: m['due_date'] == null ? null : DateTime.tryParse('${m['due_date']}'), status: '${m['status'] ?? 'active'}', createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now());
}

class ExecutiveReport {
  final int? id;
  final String title;
  final String body;
  final DateTime createdAt;
  const ExecutiveReport({this.id, required this.title, required this.body, required this.createdAt});
  factory ExecutiveReport.fromMap(Map<String, Object?> m) => ExecutiveReport(id: m['id'] as int?, title: '${m['title'] ?? ''}', body: '${m['body'] ?? ''}', createdAt: DateTime.tryParse('${m['created_at']}') ?? DateTime.now());
}

class StrategicPmoRepository {
  Future<List<ScenarioPlan>> scenarios() async {
    final db = await AppDatabase.instance.database;
    return (await db.query('scenario_plans', orderBy: 'created_at DESC')).map(ScenarioPlan.fromMap).toList();
  }

  Future<void> saveScenario(ScenarioPlan item) async {
    final db = await AppDatabase.instance.database;
    final map = <String, Object?>{'title': item.title, 'project': item.project, 'budget_delta': item.budgetDelta, 'schedule_delta_days': item.scheduleDeltaDays, 'capacity_delta': item.capacityDelta, 'risk_delta': item.riskDelta, 'note': item.note, 'created_at': item.createdAt.toIso8601String()};
    if (item.id == null) { await db.insert('scenario_plans', map); } else { await db.update('scenario_plans', map, where: 'id = ?', whereArgs: [item.id]); }
  }

  Future<void> deleteScenario(int id) async => (await AppDatabase.instance.database).delete('scenario_plans', where: 'id = ?', whereArgs: [id]);

  Future<List<EvmEntry>> evmEntries() async {
    final db = await AppDatabase.instance.database;
    return (await db.query('evm_entries', orderBy: 'status_date DESC, project ASC')).map(EvmEntry.fromMap).toList();
  }

  Future<void> saveEvm(EvmEntry item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('evm_entries', {'project': item.project, 'pv': item.pv, 'ev': item.ev, 'ac': item.ac, 'bac': item.bac, 'status_date': item.statusDate.toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEvm(int id) async => (await AppDatabase.instance.database).delete('evm_entries', where: 'id = ?', whereArgs: [id]);

  Future<List<PortfolioPriority>> priorities() async {
    final db = await AppDatabase.instance.database;
    final items = (await db.query('portfolio_priorities')).map(PortfolioPriority.fromMap).toList();
    items.sort((a, b) => b.score.compareTo(a.score));
    return items;
  }

  Future<void> savePriority(PortfolioPriority item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('portfolio_priorities', {'project': item.project, 'strategy': item.strategy, 'value_score': item.valueScore, 'risk_score': item.riskScore, 'effort_score': item.effortScore, 'mandatory': item.mandatory ? 1 : 0, 'note': item.note}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePriority(int id) async => (await AppDatabase.instance.database).delete('portfolio_priorities', where: 'id = ?', whereArgs: [id]);

  Future<List<BenefitItem>> benefits() async {
    final db = await AppDatabase.instance.database;
    return (await db.query('benefits', orderBy: 'status ASC, due_date ASC')).map(BenefitItem.fromMap).toList();
  }

  Future<void> saveBenefit(BenefitItem item) async {
    final db = await AppDatabase.instance.database;
    final map = <String, Object?>{'project': item.project, 'title': item.title, 'owner': item.owner, 'target': item.target, 'current': item.current, 'unit': item.unit, 'due_date': item.dueDate?.toIso8601String(), 'status': item.status, 'created_at': item.createdAt.toIso8601String()};
    if (item.id == null) { await db.insert('benefits', map); } else { await db.update('benefits', map, where: 'id = ?', whereArgs: [item.id]); }
  }

  Future<void> deleteBenefit(int id) async => (await AppDatabase.instance.database).delete('benefits', where: 'id = ?', whereArgs: [id]);

  Future<List<ExecutiveReport>> reports() async {
    final db = await AppDatabase.instance.database;
    return (await db.query('executive_reports', orderBy: 'created_at DESC')).map(ExecutiveReport.fromMap).toList();
  }

  Future<ExecutiveReport> generateExecutiveReport() async {
    final db = await AppDatabase.instance.database;
    final projects = await db.query('projects');
    final risks = await db.query('pmo_register', where: 'status != ?', whereArgs: ['closed']);
    final deps = await db.query('project_dependencies', where: 'status = ?', whereArgs: ['blocked']);
    final budgets = await db.query('project_budgets');
    final priorities = await this.priorities();
    final benefits = await this.benefits();
    final evm = await evmEntries();
    final latestByProject = <String, EvmEntry>{};
    for (final item in evm) { latestByProject.putIfAbsent(item.project, () => item); }
    final avgCpi = latestByProject.isEmpty ? 0.0 : latestByProject.values.fold<double>(0, (s, e) => s + e.cpi) / latestByProject.length;
    final avgSpi = latestByProject.isEmpty ? 0.0 : latestByProject.values.fold<double>(0, (s, e) => s + e.spi) / latestByProject.length;
    final realized = benefits.where((e) => e.status == 'realized' || e.progress >= 1).length;
    final totalPlanned = budgets.fold<double>(0, (s, e) => s + ((e['planned_cost'] as num?)?.toDouble() ?? 0));
    final totalActual = budgets.fold<double>(0, (s, e) => s + ((e['actual_cost'] as num?)?.toDouble() ?? 0));
    final now = DateTime.now();
    final top = priorities.take(3).map((e) => '${e.project} (${e.score.toStringAsFixed(1)})').join('، ');
    final body = '''گزارش مدیریتی Portfolio\n\nوضعیت کلی\n- پروژه‌ها: ${projects.length}\n- ریسک/Issue باز: ${risks.length}\n- Dependency مسدود: ${deps.length}\n- بودجه برنامه‌ریزی‌شده: ${totalPlanned.toStringAsFixed(0)}\n- هزینه واقعی: ${totalActual.toStringAsFixed(0)}\n\nEarned Value\n- میانگین CPI: ${avgCpi.toStringAsFixed(2)}\n- میانگین SPI: ${avgSpi.toStringAsFixed(2)}\n\nPortfolio Prioritization\n- اولویت‌های برتر: ${top.isEmpty ? 'ثبت نشده' : top}\n\nBenefits\n- Benefitهای تحقق‌یافته: $realized از ${benefits.length}\n\nاقدام مدیریتی\n${risks.isNotEmpty || deps.isNotEmpty ? '- تمرکز روی ریسک‌ها و گلوگاه‌های باز\n' : '- Portfolio بدون Blocker بحرانی ثبت‌شده\n'}${avgCpi > 0 && avgCpi < 1 ? '- کنترل هزینه و بهبود CPI\n' : ''}${avgSpi > 0 && avgSpi < 1 ? '- بازبینی برنامه زمان‌بندی و بهبود SPI\n' : ''}''';
    final report = ExecutiveReport(title: 'Executive Portfolio Report ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}', body: body, createdAt: now);
    await db.insert('executive_reports', {'title': report.title, 'body': report.body, 'created_at': report.createdAt.toIso8601String()});
    return report;
  }
}
