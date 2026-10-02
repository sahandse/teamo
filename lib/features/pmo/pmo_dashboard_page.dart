import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/date/persian_date.dart';
import '../../data/pmo_repository.dart';

class PmoDashboardPage extends StatefulWidget {
  const PmoDashboardPage({super.key});

  @override
  State<PmoDashboardPage> createState() => _PmoDashboardPageState();
}

class _PmoDashboardPageState extends State<PmoDashboardPage> with SingleTickerProviderStateMixin {
  final repo = PmoRepository();
  late final TabController tabs;
  List<RegisterItem> registers = [];
  List<OkrItem> okrs = [];
  List<Map<String, Object?>> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await Future.wait([repo.registers(), repo.okrs(), repo.projectHealth()]);
    if (!mounted) return;
    setState(() {
      registers = data[0] as List<RegisterItem>;
      okrs = data[1] as List<OkrItem>;
      projects = data[2] as List<Map<String, Object?>>;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PMO Control Center'),
        actions: [IconButton(onPressed: _exportCsv, tooltip: 'خروجی CSV', icon: const Icon(Icons.file_download_outlined))],
        bottom: TabBar(controller: tabs, isScrollable: true, tabs: const [Tab(text: 'Portfolio'), Tab(text: 'Risk / Issue'), Tab(text: 'KPI / OKR'), Tab(text: 'گزارش')]),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: tabs, children: [_portfolio(), _register(), _okr(), _report()]),
      floatingActionButton: AnimatedBuilder(
        animation: tabs,
        builder: (context, _) => tabs.index == 1
            ? FloatingActionButton.extended(onPressed: () => _editRegister(), icon: const Icon(Icons.add_rounded), label: const Text('ریسک / مسئله'))
            : tabs.index == 2
                ? FloatingActionButton.extended(onPressed: () => _editOkr(), icon: const Icon(Icons.add_rounded), label: const Text('OKR'))
                : const SizedBox.shrink(),
      ),
    );
  }

  Widget _portfolio() {
    final atRisk = projects.where((p) => '${p['status']}' == 'atRisk' || '${p['status']}' == 'delayed').length;
    final active = projects.where((p) => '${p['status']}' == 'active').length;
    final avg = projects.isEmpty ? 0.0 : projects.fold<double>(0, (sum, p) => sum + ((p['progress'] as num?)?.toDouble() ?? 0)) / projects.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(children: [
          Expanded(child: _Metric(icon: Icons.layers_outlined, label: 'پروژه‌ها', value: '${projects.length}')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.play_circle_outline_rounded, label: 'فعال', value: '$active')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Metric(icon: Icons.warning_amber_rounded, label: 'نیازمند توجه', value: '$atRisk')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.insights_rounded, label: 'میانگین پیشرفت', value: '${(avg * 100).round()}٪')),
        ]),
        const SizedBox(height: 18),
        Text('سلامت Portfolio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (projects.isEmpty) const _Empty(title: 'پروژه‌ای ثبت نشده', subtitle: 'پروژه‌ها از بخش پروژه‌های تیمو وارد Portfolio می‌شوند.'),
        ...projects.map((p) {
          final progress = ((p['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0).toDouble();
          final status = '${p['status'] ?? 'active'}';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${p['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  _StatusChip(label: _projectStatus(status)),
                ]),
                if ('${p['owner'] ?? ''}'.isNotEmpty) ...[const SizedBox(height: 4), Text('مالک: ${p['owner']}', style: Theme.of(context).textTheme.bodySmall)],
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8)),
                const SizedBox(height: 6),
                Text('${(progress * 100).round()}٪ پیشرفت', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _register() {
    final risks = registers.where((e) => e.type == RegisterType.risk).length;
    final issues = registers.where((e) => e.type == RegisterType.issue).length;
    final critical = registers.where((e) => e.status != RegisterStatus.closed && (e.score >= 12 || e.severity == 'critical')).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(children: [
          Expanded(child: _Metric(icon: Icons.warning_amber_rounded, label: 'Risk', value: '$risks')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.report_problem_outlined, label: 'Issue', value: '$issues')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.priority_high_rounded, label: 'بحرانی', value: '$critical')),
        ]),
        const SizedBox(height: 16),
        if (registers.isEmpty) const _Empty(title: 'Risk / Issue Register خالی است', subtitle: 'ریسک‌ها و مسائل پروژه‌ها را اینجا ثبت و پیگیری کن.'),
        ...registers.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => _editRegister(item),
                leading: CircleAvatar(child: Icon(item.type == RegisterType.risk ? Icons.warning_amber_rounded : Icons.report_problem_outlined)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${item.project.isEmpty ? 'بدون پروژه' : item.project} • ${item.owner.isEmpty ? 'بدون مالک' : item.owner}\nScore: ${item.score.toStringAsFixed(1)} • ${_registerStatus(item.status)}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
            )),
      ],
    );
  }

  Widget _okr() {
    final active = okrs.where((e) => e.status == ObjectiveStatus.active).length;
    final done = okrs.where((e) => e.status == ObjectiveStatus.done).length;
    final avg = okrs.isEmpty ? 0.0 : okrs.fold<double>(0, (sum, e) => sum + e.progress) / okrs.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(children: [
          Expanded(child: _Metric(icon: Icons.track_changes_rounded, label: 'فعال', value: '$active')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.done_all_rounded, label: 'تکمیل', value: '$done')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.percent_rounded, label: 'میانگین', value: '${(avg * 100).round()}٪')),
        ]),
        const SizedBox(height: 16),
        if (okrs.isEmpty) const _Empty(title: 'KPI / OKR ثبت نشده', subtitle: 'Objective و Key Resultهای قابل اندازه‌گیری تعریف کن.'),
        ...okrs.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _editOkr(item),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(item.objective, style: const TextStyle(fontWeight: FontWeight.w900))), _StatusChip(label: _objectiveStatus(item.status))]),
                    const SizedBox(height: 5),
                    Text(item.keyResult),
                    const SizedBox(height: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: item.progress, minHeight: 8)),
                    const SizedBox(height: 7),
                    Row(children: [Text('${item.current.toStringAsFixed(0)} / ${item.target.toStringAsFixed(0)} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), if (item.dueDate != null) Text(PersianDate.short(item.dueDate!), style: Theme.of(context).textTheme.bodySmall)]),
                  ]),
                ),
              ),
            )),
      ],
    );
  }

  Widget _report() {
    final openRisks = registers.where((e) => e.type == RegisterType.risk && e.status != RegisterStatus.closed).length;
    final openIssues = registers.where((e) => e.type == RegisterType.issue && e.status != RegisterStatus.closed).length;
    final atRiskOkrs = okrs.where((e) => e.status == ObjectiveStatus.atRisk).length;
    final score = (100 - openRisks * 5 - openIssues * 7 - atRiskOkrs * 8).clamp(0, 100);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PMO Health Score', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('$score / 100', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: score / 100, minHeight: 10),
          ]),
        ),
        const SizedBox(height: 16),
        _ReportTile(icon: Icons.warning_amber_rounded, title: 'ریسک باز', value: '$openRisks'),
        _ReportTile(icon: Icons.report_problem_outlined, title: 'Issue باز', value: '$openIssues'),
        _ReportTile(icon: Icons.track_changes_rounded, title: 'OKR در معرض خطر', value: '$atRiskOkrs'),
        _ReportTile(icon: Icons.layers_outlined, title: 'تعداد پروژه‌ها', value: '${projects.length}'),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.content_copy_rounded), label: const Text('کپی گزارش CSV')),
        const SizedBox(height: 8),
        Text('گزارش شامل Risk Register، Issue Register و KPI/OKR است و می‌توان آن را در Excel یا Google Sheets وارد کرد.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _editRegister([RegisterItem? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final owner = TextEditingController(text: current?.owner ?? '');
    final probability = TextEditingController(text: '${current?.probability ?? 0}');
    final impact = TextEditingController(text: '${current?.impact ?? 0}');
    final plan = TextEditingController(text: current?.responsePlan ?? '');
    var type = current?.type ?? RegisterType.risk;
    var status = current?.status ?? RegisterStatus.open;
    var severity = current?.severity ?? 'medium';

    final saved = await showModalBottomSheet<RegisterItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(current == null ? 'ثبت Risk / Issue' : 'ویرایش Risk / Issue', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                SegmentedButton<RegisterType>(segments: const [ButtonSegment(value: RegisterType.risk, label: Text('Risk')), ButtonSegment(value: RegisterType.issue, label: Text('Issue'))], selected: {type}, onSelectionChanged: (v) => setSheetState(() => type = v.first)),
                const SizedBox(height: 10),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان')),
                const SizedBox(height: 10),
                TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
                const SizedBox(height: 10),
                TextField(controller: owner, decoration: const InputDecoration(labelText: 'مالک / مسئول')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(initialValue: severity, decoration: const InputDecoration(labelText: 'شدت'), items: const [DropdownMenuItem(value: 'low', child: Text('کم')), DropdownMenuItem(value: 'medium', child: Text('متوسط')), DropdownMenuItem(value: 'high', child: Text('بالا')), DropdownMenuItem(value: 'critical', child: Text('بحرانی'))], onChanged: (v) => setSheetState(() => severity = v ?? 'medium')),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: probability, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Probability 1-5'))), const SizedBox(width: 10), Expanded(child: TextField(controller: impact, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Impact 1-5')))]),
                const SizedBox(height: 10),
                DropdownButtonFormField<RegisterStatus>(initialValue: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: RegisterStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_registerStatus(e)))).toList(), onChanged: (v) => setSheetState(() => status = v ?? RegisterStatus.open)),
                const SizedBox(height: 10),
                TextField(controller: plan, maxLines: 3, decoration: const InputDecoration(labelText: 'Response / Mitigation Plan')),
                const SizedBox(height: 16),
                FilledButton(onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.pop(context, RegisterItem(id: current?.id, type: type, title: title.text.trim(), project: project.text.trim(), owner: owner.text.trim(), severity: severity, probability: double.tryParse(probability.text) ?? 0, impact: double.tryParse(impact.text) ?? 0, status: status, responsePlan: plan.text.trim(), createdAt: current?.createdAt ?? DateTime.now()));
                }, child: const Text('ذخیره')),
                if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteRegister(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
              ]),
            ),
          )),
    );
    if (saved != null) await repo.saveRegister(saved);
    await _load();
  }

  Future<void> _editOkr([OkrItem? current]) async {
    final objective = TextEditingController(text: current?.objective ?? '');
    final keyResult = TextEditingController(text: current?.keyResult ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final owner = TextEditingController(text: current?.owner ?? '');
    final currentValue = TextEditingController(text: '${current?.current ?? 0}');
    final target = TextEditingController(text: '${current?.target ?? 100}');
    final unit = TextEditingController(text: current?.unit ?? '%');
    var status = current?.status ?? ObjectiveStatus.active;
    var due = current?.dueDate;

    final saved = await showModalBottomSheet<OkrItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(current == null ? 'OKR جدید' : 'ویرایش OKR', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(controller: objective, decoration: const InputDecoration(labelText: 'Objective')),
                const SizedBox(height: 10),
                TextField(controller: keyResult, decoration: const InputDecoration(labelText: 'Key Result')),
                const SizedBox(height: 10),
                TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
                const SizedBox(height: 10),
                TextField(controller: owner, decoration: const InputDecoration(labelText: 'مالک')),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: currentValue, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مقدار فعلی'))), const SizedBox(width: 10), Expanded(child: TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'هدف'))), const SizedBox(width: 10), SizedBox(width: 78, child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'واحد')))]),
                const SizedBox(height: 10),
                DropdownButtonFormField<ObjectiveStatus>(initialValue: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: ObjectiveStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_objectiveStatus(e)))).toList(), onChanged: (v) => setSheetState(() => status = v ?? ObjectiveStatus.active)),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2040)); if (date != null) setSheetState(() => due = date); }, icon: const Icon(Icons.calendar_month_outlined), label: Text(due == null ? 'انتخاب موعد' : PersianDate.short(due!))),
                const SizedBox(height: 16),
                FilledButton(onPressed: () {
                  if (objective.text.trim().isEmpty || keyResult.text.trim().isEmpty) return;
                  Navigator.pop(context, OkrItem(id: current?.id, objective: objective.text.trim(), keyResult: keyResult.text.trim(), project: project.text.trim(), owner: owner.text.trim(), target: double.tryParse(target.text) ?? 100, current: double.tryParse(currentValue.text) ?? 0, unit: unit.text.trim().isEmpty ? '%' : unit.text.trim(), status: status, dueDate: due, createdAt: current?.createdAt ?? DateTime.now()));
                }, child: const Text('ذخیره')),
                if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteOkr(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
              ]),
            ),
          )),
    );
    if (saved != null) await repo.saveOkr(saved);
    await _load();
  }

  Future<void> _exportCsv() async {
    final csv = await repo.csvReport();
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گزارش CSV در کلیپ‌بورد کپی شد')));
  }

  static String _registerStatus(RegisterStatus s) => switch (s) { RegisterStatus.open => 'باز', RegisterStatus.monitoring => 'پایش', RegisterStatus.mitigated => 'کنترل‌شده', RegisterStatus.closed => 'بسته' };
  static String _objectiveStatus(ObjectiveStatus s) => switch (s) { ObjectiveStatus.active => 'فعال', ObjectiveStatus.atRisk => 'در معرض خطر', ObjectiveStatus.done => 'تکمیل' };
  static String _projectStatus(String s) => switch (s) { 'active' => 'فعال', 'atRisk' => 'در معرض خطر', 'delayed' => 'تاخیر', 'completed' => 'تکمیل', _ => s };
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(height: 10), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)]));
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});
  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ReportTile({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(title), trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))));
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)), child: Column(children: [const Icon(Icons.dashboard_customize_outlined, size: 42), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center)]));
}
