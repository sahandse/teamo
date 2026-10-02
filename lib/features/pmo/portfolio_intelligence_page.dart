import 'package:flutter/material.dart';

import '../../core/date/persian_date.dart';
import '../../data/portfolio_intelligence_repository.dart';

class PortfolioIntelligencePage extends StatefulWidget {
  const PortfolioIntelligencePage({super.key});

  @override
  State<PortfolioIntelligencePage> createState() => _PortfolioIntelligencePageState();
}

class _PortfolioIntelligencePageState extends State<PortfolioIntelligencePage> with SingleTickerProviderStateMixin {
  final repo = PortfolioIntelligenceRepository();
  late final TabController tabs;
  List<ProjectBaseline> baselines = [];
  List<CostSnapshot> costs = [];
  List<Map<String, Object?>> capacity = [];
  List<Map<String, Object?>> timeline = [];
  List<Map<String, Object?>> critical = [];
  List<ExecutiveDigest> digests = [];
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
    final data = await Future.wait([repo.baselines(), repo.costSnapshots(), repo.capacityForecast(), repo.timeline(), repo.criticalPath(), repo.digests()]);
    if (!mounted) return;
    setState(() {
      baselines = data[0] as List<ProjectBaseline>;
      costs = data[1] as List<CostSnapshot>;
      capacity = data[2] as List<Map<String, Object?>>;
      timeline = data[3] as List<Map<String, Object?>>;
      critical = data[4] as List<Map<String, Object?>>;
      digests = data[5] as List<ExecutiveDigest>;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Intelligence'),
        bottom: TabBar(controller: tabs, isScrollable: true, tabs: const [
          Tab(text: 'Forecast'),
          Tab(text: 'Timeline'),
          Tab(text: 'Cost Trend'),
          Tab(text: 'Baseline'),
          Tab(text: 'Digest'),
        ]),
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : TabBarView(controller: tabs, children: [_forecast(), _timeline(), _costTrend(), _baseline(), _digest()]),
    );
  }

