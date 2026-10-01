import 'package:flutter/material.dart';

import '../../core/date/persian_date.dart';
import '../../data/sprint_repository.dart';
import '../../models/sprint_item.dart';
import '../../state/sprint_store.dart';

class SprintsPage extends StatefulWidget {
  const SprintsPage({super.key});

  @override
  State<SprintsPage> createState() => _SprintsPageState();
}

class _SprintsPageState extends State<SprintsPage> {
  late final SprintStore store;

  @override
  void initState() {
    super.initState();
    store = SprintStore(SprintRepository())..addListener(_refresh);
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
    final active = store.items.where((e) => e.status == SprintStatus.active).length;
    return Scaffold(
      appBar: AppBar(title: const Text('اسپرینت‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('اسپرینت'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          Row(children: [
            Expanded(child: _Summary(label: 'کل اسپرینت‌ها', value: '${store.items.length}')),
            const SizedBox(width: 10),
            Expanded(child: _Summary(label: 'فعال', value: '$active')),
          ]),
          const SizedBox(height: 18),
          if (store.loading) const Center(child: CircularProgressIndicator()),
          if (!store.loading && store.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
              child: const Column(children: [Icon(Icons.loop_rounded, size: 42), SizedBox(height: 10), Text('اولین اسپرینت را بساز', style: TextStyle(fontWeight: FontWeight.w900))]),
            ),
          ...store.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SprintCard(item: item, onTap: () => _openEditor(item)),
              )),
        ],
      ),
    );
  }

  Future<void> _openEditor([SprintItem? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final goal = TextEditingController(text: current?.goal ?? '');
    final planned = TextEditingController(text: '${current?.plannedPoints ?? 0}');
    final completed = TextEditingController(text: '${current?.completedPoints ?? 0}');
    var status = current?.status ?? SprintStatus.planned;
    var start = current?.startDate ?? DateTime.now();
    var end = current?.endDate ?? DateTime.now().add(const Duration(days: 14));

    final saved = await showModalBottomSheet<SprintItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(current == null ? 'اسپرینت جدید' : 'ویرایش اسپرینت', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'نام اسپرینت')),
              const SizedBox(height: 10),
              TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
              const SizedBox(height: 10),
              TextField(controller: goal, maxLines: 2, decoration: const InputDecoration(labelText: 'Sprint Goal')),
              const SizedBox(height: 10),
              DropdownButtonFormField<SprintStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'وضعیت'),
                items: SprintStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_statusLabel(e)))).toList(),
                onChanged: (value) => setSheetState(() => status = value ?? SprintStatus.planned),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _DateField(label: 'شروع', value: start, onChanged: (value) => setSheetState(() => start = value))),
                const SizedBox(width: 10),
                Expanded(child: _DateField(label: 'پایان', value: end, onChanged: (value) => setSheetState(() => end = value))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: planned, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Story Point برنامه'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: completed, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Story Point انجام‌شده'))),
              ]),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.pop(context, SprintItem(
                    id: current?.id,
                    title: title.text.trim(),
                    project: project.text.trim(),
                    goal: goal.text.trim(),
                    status: status,
                    startDate: start,
                    endDate: end,
                    plannedPoints: int.tryParse(planned.text) ?? 0,
                    completedPoints: int.tryParse(completed.text) ?? 0,
                    createdAt: current?.createdAt ?? DateTime.now(),
                  ));
                },
                child: const Text('ذخیره'),
              ),
              if (current?.id != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await store.remove(current!.id!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف اسپرینت'),
                ),
              ],
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
  }

  static String _statusLabel(SprintStatus status) => switch (status) {
        SprintStatus.planned => 'برنامه‌ریزی',
        SprintStatus.active => 'فعال',
        SprintStatus.completed => 'تمام‌شده',
      };
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2024), lastDate: DateTime(2040));
          if (date != null) onChanged(date);
        },
        child: InputDecorator(decoration: InputDecoration(labelText: label), child: Text(PersianDate.short(value))),
      );
}

class _SprintCard extends StatelessWidget {
  final SprintItem item;
  final VoidCallback onTap;
  const _SprintCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(child: Icon(Icons.loop_rounded)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)), if (item.project.isNotEmpty) Text(item.project, style: Theme.of(context).textTheme.bodySmall)])),
              Chip(label: Text(_SprintsPageState._statusLabel(item.status))),
            ]),
            if (item.goal.isNotEmpty) ...[const SizedBox(height: 10), Text(item.goal)],
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: item.progress, minHeight: 8)),
            const SizedBox(height: 8),
            Row(children: [Text('${item.completedPoints}/${item.plannedPoints} SP', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${PersianDate.short(item.startDate)} تا ${PersianDate.short(item.endDate)}', style: Theme.of(context).textTheme.bodySmall)]),
          ]),
        ),
      );
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  const _Summary({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
      );
}
