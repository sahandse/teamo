enum FollowupStatus { open, waiting, snoozed, done }

class FollowupItem {
  final int? id;
  final String title;
  final String context;
  final String assignee;
  final FollowupStatus status;
  final DateTime? dueDate;
  final DateTime? snoozedUntil;
  final String note;
  final DateTime createdAt;

  const FollowupItem({
    this.id,
    required this.title,
    this.context = '',
    this.assignee = '',
    this.status = FollowupStatus.open,
    this.dueDate,
    this.snoozedUntil,
    this.note = '',
    required this.createdAt,
  });

  FollowupItem copyWith({
    int? id,
    String? title,
    String? context,
    String? assignee,
    FollowupStatus? status,
    DateTime? dueDate,
    DateTime? snoozedUntil,
    String? note,
    DateTime? createdAt,
  }) => FollowupItem(
        id: id ?? this.id,
        title: title ?? this.title,
        context: context ?? this.context,
        assignee: assignee ?? this.assignee,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        snoozedUntil: snoozedUntil ?? this.snoozedUntil,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'context': context,
        'assignee': assignee,
        'status': status.name,
        'due_date': dueDate?.toIso8601String(),
        'snoozed_until': snoozedUntil?.toIso8601String(),
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory FollowupItem.fromMap(Map<String, Object?> map) => FollowupItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        context: (map['context'] as String?) ?? '',
        assignee: (map['assignee'] as String?) ?? '',
        status: FollowupStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => FollowupStatus.open,
        ),
        dueDate: map['due_date'] == null ? null : DateTime.tryParse(map['due_date'] as String),
        snoozedUntil: map['snoozed_until'] == null ? null : DateTime.tryParse(map['snoozed_until'] as String),
        note: (map['note'] as String?) ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
