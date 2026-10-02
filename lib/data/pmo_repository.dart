import 'app_database.dart';

enum RegisterType { risk, issue }
enum RegisterStatus { open, monitoring, mitigated, closed }
enum ObjectiveStatus { active, atRisk, done }

class RegisterItem {
  final int? id;
  final RegisterType type;
  final String title;
  final String project;
  final String owner;
  final String severity;
  final double probability;
  final double impact;
  final RegisterStatus status;
  final String responsePlan;
  final DateTime createdAt;

  const RegisterItem({this.id, required this.type, required this.title, this.project = '', this.owner = '', this.severity = 'medium', this.probability = 0, this.impact = 0, this.status = RegisterStatus.open, this.responsePlan = '', required this.createdAt});

  double get score => probability * impact;

  Map<String, Object?> toMap() => {'id': id, 'type': type.name, 'title': title, 'project': project, 'owner': owner, 'severity': severity, 'probability': probability, 'impact': impact, 'status': status.name, 'response_plan': responsePlan, 'created_at': createdAt.toIso8601String()};

  factory RegisterItem.fromMap(Map<String, Object?> m) => RegisterItem(
        id: m['id'] as int?,
        type: RegisterType.values.firstWhere((e) => e.name == m['type'], orElse: () => RegisterType.risk),
        title: m['title'] as String,
        project: (m['project'] as String?) ?? '',
        owner: (m['owner'] as String?) ?? '',
        severity: (m['severity'] as String?) ?? 'medium',
        probability: (m['probability'] as num?)?.toDouble() ?? 0,
        impact: (m['impact'] as num?)?.toDouble() ?? 0,
        status: RegisterStatus.values.firstWhere((e) => e.name == m['status'], orElse: () => RegisterStatus.open),
        responsePlan: (m['response_plan'] as String?) ?? '',
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}

class OkrItem {
  final int? id;
  final String objective;
  final String keyResult;
  final String project;
  final String owner;
  final double target;
  final double current;
  final String unit;
  final ObjectiveStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;

  const OkrItem({this.id, required this.objective, required this.keyResult, this.project = '', this.owner = '', this.target = 100, this.current = 0, this.unit = '%', this.status = ObjectiveStatus.active, this.dueDate, required this.createdAt});

  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);

  Map<String, Object?> toMap() => {'id': id, 'objective': objective, 'key_result': keyResult, 'project': project, 'owner': owner, 'target': target, 'current': current, 'unit': unit, 'status': status.name, 'due_date': dueDate?.toIso8601String(), 'created_at': createdAt.toIso8601String()};

  factory OkrItem.fromMap(Map<String, Object?> m) => OkrItem(
        id: m['id'] as int?,
        objective: m['objective'] as String,
        keyResult: m['key_result'] as String,
        project: (m['project'] as String?) ?? '',
        owner: (m['owner'] as String?) ?? '',
        target: (m['target'] as num?)?.toDouble() ?? 100,
        current: (m['current'] as num?)?.toDouble() ?? 0,
        unit: (m['unit'] as String?) ?? '%',
        status: ObjectiveStatus.values.firstWhere((e) => e.name == m['status'], orElse: () => ObjectiveStatus.active),
        dueDate: DateTime.tryParse((m['due_date'] as String?) ?? ''),
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}

class PmoRepository {
  Future<List<RegisterItem>> registers() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('pmo_register', orderBy: 'created_at DESC');
    return rows.map(RegisterItem.fromMap).toList();
  }

  Future<void> saveRegister(RegisterItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    if (item.id == null) {
      await db.insert('pmo_register', data);
    } else {
      await db.update('pmo_register', data, where: 'id = ?', whereArgs: [item.id]);
    }
  }

  Future<void> deleteRegister(int id) async => (await AppDatabase.instance.database).delete('pmo_register', where: 'id = ?', whereArgs: [id]);

  Future<List<OkrItem>> okrs() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('okr_items', orderBy: 'created_at DESC');
    return rows.map(OkrItem.fromMap).toList();
  }

  Future<void> saveOkr(OkrItem item) async {
    final db = await AppDatabase.instance.database;
    final data = item.toMap()..remove('id');
    if (item.id == null) {
      await db.insert('okr_items', data);
    } else {
      await db.update('okr_items', data, where: 'id = ?', whereArgs: [item.id]);
    }
  }

  Future<void> deleteOkr(int id) async => (await AppDatabase.instance.database).delete('okr_items', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> projectHealth() async {
    final db = await AppDatabase.instance.database;
    return db.query('projects', orderBy: 'created_at DESC');
  }

  Future<String> csvReport() async {
    final riskRows = await registers();
    final okrRows = await okrs();
    final b = StringBuffer('type,title,project,owner,status,score\n');
    for (final r in riskRows) {
      b.writeln('${r.type.name},"${r.title.replaceAll('"', '""')}","${r.project.replaceAll('"', '""')}","${r.owner.replaceAll('"', '""')}",${r.status.name},${r.score.toStringAsFixed(1)}');
    }
    b.writeln();
    b.writeln('objective,key_result,project,owner,current,target,unit,status');
    for (final o in okrRows) {
      b.writeln('"${o.objective.replaceAll('"', '""')}","${o.keyResult.replaceAll('"', '""')}","${o.project.replaceAll('"', '""')}","${o.owner.replaceAll('"', '""')}",${o.current},${o.target},${o.unit},${o.status.name}');
    }
    return b.toString();
  }
}
