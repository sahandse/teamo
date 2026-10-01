class MeetingItem {
  final int? id;
  final String title;
  final String project;
  final String attendees;
  final DateTime startsAt;
  final int durationMinutes;
  final String agenda;
  final String decisions;
  final String actionItems;
  final String notes;
  final DateTime createdAt;

  const MeetingItem({
    this.id,
    required this.title,
    this.project = '',
    this.attendees = '',
    required this.startsAt,
    this.durationMinutes = 30,
    this.agenda = '',
    this.decisions = '',
    this.actionItems = '',
    this.notes = '',
    required this.createdAt,
  });

  MeetingItem copyWith({
    int? id,
    String? title,
    String? project,
    String? attendees,
    DateTime? startsAt,
    int? durationMinutes,
    String? agenda,
    String? decisions,
    String? actionItems,
    String? notes,
    DateTime? createdAt,
  }) => MeetingItem(
        id: id ?? this.id,
        title: title ?? this.title,
        project: project ?? this.project,
        attendees: attendees ?? this.attendees,
        startsAt: startsAt ?? this.startsAt,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        agenda: agenda ?? this.agenda,
        decisions: decisions ?? this.decisions,
        actionItems: actionItems ?? this.actionItems,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'project': project,
        'attendees': attendees,
        'starts_at': startsAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'agenda': agenda,
        'decisions': decisions,
        'action_items': actionItems,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory MeetingItem.fromMap(Map<String, Object?> map) => MeetingItem(
        id: map['id'] as int?,
        title: map['title'] as String,
        project: (map['project'] as String?) ?? '',
        attendees: (map['attendees'] as String?) ?? '',
        startsAt: DateTime.tryParse((map['starts_at'] as String?) ?? '') ?? DateTime.now(),
        durationMinutes: (map['duration_minutes'] as int?) ?? 30,
        agenda: (map['agenda'] as String?) ?? '',
        decisions: (map['decisions'] as String?) ?? '',
        actionItems: (map['action_items'] as String?) ?? '',
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      );
}
