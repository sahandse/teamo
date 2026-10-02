import 'package:flutter/material.dart';

import '../../data/scrum_governance_repository.dart';
import '../../data/sprint_repository.dart';
import '../../models/sprint_item.dart';

class ScrumGovernancePage extends StatefulWidget {
  const ScrumGovernancePage({super.key});

  @override
  State<ScrumGovernancePage> createState() => _ScrumGovernancePageState();
}

class _ScrumGovernancePageState extends State<ScrumGovernancePage> with SingleTickerProviderStateMixin {
  final repo = ScrumGovernanceRepository();
  final sprintRepo = SprintRepository();
  late final TabController tabs;
  List<SprintItem> sprints = [];
  List<Map<String, Object?>> reviews = [];
  List<Map<String, Object?>> dod = [];
  List<Map<String, Object?>> capacity = [];
  List<Map<String, Object?>> impediments = [];
  int? sprintId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await Future.wait([sprintRepo.all(), repo.reviews(), repo.dod(), repo.capacity(), repo.impediments()]);
    if (!mounted) return;
    setState(() {
      sprints = result[0] as List<SprintItem>;
      reviews = result[1] as List<Map<String, Object?>>;
      dod = result[2] as List<Map<String, Object?>>;
      capacity = result[3] as List<Map<String, Object?>>;
      impediments = result[4] as List<Map<String, Object?>>;
      sprintId ??= sprints.where((e) => e.status == SprintStatus.active).map((e) => e.id).whereType<int>().firstOrNull;
      sprintId ??= sprints.map((e) => e.id).whereType<int>().firstOrNull;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrum Control Center'),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'گزارش'),
            Tab(text: 'Sprint Review'),
            Tab(text: 'Definition of Done'),
            Tab(text: 'ظرفیت تیم'),
            Tab(text: 'موانع'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (sprints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DropdownButtonFormField<int>(
                    initialValue: sprintId,
                    decoration: const InputDecoration(labelText: 'اسپرینت'),
                    items: sprints.where((e) => e.id != null).map((e) => DropdownMenuItem(value: e.id!, child: Text(e.title))).toList(),
                    onChanged: (value) => setState(() => sprintId = value),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: [_report(), _reviews(), _dod(), _capacity(), _impediments()],
                ),
              ),
            ]),
    );
  }

  Widget _report() {
    final open = impediments.where((e) => e['status'] == 'open').length;
    final doneDod = dod.where((e) => e['is_done'] == 1).length;
    final hours = capacity.where((e) => sprintId == null || e['sprint_id'] == sprintId).fold<double>(0, (sum, e) => sum + ((e['available_hours'] as num?)?.toDouble() ?? 0));
    final effective = capacity.where((e) => sprintId == null || e['sprint_id'] == sprintId).fold<double>(0, (sum, e) {
      final h = (e['available_hours'] as num?)?.toDouble() ?? 0;
      final f = (e['focus_factor'] as num?)?.toDouble() ?? 1;
      return sum + h * f;
    });
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Metric(label: 'Sprint Review', value: '${reviews.length}', icon: Icons.rate_review_outlined),
          _Metric(label: 'DoD تکمیل', value: '$doneDod/${dod.length}', icon: Icons.verified_outlined),
          _Metric(label: 'موانع باز', value: '$open', icon: Icons.warning_amber_rounded),
          _Metric(label: 'ظرفیت موثر', value: '${effective.toStringAsFixed(1)}h', icon: Icons.groups_2_outlined),
        ]),
        const SizedBox(height: 18),
        _Panel(
          title: 'وضعیت تیم',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ظرفیت خام: ${hours.toStringAsFixed(1)} ساعت'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: hours <= 0 ? 0 : (effective / hours).clamp(0, 1)),
            const SizedBox(height: 8),
            Text('Focus Factor ظرفیت تیم را به ظرفیت واقعی قابل برنامه‌ریزی تبدیل می‌کند.', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const SizedBox(height: 12),
        _Panel(
          title: 'چک مدیریتی Scrum',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Check(ok: sprintId != null, text: 'اسپرینت فعال/انتخاب‌شده دارد'),
            _Check(ok: dod.isNotEmpty, text: 'Definition of Done تعریف شده'),
            _Check(ok: open == 0, text: 'مانع باز بحرانی وجود ندارد'),
            _Check(ok: effective > 0, text: 'ظرفیت تیم ثبت شده'),
            _Check(ok: reviews.isNotEmpty, text: 'Sprint Review ثبت شده'),
          ]),
        ),
      ],
    );
  }

  Widget _reviews() => _CrudList(
        empty: 'هنوز Sprint Review ثبت نشده.',
        children: reviews.where((e) => sprintId == null || e['sprint_id'] == sprintId).map((e) => ListTile(
              title: Text((e['summary'] as String?)?.isNotEmpty == true ? e['summary'] as String : 'Sprint Review'),
              subtitle: Text('تایید: ${e['accepted'] ?? '-'}\nرد/Carry-over: ${e['rejected'] ?? '-'}\nFeedback: ${e['feedback'] ?? '-'}'),
              isThreeLine: true,
            )),
        onAdd: _addReview,
      );

  Widget _dod() => _CrudList(
        empty: 'Definition of Done را تعریف کن.',
        children: dod.map((e) => CheckboxListTile(
              value: e['is_done'] == 1,
              title: Text(e['title'] as String? ?? ''),
              onChanged: (value) async {
                await repo.toggleDod(e['id'] as int, value ?? false);
                await _load();
              },
            )),
        onAdd: _addDod,
      );

  Widget _capacity() => _CrudList(
        empty: 'ظرفیت اعضای تیم هنوز ثبت نشده.',
        children: capacity.where((e) => sprintId == null || e['sprint_id'] == sprintId).map((e) {
          final h = (e['available_hours'] as num?)?.toDouble() ?? 0;
          final f = (e['focus_factor'] as num?)?.toDouble() ?? 1;
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
            title: Text(e['member_name'] as String? ?? ''),
            subtitle: Text('${h.toStringAsFixed(1)} ساعت × ${f.toStringAsFixed(2)} = ${(h * f).toStringAsFixed(1)} ساعت موثر'),
          );
        }),
        onAdd: _addCapacity,
      );

  Widget _impediments() => _CrudList(
        empty: 'مانعی ثبت نشده.',
        children: impediments.where((e) => sprintId == null || e['sprint_id'] == sprintId).map((e) => ListTile(
              leading: Icon(e['status'] == 'open' ? Icons.report_problem_outlined : Icons.check_circle_outline_rounded),
              title: Text(e['title'] as String? ?? ''),
              subtitle: Text('مالک: ${e['owner'] ?? '-'} • شدت: ${e['severity'] ?? '-'}${(e['note'] as String?)?.isNotEmpty == true ? '\n${e['note']}' : ''}'),
              trailing: e['status'] == 'open'
                  ? IconButton(
                      tooltip: 'بستن مانع',
                      onPressed: () async {
                        await repo.closeImpediment(e['id'] as int);
                        await _load();
                      },
                      icon: const Icon(Icons.done_rounded),
                    )
                  : null,
            )),
        onAdd: _addImpediment,
      );

  Future<void> _addReview() async {
    if (sprintId == null) return;
    final summary = TextEditingController();
    final accepted = TextEditingController();
    final rejected = TextEditingController();
    final feedback = TextEditingController();
    final ok = await _form('Sprint Review', [
      TextField(controller: summary, maxLines: 2, decoration: const InputDecoration(labelText: 'خلاصه Review')),
      TextField(controller: accepted, maxLines: 2, decoration: const InputDecoration(labelText: 'موارد تاییدشده')),
      TextField(controller: rejected, maxLines: 2, decoration: const InputDecoration(labelText: 'ردشده / Carry-over')),
      TextField(controller: feedback, maxLines: 3, decoration: const InputDecoration(labelText: 'Feedback ذی‌نفعان')),
    ]);
    if (ok == true) {
      await repo.addReview(sprintId: sprintId!, summary: summary.text, accepted: accepted.text, rejected: rejected.text, feedback: feedback.text);
      await _load();
    }
  }

  Future<void> _addDod() async {
    final c = TextEditingController();
    final ok = await _form('Definition of Done', [TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'معیار تکمیل'))]);
    if (ok == true && c.text.trim().isNotEmpty) {
      await repo.addDod(c.text.trim());
      await _load();
    }
  }

  Future<void> _addCapacity() async {
    if (sprintId == null) return;
    final name = TextEditingController();
    final hours = TextEditingController();
    final focus = TextEditingController(text: '0.8');
    final ok = await _form('ظرفیت عضو تیم', [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'نام عضو')),
      TextField(controller: hours, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ساعت در دسترس')),
      TextField(controller: focus, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Focus Factor (مثلاً 0.8)')),
    ]);
    if (ok == true && name.text.trim().isNotEmpty) {
      await repo.addCapacity(sprintId: sprintId!, member: name.text.trim(), hours: double.tryParse(hours.text) ?? 0, focusFactor: (double.tryParse(focus.text) ?? 1).clamp(0, 1));
      await _load();
    }
  }

  Future<void> _addImpediment() async {
    if (sprintId == null) return;
    final title = TextEditingController();
    final owner = TextEditingController();
    final note = TextEditingController();
    var severity = 'medium';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('مانع جدید', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان مانع')),
          const SizedBox(height: 10),
          TextField(controller: owner, decoration: const InputDecoration(labelText: 'مالک پیگیری')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: severity, decoration: const InputDecoration(labelText: 'شدت'), items: const [DropdownMenuItem(value: 'low', child: Text('کم')), DropdownMenuItem(value: 'medium', child: Text('متوسط')), DropdownMenuItem(value: 'high', child: Text('زیاد')), DropdownMenuItem(value: 'critical', child: Text('بحرانی'))], onChanged: (v) => setState(() => severity = v ?? 'medium')),
          const SizedBox(height: 10),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ])),
      )),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      await repo.addImpediment(sprintId: sprintId!, title: title.text.trim(), owner: owner.text.trim(), severity: severity, note: note.text.trim());
      await _load();
    }
  }

  Future<bool?> _form(String title, List<Widget> fields) => showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            ...fields.expand((e) => [e, const SizedBox(height: 10)]),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
          ])),
        ),
      );
}

class _CrudList extends StatelessWidget {
  final Iterable<Widget> children;
  final String empty;
  final VoidCallback onAdd;
  const _CrudList({required this.children, required this.empty, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final list = children.toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      Align(alignment: Alignment.centerLeft, child: FilledButton.tonalIcon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('افزودن'))),
      const SizedBox(height: 12),
      if (list.isEmpty) _Panel(title: empty, child: const SizedBox.shrink()) else ...list,
    ]);
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
      );
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 12), child]),
      );
}

class _Check extends StatelessWidget {
  final bool ok;
  final String text;
  const _Check({required this.ok, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20), const SizedBox(width: 8), Expanded(child: Text(text))]),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
