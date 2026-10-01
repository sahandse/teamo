enum WorkItemType { epic, story, task, bug }
enum WorkItemStatus { backlog, ready, doing, review, done }

class WorkItem {
  final int? id;
  final String title;
  final String project;
  final int? sprintId;
  final WorkItemType type;
  final WorkItemStatus status;
  final int storyPoints;
  final String assignee;
  final String description;
  final DateTime createdAt;

  const WorkItem({
    this.id,
    required this.title,
    this.project = '',
    this.sprintId,
    this.type = WorkItemType.story,
    this.status = WorkItemStatus.backlog,
    this.storyPoints = 0,
    this.assignee = '',
    this.description = '',
    required this.createdAt,
  });

  WorkItem copyWith({
    int? id,
    String? title,
    String? project,
    int? sprintId,
    WorkItemType? type,
    WorkItemStatus? status,
    int? storyPoints,
    String? assignee,
    String? description,
    DateTime? createdAt,
  }) => WorkItem(
        id: id ?? this.id,
        title: title ?? this.title,
        project: project ?? this.project,
        sprintId: sprintId ?? this.sprintId,
        type: type ?? this.type,
        status: status ?? this.status,
        storyPoints: storyPoints ?? this.storyPoints,
        assignee: assignee ?? this.assignee,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'project': project,
        'sprint_id': sprintId,
        'type': type.name,
        'status': status.name,
        'story_points': storyPoints,
        'assignee': assignee,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory WorkItem.fromMap(Map<String, Object?> map) => WorkItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        project: (map['project'] as String?) ?? '',
        sprintId: map['sprint_id'] as int?,
        type: WorkItemType.values.firstWhere((e) => e.name == map['type'], orElse: () => WorkItemType.story),
        status: WorkItemStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => WorkItemStatus.backlog),
        storyPoints: (map['story_points'] as int?) ?? 0,
        assignee: (map['assignee'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}
