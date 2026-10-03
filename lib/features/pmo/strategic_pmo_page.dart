import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/date/persian_date.dart';
import '../../data/strategic_pmo_repository.dart';

class StrategicPmoPage extends StatefulWidget {
  const StrategicPmoPage({super.key});

  @override
  State<StrategicPmoPage> createState() => _StrategicPmoPageState();
}

class _StrategicPmoPageState extends State<StrategicPmoPage> with SingleTickerProviderStateMixin {
  final repo = StrategicPmoRepository();
  late final TabController tabs;
  List<ScenarioPlan> scenarios = [];
  List<EvmEntry> evm = [];
  List<PortfolioPriority> priorities = [];
  List<BenefitItem> benefits = [];
  List<ExecutiveReport> reports = [];
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
    final data = await Future.wait([repo.scenarios(), repo.evmEntries(), repo.priorities(), repo.benefits(), repo.reports()]);
    if (!mounted) return;
    setState(() {
      scenarios = data[0] as List<ScenarioPlan>;
      evm = data[1] as List<EvmEntry>;
      priorities = data[2] as List<PortfolioPriority>;
      benefits = data[3] as List<BenefitItem>;
      reports = data[4] as List<ExecutiveReport>;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Strategic PMO'),
          bottom: TabBar(controller: tabs, isScrollable: true, tabs: const [
            Tab(text: 'Scenario'),
            Tab(text: 'EVM'),
            Tab(text: 'Priority'),
            Tab(text: 'Benefits'),
            Tab(text: 'Executive'),
          ]),
        ),
        body: loading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: tabs, children: [_scenarioTab(), _evmTab(), _priorityTab(), _benefitTab(), _reportTab()]),
        floatingActionButton: AnimatedBuilder(
          animation: tabs,
          builder: (context, _) => switch (tabs.index) {
            0 => FloatingActionButton.extended(onPressed: () => _editScenario(), icon: const Icon(Icons.add_rounded), label: const Text('Scenario')),
            1 => FloatingActionButton.extended(onPressed: () => _editEvm(), icon: const Icon(Icons.add_chart_rounded), label: const Text('EVM')),
            2 => FloatingActionButton.extended(onPressed: () => _editPriority(), icon: const Icon(Icons.low_priority_rounded), label: const Text('Priority')),
            3 => FloatingActionButton.extended(onPressed: () => _editBenefit(), icon: const Icon(Icons.add_task_rounded), label: const Text('Benefit')),
            _ => const SizedBox.shrink(),
          },
        ),
      );

  Widget _scenarioTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
        _Hero(title: 'What-if Analysis', subtitle: 'اثر تغییر بودجه، زمان، ظرفیت و ریسک را قبل از تصمیم‌گیری مقایسه کن.', icon: Icons.tune_rounded),
        const SizedBox(height: 14),
        if (scenarios.isEmpty) const _Empty(text: 'سناریویی ثبت نشده.'),
        ...scenarios.map((s) {
          final score = 100 + s.capacityDelta - s.riskDelta - (s.scheduleDeltaDays > 0 ? s.scheduleDeltaDays * .8 : 0) - (s.budgetDelta > 0 ? s.budgetDelta * .15 : 0);
          return Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: () => _editScenario(s), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), _Pill(text: '${score.clamp(0, 140).round()} Score')]),
            if (s.project.isNotEmpty) Text(s.project, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [_Pill(text: 'Budget ${_signed(s.budgetDelta)}٪'), _Pill(text: 'Schedule ${_signedInt(s.scheduleDeltaDays)}d'), _Pill(text: 'Capacity ${_signed(s.capacityDelta)}٪'), _Pill(text: 'Risk ${_signed(s.riskDelta)}')]),
            if (s.note.isNotEmpty) ...[const SizedBox(height: 10), Text(s.note)],
          ]))));
        }),
      ]);

  Widget _evmTab() {
    final latest = <String, EvmEntry>{};
    for (final e in evm) { latest.putIfAbsent(e.project, () => e); }
    final avgCpi = latest.isEmpty ? 0.0 : latest.values.fold<double>(0, (s, e) => s + e.cpi) / latest.length;
    final avgSpi = latest.isEmpty ? 0.0 : latest.values.fold<double>(0, (s, e) => s + e.spi) / latest.length;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      Row(children: [Expanded(child: _Metric(label: 'CPI میانگین', value: avgCpi == 0 ? '—' : avgCpi.toStringAsFixed(2), icon: Icons.payments_outlined)), const SizedBox(width: 8), Expanded(child: _Metric(label: 'SPI میانگین', value: avgSpi == 0 ? '—' : avgSpi.toStringAsFixed(2), icon: Icons.schedule_rounded))]),
      const SizedBox(height: 14),
      if (latest.isEmpty) const _Empty(text: 'داده EVM ثبت نشده.'),
      ...latest.values.map((e) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: () => _editEvm(e), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(e.project, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), Text(PersianDate.short(e.statusDate), style: Theme.of(context).textTheme.bodySmall)]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [_Pill(text: 'PV ${_money(e.pv)}'), _Pill(text: 'EV ${_money(e.ev)}'), _Pill(text: 'AC ${_money(e.ac)}'), _Pill(text: 'BAC ${_money(e.bac)}')]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _Index(label: 'CPI', value: e.cpi)), const SizedBox(width: 8), Expanded(child: _Index(label: 'SPI', value: e.spi))]),
        const SizedBox(height: 8),
        Text('CV ${_money(e.cv)} • SV ${_money(e.sv)} • EAC ${_money(e.eac)}', style: Theme.of(context).textTheme.bodySmall),
      ]))))),
    ]);
  }

  Widget _priorityTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
        _Hero(title: 'Portfolio Prioritization', subtitle: 'ترکیب Strategy، Value، Risk، Effort و الزام برای مرتب‌سازی پروژه‌ها.', icon: Icons.filter_list_rounded),
        const SizedBox(height: 14),
        if (priorities.isEmpty) const _Empty(text: 'اولویت پروژه‌ای ثبت نشده.'),
        ...priorities.asMap().entries.map((entry) {
          final p = entry.value;
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(onTap: () => _editPriority(p), leading: CircleAvatar(child: Text('${entry.key + 1}')), title: Text(p.project, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Strategy ${p.strategy.toStringAsFixed(1)} • Value ${p.valueScore.toStringAsFixed(1)} • Risk ${p.riskScore.toStringAsFixed(1)} • Effort ${p.effortScore.toStringAsFixed(1)}${p.mandatory ? ' • Mandatory' : ''}'), trailing: Text(p.score.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))));
        }),
      ]);

  Widget _benefitTab() {
    final realized = benefits.where((e) => e.status == 'realized' || e.progress >= 1).length;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 110), children: [
      Row(children: [Expanded(child: _Metric(label: 'کل Benefit', value: '${benefits.length}', icon: Icons.workspace_premium_outlined)), const SizedBox(width: 8), Expanded(child: _Metric(label: 'تحقق‌یافته', value: '$realized', icon: Icons.verified_outlined))]),
      const SizedBox(height: 14),
      if (benefits.isEmpty) const _Empty(text: 'Benefit ثبت نشده.'),
      ...benefits.map((b) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(onTap: () => _editBenefit(b), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(b.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), Text('${(b.progress * 100).round()}٪', style: const TextStyle(fontWeight: FontWeight.w900))]),
        Text('${b.project}${b.owner.isEmpty ? '' : ' • ${b.owner}'}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10), LinearProgressIndicator(value: b.progress, minHeight: 8), const SizedBox(height: 8),
        Text('${b.current.toStringAsFixed(1)} / ${b.target.toStringAsFixed(1)} ${b.unit}${b.dueDate == null ? '' : ' • ${PersianDate.short(b.dueDate!)}'}'),
      ]))))),
    ]);
  }

  Widget _reportTab() => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
        FilledButton.icon(onPressed: () async { await repo.generateExecutiveReport(); await _load(); }, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('ساخت Executive Report')),
        const SizedBox(height: 14),
        if (reports.isEmpty) const _Empty(text: 'هنوز گزارش Executive ساخته نشده.'),
        ...reports.map((r) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), IconButton(tooltip: 'کپی خروجی', onPressed: () async { await Clipboard.setData(ClipboardData(text: '${r.title}\n\n${r.body}')); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('گزارش کپی شد'))); }, icon: const Icon(Icons.copy_all_outlined))]),
          Text(PersianDate.short(r.createdAt), style: Theme.of(context).textTheme.bodySmall), const Divider(height: 22), SelectableText(r.body),
        ])))),
      ]);

  Future<void> _editScenario([ScenarioPlan? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final budget = TextEditingController(text: '${current?.budgetDelta ?? 0}');
    final schedule = TextEditingController(text: '${current?.scheduleDeltaDays ?? 0}');
    final capacity = TextEditingController(text: '${current?.capacityDelta ?? 0}');
    final risk = TextEditingController(text: '${current?.riskDelta ?? 0}');
    final note = TextEditingController(text: current?.note ?? '');
    final saved = await showModalBottomSheet<ScenarioPlan>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => _Sheet(children: [
      Text(current == null ? 'Scenario جدید' : 'ویرایش Scenario', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'نام سناریو')), const SizedBox(height: 10), TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: budget, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget Δ %'))), const SizedBox(width: 8), Expanded(child: TextField(controller: schedule, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Schedule Δ days')))]), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity Δ %'))), const SizedBox(width: 8), Expanded(child: TextField(controller: risk, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Risk Δ')))]), const SizedBox(height: 10), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت')), const SizedBox(height: 16),
      FilledButton(onPressed: () { if (title.text.trim().isEmpty) return; Navigator.pop(context, ScenarioPlan(id: current?.id, title: title.text.trim(), project: project.text.trim(), budgetDelta: double.tryParse(budget.text) ?? 0, scheduleDeltaDays: int.tryParse(schedule.text) ?? 0, capacityDelta: double.tryParse(capacity.text) ?? 0, riskDelta: double.tryParse(risk.text) ?? 0, note: note.text.trim(), createdAt: current?.createdAt ?? DateTime.now())); }, child: const Text('ذخیره')),
      if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteScenario(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
    ]));
    if (saved != null) await repo.saveScenario(saved);
    await _load();
  }

  Future<void> _editEvm([EvmEntry? current]) async {
    final project = TextEditingController(text: current?.project ?? ''); final pv = TextEditingController(text: '${current?.pv ?? 0}'); final ev = TextEditingController(text: '${current?.ev ?? 0}'); final ac = TextEditingController(text: '${current?.ac ?? 0}'); final bac = TextEditingController(text: '${current?.bac ?? 0}'); var date = current?.statusDate ?? DateTime.now();
    final saved = await showModalBottomSheet<EvmEntry>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) => _Sheet(children: [
      Text('Earned Value', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14), TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: pv, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PV'))), const SizedBox(width: 8), Expanded(child: TextField(controller: ev, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'EV')))]), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: ac, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'AC'))), const SizedBox(width: 8), Expanded(child: TextField(controller: bac, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'BAC')))]), const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime(2045)); if (d != null) setSheetState(() => date = d); }, icon: const Icon(Icons.calendar_month_outlined), label: Text(PersianDate.short(date))), const SizedBox(height: 16),
      FilledButton(onPressed: () { if (project.text.trim().isEmpty) return; Navigator.pop(context, EvmEntry(project: project.text.trim(), pv: double.tryParse(pv.text) ?? 0, ev: double.tryParse(ev.text) ?? 0, ac: double.tryParse(ac.text) ?? 0, bac: double.tryParse(bac.text) ?? 0, statusDate: date)); }, child: const Text('ذخیره')),
      if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteEvm(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
    ])));
    if (saved != null) await repo.saveEvm(saved); await _load();
  }

  Future<void> _editPriority([PortfolioPriority? current]) async {
    final project = TextEditingController(text: current?.project ?? ''); final strategy = TextEditingController(text: '${current?.strategy ?? 5}'); final value = TextEditingController(text: '${current?.valueScore ?? 5}'); final risk = TextEditingController(text: '${current?.riskScore ?? 5}'); final effort = TextEditingController(text: '${current?.effortScore ?? 5}'); final note = TextEditingController(text: current?.note ?? ''); var mandatory = current?.mandatory ?? false;
    final saved = await showModalBottomSheet<PortfolioPriority>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) => _Sheet(children: [
      Text('Portfolio Priority', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14), TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: strategy, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Strategy 0-10'))), const SizedBox(width: 8), Expanded(child: TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value 0-10')))]), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: risk, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Risk 0-10'))), const SizedBox(width: 8), Expanded(child: TextField(controller: effort, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Effort 0-10')))]),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: mandatory, onChanged: (v) => setSheetState(() => mandatory = v), title: const Text('Mandatory / الزامی')), TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'یادداشت')), const SizedBox(height: 16),
      FilledButton(onPressed: () { if (project.text.trim().isEmpty) return; Navigator.pop(context, PortfolioPriority(id: current?.id, project: project.text.trim(), strategy: (double.tryParse(strategy.text) ?? 0).clamp(0, 10), valueScore: (double.tryParse(value.text) ?? 0).clamp(0, 10), riskScore: (double.tryParse(risk.text) ?? 0).clamp(0, 10), effortScore: (double.tryParse(effort.text) ?? 0).clamp(0, 10), mandatory: mandatory, note: note.text.trim())); }, child: const Text('ذخیره')),
      if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deletePriority(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
    ])));
    if (saved != null) await repo.savePriority(saved); await _load();
  }

  Future<void> _editBenefit([BenefitItem? current]) async {
    final project = TextEditingController(text: current?.project ?? ''); final title = TextEditingController(text: current?.title ?? ''); final owner = TextEditingController(text: current?.owner ?? ''); final target = TextEditingController(text: '${current?.target ?? 100}'); final currentValue = TextEditingController(text: '${current?.current ?? 0}'); final unit = TextEditingController(text: current?.unit ?? '%'); var due = current?.dueDate; var status = current?.status ?? 'active';
    final saved = await showModalBottomSheet<BenefitItem>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) => _Sheet(children: [
      Text('Benefit Tracking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 14), TextField(controller: title, decoration: const InputDecoration(labelText: 'Benefit')), const SizedBox(height: 10), TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')), const SizedBox(height: 10), TextField(controller: owner, decoration: const InputDecoration(labelText: 'مالک Benefit')), const SizedBox(height: 10),
      Row(children: [Expanded(child: TextField(controller: target, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target'))), const SizedBox(width: 8), Expanded(child: TextField(controller: currentValue, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current'))), const SizedBox(width: 8), SizedBox(width: 80, child: TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unit')))]), const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: const [DropdownMenuItem(value: 'active', child: Text('فعال')), DropdownMenuItem(value: 'at_risk', child: Text('At Risk')), DropdownMenuItem(value: 'realized', child: Text('تحقق‌یافته'))], onChanged: (v) => setSheetState(() => status = v ?? 'active')), const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2045)); if (d != null) setSheetState(() => due = d); }, icon: const Icon(Icons.calendar_month_outlined), label: Text(due == null ? 'موعد Benefit' : PersianDate.short(due!))), const SizedBox(height: 16),
      FilledButton(onPressed: () { if (title.text.trim().isEmpty || project.text.trim().isEmpty) return; Navigator.pop(context, BenefitItem(id: current?.id, project: project.text.trim(), title: title.text.trim(), owner: owner.text.trim(), target: double.tryParse(target.text) ?? 0, current: double.tryParse(currentValue.text) ?? 0, unit: unit.text.trim().isEmpty ? '%' : unit.text.trim(), dueDate: due, status: status, createdAt: current?.createdAt ?? DateTime.now())); }, child: const Text('ذخیره')),
      if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteBenefit(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
    ])));
    if (saved != null) await repo.saveBenefit(saved); await _load();
  }

  static String _signed(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}';
  static String _signedInt(int v) => '${v >= 0 ? '+' : ''}$v';
  static String _money(double v) { if (v.abs() >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B'; if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M'; if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K'; return v.toStringAsFixed(0); }
}

class _Sheet extends StatelessWidget { final List<Widget> children; const _Sheet({required this.children}); @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))); }
class _Hero extends StatelessWidget { final String title; final String subtitle; final IconData icon; const _Hero({required this.title, required this.subtitle, required this.icon}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(28)), child: Row(children: [CircleAvatar(radius: 24, child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 4), Text(subtitle)]))])); }
class _Metric extends StatelessWidget { final String label; final String value; final IconData icon; const _Metric({required this.label, required this.value, required this.icon}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)])); }
class _Index extends StatelessWidget { final String label; final double value; const _Index({required this.label, required this.value}); @override Widget build(BuildContext context) { final ok = value >= 1; return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)), child: Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Icon(ok ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 18), const SizedBox(width: 4), Text(value == 0 ? '—' : value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w900))])); } }
class _Pill extends StatelessWidget { final String text; const _Pill({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)), child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800))); }
class _Empty extends StatelessWidget { final String text; const _Empty({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)), child: Text(text, textAlign: TextAlign.center)); }
