enum SprintStatus { planned, active, completed }

class SprintItem {
  final int? id;
  final String title;
  final String project;
  final String goal;
  final SprintStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int plannedPoints;
  final int completedPoints;
  final DateTime createdAt;

  const SprintItem({
    this.id,
    required this.title,
    this.project = '',
    this.goal = '',
    this.status = SprintStatus.planned,
    required this.startDate,
    required this.endDate,
    this.plannedPoints = 0,
    this.completedPoints = 0,
    required this.createdAt,
  });

  double get progress => plannedPoints <= 0 ? 0 : (completedPoints / plannedPoints).clamp(0, 1);

  SprintItem copyWith({
    int? id,
    String? title,
    String? project,
    String? goal,
    SprintStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? plannedPoints,
    int? completedPoints,
    DateTime? createdAt,
  }) => SprintItem(
        id: id ?? this.id,
        title: title ?? this.title,
        project: project ?? this.project,
        goal: goal ?? this.goal,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        plannedPoints: plannedPoints ?? this.plannedPoints,
        completedPoints: completedPoints ?? this.completedPoints,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'project': project,
        'goal': goal,
        'status': status.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'planned_points': plannedPoints,
        'completed_points': completedPoints,
        'created_at': createdAt.toIso8601String(),
      };

  factory SprintItem.fromMap(Map<String, Object?> map) => SprintItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        project: (map['project'] as String?) ?? '',
        goal: (map['goal'] as String?) ?? '',
        status: SprintStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SprintStatus.planned,
        ),
        startDate: DateTime.tryParse((map['start_date'] as String?) ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse((map['end_date'] as String?) ?? '') ?? DateTime.now(),
        plannedPoints: (map['planned_points'] as int?) ?? 0,
        completedPoints: (map['completed_points'] as int?) ?? 0,
        createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}
