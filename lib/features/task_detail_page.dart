import 'package:flutter/material.dart';
import '../models/task_item.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskItem task;
  final Future<void> Function(TaskItem updated) onSave;
  final Future<void> Function(int id)? onDelete;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final TextEditingController title;
  late final TextEditingController description;
  late final TextEditingController assignee;
  late final TextEditingController project;
  late TaskStatus status;
  late TaskPriority priority;
  DateTime? dueDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    title = TextEditingController(text: t.title);
    description = TextEditingController(text: t.description);
    assignee = TextEditingController(text: t.assignee);
    project = TextEditingController(text: t.project);
    status = t.status;
    priority = t.priority;
    dueDate = t.dueDate;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    assignee.dispose();
    project.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات کار'),
        actions: [
          if (widget.task.id != null && widget.onDelete != null)
            IconButton(
              tooltip: 'حذف',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('حذف کار؟'),
                    content: const Text('این عملیات قابل بازگشت نیست.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                    ],
                  ),
                );
                if (ok == true) {
                  await widget.onDelete!(widget.task.id!);
                  if (mounted) Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان کار', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: assignee, decoration: const InputDecoration(labelText: 'مسئول', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskStatus>(
            value: status,
            decoration: const InputDecoration(labelText: 'وضعیت', border: OutlineInputBorder()),
            items: TaskStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_statusLabel(e)))).toList(),
            onChanged: (v) => setState(() => status = v ?? status),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            value: priority,
            decoration: const InputDecoration(labelText: 'اولویت', border: OutlineInputBorder()),
            items: TaskPriority.values.map((e) => DropdownMenuItem(value: e, child: Text(_priorityLabel(e)))).toList(),
            onChanged: (v) => setState(() => priority = v ?? priority),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            leading: const Icon(Icons.event_rounded),
            title: const Text('موعد'),
            subtitle: Text(dueDate == null ? 'بدون موعد' : '${dueDate!.year}/${dueDate!.month}/${dueDate!.day}'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: dueDate ?? DateTime.now(),
              );
              if (picked != null) setState(() => dueDate = picked);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'توضیحات', alignLabelWithHint: true, border: OutlineInputBorder()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('ذخیره تغییرات')),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) return;
    setState(() => saving = true);
    await widget.onSave(widget.task.copyWith(
      title: title.text.trim(),
      project: project.text.trim().isEmpty ? 'بدون پروژه' : project.text.trim(),
      assignee: assignee.text.trim(),
      status: status,
      priority: priority,
      dueDate: dueDate,
      description: description.text.trim(),
    ));
    if (mounted) {
      setState(() => saving = false);
      Navigator.pop(context, true);
    }
  }

  String _statusLabel(TaskStatus value) => switch (value) {
        TaskStatus.backlog => 'بک‌لاگ',
        TaskStatus.todo => 'آماده انجام',
        TaskStatus.doing => 'در حال انجام',
        TaskStatus.review => 'بررسی',
        TaskStatus.done => 'انجام شده',
      };

  String _priorityLabel(TaskPriority value) => switch (value) {
        TaskPriority.low => 'کم',
        TaskPriority.medium => 'متوسط',
        TaskPriority.high => 'بالا',
        TaskPriority.urgent => 'فوری',
      };
}
