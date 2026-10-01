enum ProjectStatus { active, atRisk, delayed, completed }

class ProjectItem {
  final int? id;
  final String title;
  final String owner;
  final ProjectStatus status;
  final double progress;
  final DateTime? dueDate;
  final String description;
  final DateTime createdAt;

  const ProjectItem({
    this.id,
    required this.title,
    this.owner = '',
    this.status = ProjectStatus.active,
    this.progress = 0,
    this.dueDate,
    this.description = '',
    required this.createdAt,
  });

  ProjectItem copyWith({
    int? id,
    String? title,
    String? owner,
    ProjectStatus? status,
    double? progress,
    DateTime? dueDate,
    String? description,
    DateTime? createdAt,
  }) => ProjectItem(
        id: id ?? this.id,
        title: title ?? this.title,
        owner: owner ?? this.owner,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        dueDate: dueDate ?? this.dueDate,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'status': status.name,
        'progress': progress,
        'due_date': dueDate?.toIso8601String(),
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProjectItem.fromMap(Map<String, Object?> map) => ProjectItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        owner: (map['owner'] as String?) ?? '',
        status: ProjectStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ProjectStatus.active,
        ),
        progress: ((map['progress'] as num?) ?? 0).toDouble(),
        dueDate: map['due_date'] == null ? null : DateTime.tryParse(map['due_date'] as String),
        description: (map['description'] as String?) ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
