import 'app_database.dart';

class ResourceAllocation {
  final int? id;
  final String memberName;
  final String project;
  final String role;
  final double allocationPercent;
  final double weeklyHours;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  const ResourceAllocation({this.id, required this.memberName, this.project = '', this.role = '', this.allocationPercent = 0, this.weeklyHours = 0, this.startDate, this.endDate, required this.createdAt});

  factory ResourceAllocation.fromMap(Map<String, Object?> m) => ResourceAllocation(
        id: m['id'] as int?,
        memberName: m['member_name'] as String,
        project: (m['project'] as String?) ?? '',
        role: (m['role'] as String?) ?? '',
        allocationPercent: (m['allocation_percent'] as num?)?.toDouble() ?? 0,
        weeklyHours: (m['weekly_hours'] as num?)?.toDouble() ?? 0,
        startDate: m['start_date'] == null ? null : DateTime.tryParse(m['start_date'] as String),
        endDate: m['end_date'] == null ? null : DateTime.tryParse(m['end_date'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'member_name': memberName,
        'project': project,
        'role': role,
        'allocation_percent': allocationPercent,
        'weekly_hours': weeklyHours,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class ProjectDependency {
  final int? id;
  final String project;
  final String dependsOn;
  final String dependencyType;
  final String status;
  final String note;
  final DateTime createdAt;

  const ProjectDependency({this.id, required this.project, required this.dependsOn, this.dependencyType = 'finish_to_start', this.status = 'active', this.note = '', required this.createdAt});

  factory ProjectDependency.fromMap(Map<String, Object?> m) => ProjectDependency(
        id: m['id'] as int?,
        project: m['project'] as String,
        dependsOn: m['depends_on'] as String,
        dependencyType: (m['dependency_type'] as String?) ?? 'finish_to_start',
        status: (m['status'] as String?) ?? 'active',
        note: (m['note'] as String?) ?? '',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'project': project,
        'depends_on': dependsOn,
        'dependency_type': dependencyType,
        'status': status,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}

class ProjectBudget {
  final int? id;
  final String project;
  final double plannedCost;
  final double actualCost;
  final double forecastCost;
  final String currency;
  final DateTime updatedAt;

  const ProjectBudget({this.id, required this.project, this.plannedCost = 0, this.actualCost = 0, this.forecastCost = 0, this.currency = 'IRR', required this.updatedAt});

  double get variance => plannedCost - actualCost;
  double get burnRate => plannedCost <= 0 ? 0 : (actualCost / plannedCost).clamp(0, 99).toDouble();

  factory ProjectBudget.fromMap(Map<String, Object?> m) => ProjectBudget(
        id: m['id'] as int?,
        project: m['project'] as String,
        plannedCost: (m['planned_cost'] as num?)?.toDouble() ?? 0,
        actualCost: (m['actual_cost'] as num?)?.toDouble() ?? 0,
        forecastCost: (m['forecast_cost'] as num?)?.toDouble() ?? 0,
        currency: (m['currency'] as String?) ?? 'IRR',
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'project': project,
        'planned_cost': plannedCost,
        'actual_cost': actualCost,
        'forecast_cost': forecastCost,
        'currency': currency,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class ExecutivePmoRepository {
  Future<List<ResourceAllocation>> allocations() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('resource_allocations', orderBy: 'member_name ASC');
    return rows.map(ResourceAllocation.fromMap).toList();
  }

  Future<void> saveAllocation(ResourceAllocation item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap();
    if (item.id == null) {
      await db.insert('resource_allocations', data);
    } else {
      await db.update('resource_allocations', data, where: 'id = ?', whereArgs: [item.id]);
    }
  }

  Future<void> deleteAllocation(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('resource_allocations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProjectDependency>> dependencies() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('project_dependencies', orderBy: 'project ASC');
    return rows.map(ProjectDependency.fromMap).toList();
  }

  Future<void> saveDependency(ProjectDependency item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap();
    if (item.id == null) {
      await db.insert('project_dependencies', data);
    } else {
      await db.update('project_dependencies', data, where: 'id = ?', whereArgs: [item.id]);
    }
  }

  Future<void> deleteDependency(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('project_dependencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProjectBudget>> budgets() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('project_budgets', orderBy: 'project ASC');
    return rows.map(ProjectBudget.fromMap).toList();
  }

  Future<void> saveBudget(ProjectBudget item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap();
    final existing = await db.query('project_budgets', columns: ['id'], where: 'project = ?', whereArgs: [item.project], limit: 1);
    if (item.id != null) {
      await db.update('project_budgets', data, where: 'id = ?', whereArgs: [item.id]);
    } else if (existing.isNotEmpty) {
      await db.update('project_budgets', data, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      await db.insert('project_budgets', data);
    }
  }

  Future<void> deleteBudget(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('project_budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> executiveProjects() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('projects', orderBy: 'created_at DESC');
    final riskRows = await db.query('pmo_register', where: 'status != ?', whereArgs: ['closed']);
    final budgetRows = await db.query('project_budgets');
    final dependencyRows = await db.query('project_dependencies', where: 'status = ?', whereArgs: ['active']);
    final result = <Map<String, Object?>>[];
    for (final project in rows) {
      final name = '${project['title'] ?? ''}';
      final projectRisks = riskRows.where((r) => '${r['project']}' == name).toList();
      final budget = budgetRows.where((b) => '${b['project']}' == name).firstOrNull;
      final deps = dependencyRows.where((d) => '${d['project']}' == name).length;
      final progress = ((project['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble();
      final status = '${project['status'] ?? 'active'}';
      final riskScore = projectRisks.fold<double>(0, (sum, r) => sum + ((r['probability'] as num?)?.toDouble() ?? 0) * ((r['impact'] as num?)?.toDouble() ?? 0));
      final planned = (budget?['planned_cost'] as num?)?.toDouble() ?? 0;
      final actual = (budget?['actual_cost'] as num?)?.toDouble() ?? 0;
      final costRatio = planned <= 0 ? 0 : actual / planned;
      final rag = status == 'delayed' || status == 'atRisk' || riskScore >= 15 || costRatio > 1.1
          ? 'red'
          : progress < .35 || riskScore >= 8 || costRatio > .9 || deps >= 3
              ? 'amber'
              : 'green';
      result.add({...project, 'rag': rag, 'open_risk_score': riskScore, 'dependency_count': deps, 'planned_cost': planned, 'actual_cost': actual});
    }
    return result;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
