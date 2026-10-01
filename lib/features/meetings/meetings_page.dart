import 'package:flutter/material.dart';

import '../../core/date/persian_date.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/meeting_repository.dart';
import '../../models/meeting_item.dart';
import '../../state/meeting_store.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  late final MeetingStore store;

  @override
  void initState() {
    super.initState();
    store = MeetingStore(MeetingRepository())..addListener(_refresh);
    store.load();
  }

  @override
  void dispose() {
    store.removeListener(_refresh);
    store.dispose();
    super.dispose();
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('جلسات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('جلسه، دستور جلسه، مصوبات و اقدام بعدی', style: Theme.of(context).textTheme.bodySmall),
              ])),
              FilledButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add_rounded), label: const Text('جلسه')),
            ]),
            const SizedBox(height: 18),
            if (store.loading) const Center(child: CircularProgressIndicator()),
            if (!store.loading && store.items.isEmpty)
              _Empty(onAdd: () => _openEditor()),
            ...store.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MeetingCard(
                    item: item,
                    onTap: () => _openEditor(item),
                    onDelete: item.id == null ? null : () => store.remove(item.id!),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor([MeetingItem? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final attendees = TextEditingController(text: current?.attendees ?? '');
    final agenda = TextEditingController(text: current?.agenda ?? '');
    final decisions = TextEditingController(text: current?.decisions ?? '');
    final actions = TextEditingController(text: current?.actionItems ?? '');
    final notes = TextEditingController(text: current?.notes ?? '');
    var startsAt = current?.startsAt ?? DateTime.now().add(const Duration(hours: 1));
    var duration = current?.durationMinutes ?? 30;

    final saved = await showModalBottomSheet<MeetingItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(current == null ? 'جلسه جدید' : 'ویرایش جلسه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان جلسه')),
              const SizedBox(height: 10),
              TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
              const SizedBox(height: 10),
              TextField(controller: attendees, decoration: const InputDecoration(labelText: 'شرکت‌کنندگان')),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final date = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: startsAt);
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startsAt));
                  if (time == null) return;
                  setSheetState(() => startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'تاریخ و ساعت'),
                  child: Text('${PersianDate.full(startsAt)} • ${TimeOfDay.fromDateTime(startsAt).format(context)}'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: duration,
                decoration: const InputDecoration(labelText: 'مدت جلسه'),
                items: const [15, 30, 45, 60, 90].map((e) => DropdownMenuItem(value: e, child: Text('$e دقیقه'))).toList(),
                onChanged: (value) => setSheetState(() => duration = value ?? 30),
              ),
              const SizedBox(height: 10),
              TextField(controller: agenda, maxLines: 3, decoration: const InputDecoration(labelText: 'دستور جلسه')),
              const SizedBox(height: 10),
              TextField(controller: decisions, maxLines: 3, decoration: const InputDecoration(labelText: 'مصوبات')),
              const SizedBox(height: 10),
              TextField(controller: actions, maxLines: 3, decoration: const InputDecoration(labelText: 'Action Itemها')),
              const SizedBox(height: 10),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت')),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.pop(
                    context,
                    MeetingItem(
                      id: current?.id,
                      title: title.text.trim(),
                      project: project.text.trim(),
                      attendees: attendees.text.trim(),
                      startsAt: startsAt,
                      durationMinutes: duration,
                      agenda: agenda.text.trim(),
                      decisions: decisions.text.trim(),
                      actionItems: actions.text.trim(),
                      notes: notes.text.trim(),
                      createdAt: current?.createdAt ?? DateTime.now(),
                    ),
                  );
                },
                child: const Text('ذخیره جلسه'),
              ),
            ]),
          ),
        );
      }),
    );

    if (saved == null) return;
    if (current == null) {
      await store.add(saved);
    } else {
      await store.update(saved);
    }
    final reminderAt = saved.startsAt.subtract(const Duration(minutes: 15));
    final id = (saved.id ?? saved.startsAt.millisecondsSinceEpoch).abs() % 2147483647;
    await NotificationService.instance.scheduleReminder(
      id: id,
      title: 'جلسه نزدیک است',
      body: '${saved.title} تا ۱۵ دقیقه دیگر شروع می‌شود.',
      when: reminderAt,
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _MeetingCard({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          CircleAvatar(child: Text(TimeOfDay.fromDateTime(item.startsAt).hour.toString().padLeft(2, '0'))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${PersianDate.relative(item.startsAt)} • ${PersianDate.short(item.startsAt)} • ${item.durationMinutes} دقیقه', style: Theme.of(context).textTheme.bodySmall),
            if (item.project.isNotEmpty) Text(item.project, style: Theme.of(context).textTheme.labelSmall),
          ])),
          if (onDelete != null) IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
          const Icon(Icons.chevron_left_rounded),
        ]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Icon(Icons.event_available_rounded, size: 44),
          const SizedBox(height: 10),
          const Text('هنوز جلسه‌ای ثبت نشده', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('ساخت اولین جلسه')),
        ]),
      );
}
