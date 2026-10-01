import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../state/task_store.dart';

class TaskBoardPage extends StatefulWidget {
  final TaskStore store;
  const TaskBoardPage({super.key, required this.store});

  @override
  State<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends State<TaskBoardPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    if (widget.store.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('کارها', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('کارت‌ها را نگه دار و بین ستون‌ها جابه‌جا کن', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showTaskForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('کار جدید'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: TaskStatus.values.map((status) {
                  return _KanbanColumn(
                    status: status,
                    tasks: widget.store.byStatus(status),
                    onMove: widget.store.move,
                    onDelete: widget.store.remove,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskForm(BuildContext context) async {
    final title = TextEditingController();
    final project = TextEditingController(text: 'تیمو');
    final assignee = TextEditingController();
    TaskPriority priority = TaskPriority.medium;

    final created = await showModalBottomSheet<TaskItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('کار جدید', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'عنوان کار', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: assignee, decoration: const InputDecoration(labelText: 'مسئول', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'اولویت', border: OutlineInputBorder()),
                  items: TaskPriority.values.map((item) => DropdownMenuItem(value: item, child: Text(_priorityLabel(item)))).toList(),
                  onChanged: (value) => setSheetState(() => priority = value ?? TaskPriority.medium),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (title.text.trim().isEmpty) return;
                    Navigator.pop(
                      sheetContext,
                      TaskItem(
                        title: title.text.trim(),
                        project: project.text.trim().isEmpty ? 'بدون پروژه' : project.text.trim(),
                        assignee: assignee.text.trim(),
                        priority: priority,
                        status: TaskStatus.backlog,
                        createdAt: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('ساخت کار'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (created != null) await widget.store.add(created);
  }
}

class _KanbanColumn extends StatelessWidget {
  final TaskStatus status;
  final List<TaskItem> tasks;
  final Future<void> Function(TaskItem task, TaskStatus status) onMove;
  final Future<void> Function(TaskItem task) onDelete;

  const _KanbanColumn({required this.status, required this.tasks, required this.onMove, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskItem>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => onMove(details.data, status),
      builder: (context, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 292,
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(.45)
                : Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: active ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(_statusLabel(status), style: const TextStyle(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Badge(label: Text('${tasks.length}')),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: Text('کارت را اینجا رها کن', style: Theme.of(context).textTheme.bodySmall),
                ),
              ...tasks.map((task) => LongPressDraggable<TaskItem>(
                    data: task,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(width: 272, child: _TaskCard(task: task, onDelete: () {})),
                    ),
                    childWhenDragging: Opacity(opacity: .35, child: _TaskCard(task: task, onDelete: () {})),
                    child: _TaskCard(task: task, onDelete: () => onDelete(task)),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onDelete;
  const _TaskCard({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = switch (task.priority) {
      TaskPriority.low => Colors.green,
      TaskPriority.medium => Colors.amber,
      TaskPriority.high => Colors.orange,
      TaskPriority.urgent => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onSelected: (value) { if (value == 'delete') onDelete(); },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('حذف'))],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.project, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_priorityLabel(task.priority), style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                if (task.assignee.isNotEmpty) ...[
                  const Icon(Icons.person_outline_rounded, size: 15),
                  const SizedBox(width: 4),
                  Text(task.assignee, style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(TaskStatus status) => switch (status) {
      TaskStatus.backlog => 'بک‌لاگ',
      TaskStatus.todo => 'آماده انجام',
      TaskStatus.doing => 'در حال انجام',
      TaskStatus.review => 'بررسی',
      TaskStatus.done => 'انجام شد',
    };

String _priorityLabel(TaskPriority priority) => switch (priority) {
      TaskPriority.low => 'کم',
      TaskPriority.medium => 'متوسط',
      TaskPriority.high => 'بالا',
      TaskPriority.urgent => 'فوری',
    };