  Widget _forecast() {
    final overloaded = capacity.where((e) => ((e['allocation'] as num?)?.toDouble() ?? 0) > 100).length;
    final avgLoad = capacity.isEmpty ? 0.0 : capacity.fold<double>(0, (s, e) => s + ((e['allocation'] as num?)?.toDouble() ?? 0)) / capacity.length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: _Metric(icon: Icons.groups_2_outlined, label: 'اعضا', value: '${capacity.length}')),
        const SizedBox(width: 8),
        Expanded(child: _Metric(icon: Icons.warning_amber_rounded, label: 'Over Allocated', value: '$overloaded')),
        const SizedBox(width: 8),
        Expanded(child: _Metric(icon: Icons.speed_rounded, label: 'میانگین Load', value: '${avgLoad.round()}٪')),
      ]),
      const SizedBox(height: 18),
      Text('Capacity Forecast', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (capacity.isEmpty) const _Empty(text: 'هنوز تخصیص منبعی ثبت نشده.'),
      ...capacity.map((e) {
        final load = (e['allocation'] as num?)?.toDouble() ?? 0;
        final hours = (e['weekly_hours'] as num?)?.toDouble() ?? 0;
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text('${load.round()}٪')),
          title: Text('${e['member_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${e['projects'] ?? 0} پروژه • ${hours.toStringAsFixed(0)} ساعت/هفته'),
          trailing: Icon(load > 100 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
        ));
      }),
      const SizedBox(height: 18),
      Text('Critical Path', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (critical.isEmpty) const _Empty(text: 'وابستگی فعالی برای محاسبه مسیر بحرانی وجود ندارد.'),
      ...critical.take(8).map((e) => Card(child: ListTile(
        leading: CircleAvatar(child: Text('${e['criticality'] ?? 0}')),
        title: Text('${e['project'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(e['due_date'] == null ? 'بدون موعد' : 'موعد ${PersianDate.short(DateTime.parse('${e['due_date']}'))}'),
      ))),
    ]);
  }

  Widget _timeline() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Portfolio Timeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (timeline.isEmpty) const _Empty(text: 'پروژه‌ای برای Timeline وجود ندارد.'),
          ...timeline.map((e) {
            final progress = ((e['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble();
            final due = e['due_date'] == null ? null : DateTime.tryParse('${e['due_date']}');
            final baseline = e['baseline_finish'] == null ? null : DateTime.tryParse('${e['baseline_finish']}');
            final slip = due != null && baseline != null ? due.difference(baseline).inDays : 0;
            return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${e['project'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900))), Text('${(progress * 100).round()}٪')]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 8),
              const SizedBox(height: 8),
              Text(due == null ? 'موعد ثبت نشده' : 'موعد فعلی: ${PersianDate.short(due)}'),
              if (baseline != null) Text('Baseline: ${PersianDate.short(baseline)}${slip > 0 ? ' • $slip روز تأخیر' : slip < 0 ? ' • ${slip.abs()} روز جلوتر' : ''}'),
            ])));
          }),
        ],
      );

  Widget _costTrend() {
    final grouped = <String, List<CostSnapshot>>{};
    for (final c in costs) grouped.putIfAbsent(c.project, () => []).add(c);
    return ListView(padding: const EdgeInsets.all(16), children: [
      FilledButton.icon(onPressed: () async { await repo.captureCostToday(); await _load(); }, icon: const Icon(Icons.add_chart_rounded), label: const Text('ثبت Snapshot امروز')),
      const SizedBox(height: 14),
      if (grouped.isEmpty) const _Empty(text: 'هنوز Snapshot هزینه‌ای ثبت نشده.'),
      ...grouped.entries.map((entry) {
        final list = entry.value..sort((a, b) => a.date.compareTo(b.date));
        final latest = list.last;
        final first = list.first;
        final delta = latest.actual - first.actual;
        return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.trending_up_rounded)),
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${list.length} Snapshot • Actual ${_money(latest.actual)} • Forecast ${_money(latest.forecast)}'),
          trailing: Text(delta == 0 ? '—' : '${delta > 0 ? '+' : ''}${_money(delta)}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ));
      }),
    ]);
  }

  Widget _baseline() => ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(onPressed: () => _editBaseline(), icon: const Icon(Icons.add_rounded), label: const Text('Baseline جدید')),
        const SizedBox(height: 14),
        if (baselines.isEmpty) const _Empty(text: 'Baseline پروژه‌ها هنوز ثبت نشده.'),
        ...baselines.map((b) => Card(child: ListTile(
          onTap: () => _editBaseline(b),
          leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
          title: Text(b.project, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('Progress ${(b.baselineProgress * 100).round()}٪ • Cost ${_money(b.baselineCost)}${b.baselineFinish == null ? '' : ' • ${PersianDate.short(b.baselineFinish!)}'}'),
          trailing: const Icon(Icons.chevron_left_rounded),
        ))),
      ]);

  Widget _digest() => ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(onPressed: () async { await repo.generateDigest(); await _load(); }, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('ساخت Executive Weekly Digest')),
        const SizedBox(height: 14),
        if (digests.isEmpty) const _Empty(text: 'هنوز گزارشی ساخته نشده.'),
        ...digests.map((d) => Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text(PersianDate.short(d.createdAt), style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 24),
          Text('خلاصه', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)), Text(d.summary),
          const SizedBox(height: 8),
          Text('Highlights', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)), Text(d.highlights),
          const SizedBox(height: 8),
          Text('نیازمند توجه', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)), Text(d.attention),
          const SizedBox(height: 8),
          Text('اقدام بعدی', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)), Text(d.nextActions),
        ])))),
      ]);

  Future<void> _editBaseline([ProjectBaseline? current]) async {
    final project = TextEditingController(text: current?.project ?? '');
    final progress = TextEditingController(text: '${((current?.baselineProgress ?? 0) * 100).round()}');
    final cost = TextEditingController(text: '${current?.baselineCost ?? 0}');
    var finish = current?.baselineFinish;
    final saved = await showModalBottomSheet<ProjectBaseline>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(current == null ? 'Baseline جدید' : 'ویرایش Baseline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
        const SizedBox(height: 10),
        TextField(controller: progress, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Baseline Progress %')),
        const SizedBox(height: 10),
        TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Baseline Cost')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: finish ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2045)); if (d != null) setSheetState(() => finish = d); }, icon: const Icon(Icons.calendar_month_outlined), label: Text(finish == null ? 'Baseline Finish' : PersianDate.short(finish!))),
        const SizedBox(height: 16),
        FilledButton(onPressed: () { if (project.text.trim().isEmpty) return; Navigator.pop(context, ProjectBaseline(id: current?.id, project: project.text.trim(), baselineProgress: ((double.tryParse(progress.text) ?? 0) / 100).clamp(0, 1), baselineFinish: finish, baselineCost: double.tryParse(cost.text) ?? 0, createdAt: current?.createdAt ?? DateTime.now())); }, child: const Text('ذخیره')),
      ])),
    )));
    if (saved != null) await repo.saveBaseline(saved);
    await _load();
  }

  static String _money(double value) {
    if (value.abs() >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _Metric extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _Metric({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)]));
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)), child: Text(text, textAlign: TextAlign.center));
}
