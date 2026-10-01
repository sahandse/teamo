enum TaskStatus { backlog, todo, doing, review, done }

enum TaskPriority { low, medium, high, urgent }

class TaskItem {
  final int? id;
  final String title;
  final String project;
  final TaskStatus status;
  final TaskPriority priority;
  final String assignee;
  final DateTime? dueDate;
  final String description;
  final DateTime createdAt;

  const TaskItem({
    this.id,
    required this.title,
    this.project = 'بدون پروژه',
    this.status = TaskStatus.backlog,
    this.priority = TaskPriority.medium,
    this.assignee = '',
    this.dueDate,
    this.description = '',
    required this.createdAt,
  });

  TaskItem copyWith({
    int? id,
    String? title,
    String? project,
    TaskStatus? status,
    TaskPriority? priority,
    String? assignee,
    DateTime? dueDate,
    String? description,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      project: project ?? this.project,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'project': project,
        'status': status.name,
        'priority': priority.name,
        'assignee': assignee,
        'due_date': dueDate?.toIso8601String(),
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory TaskItem.fromMap(Map<String, Object?> map) {
    return TaskItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      project: (map['project'] as String?) ?? 'بدون پروژه',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.backlog,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      assignee: (map['assignee'] as String?) ?? '',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.tryParse(map['due_date'] as String),
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
