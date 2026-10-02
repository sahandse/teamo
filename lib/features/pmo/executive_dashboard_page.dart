import 'package:flutter/material.dart';

import '../../data/executive_pmo_repository.dart';

class ExecutivePmoPage extends StatefulWidget {
  const ExecutivePmoPage({super.key});

  @override
  State<ExecutivePmoPage> createState() => _ExecutivePmoPageState();
}

class _ExecutivePmoPageState extends State<ExecutivePmoPage> with SingleTickerProviderStateMixin {
  final repo = ExecutivePmoRepository();
  late final TabController tabs;
  List<ResourceAllocation> allocations = [];
  List<ProjectDependency> dependencies = [];
  List<ProjectBudget> budgets = [];
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
    final data = await Future.wait([repo.allocations(), repo.dependencies(), repo.budgets(), repo.executiveProjects()]);
    if (!mounted) return;
    setState(() {
      allocations = data[0] as List<ResourceAllocation>;
      dependencies = data[1] as List<ProjectDependency>;
      budgets = data[2] as List<ProjectBudget>;
      projects = data[3] as List<Map<String, Object?>>;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive PMO'),
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Executive'),
            Tab(text: 'منابع'),
            Tab(text: 'وابستگی‌ها'),
            Tab(text: 'بودجه'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: tabs, children: [_executive(), _resources(), _dependencies(), _budgets()]),
      floatingActionButton: AnimatedBuilder(
        animation: tabs,
        builder: (context, _) {
          return switch (tabs.index) {
            1 => FloatingActionButton.extended(onPressed: () => _editAllocation(), icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('منبع')),
            2 => FloatingActionButton.extended(onPressed: () => _editDependency(), icon: const Icon(Icons.account_tree_outlined), label: const Text('وابستگی')),
            3 => FloatingActionButton.extended(onPressed: () => _editBudget(), icon: const Icon(Icons.account_balance_wallet_outlined), label: const Text('بودجه')),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _executive() {
    final red = projects.where((e) => e['rag'] == 'red').length;
    final amber = projects.where((e) => e['rag'] == 'amber').length;
    final green = projects.where((e) => e['rag'] == 'green').length;
    final totalPlanned = budgets.fold<double>(0, (sum, e) => sum + e.plannedCost);
    final totalActual = budgets.fold<double>(0, (sum, e) => sum + e.actualCost);
    final overAllocated = _memberLoads().where((e) => e.value > 100).length;
    final blockedDeps = dependencies.where((e) => e.status == 'blocked').length;
    final executiveScore = (100 - red * 18 - amber * 7 - overAllocated * 10 - blockedDeps * 8).clamp(0, 100);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Executive Health', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('$executiveScore / 100', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                ])),
                const Icon(Icons.speed_rounded, size: 44),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: executiveScore / 100, minHeight: 10),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Metric(icon: Icons.circle, label: 'سبز', value: '$green')),
            const SizedBox(width: 8),
            Expanded(child: _Metric(icon: Icons.warning_amber_rounded, label: 'زرد', value: '$amber')),
            const SizedBox(width: 8),
            Expanded(child: _Metric(icon: Icons.error_outline_rounded, label: 'قرمز', value: '$red')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Metric(icon: Icons.groups_2_outlined, label: 'Over Allocation', value: '$overAllocated')),
            const SizedBox(width: 8),
            Expanded(child: _Metric(icon: Icons.link_off_rounded, label: 'وابستگی Blocked', value: '$blockedDeps')),
          ]),
          const SizedBox(height: 18),
          _Panel(
            title: 'بودجه Portfolio',
            subtitle: totalPlanned <= 0 ? 'هنوز بودجه‌ای ثبت نشده' : 'مصرف ${(totalActual / totalPlanned * 100).clamp(0, 999).round()}٪ از برنامه',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LinearProgressIndicator(value: totalPlanned <= 0 ? 0 : (totalActual / totalPlanned).clamp(0, 1).toDouble(), minHeight: 9),
              const SizedBox(height: 8),
              Text('برنامه: ${_money(totalPlanned)}   •   واقعی: ${_money(totalActual)}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 14),
          Text('RAG Health پروژه‌ها', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (projects.isEmpty) const _Empty(title: 'پروژه‌ای وجود ندارد', subtitle: 'پروژه‌ها را از بخش پروژه‌های تیمو ایجاد کن.'),
          ...projects.map((p) {
            final rag = '${p['rag'] ?? 'green'}';
            final progress = ((p['progress'] as num?)?.toDouble() ?? 0).clamp(0, 1).toDouble();
            final risk = (p['open_risk_score'] as num?)?.toDouble() ?? 0;
            final deps = (p['dependency_count'] as num?)?.toInt() ?? 0;
            final planned = (p['planned_cost'] as num?)?.toDouble() ?? 0;
            final actual = (p['actual_cost'] as num?)?.toDouble() ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    _RagDot(rag: rag),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${p['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                    Text('${(progress * 100).round()}٪', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 9),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _TinyChip(label: 'Risk ${risk.toStringAsFixed(0)}'),
                    _TinyChip(label: '$deps Dependency'),
                    if (planned > 0) _TinyChip(label: 'Cost ${(actual / planned * 100).clamp(0, 999).round()}٪'),
                  ]),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, double> _memberLoads() {
    final result = <String, double>{};
    for (final item in allocations) {
      result[item.memberName] = (result[item.memberName] ?? 0) + item.allocationPercent;
    }
    return result;
  }

  Widget _resources() {
    final loads = _memberLoads();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        if (allocations.isEmpty) const _Empty(title: 'برنامه منابع خالی است', subtitle: 'اعضای تیم را به پروژه‌ها تخصیص بده و ظرفیت را کنترل کن.'),
        ...loads.entries.map((e) {
          final memberItems = allocations.where((a) => a.memberName == e.key).toList();
          final load = e.value;
          return _Panel(
            title: e.key,
            subtitle: load > 100 ? 'Over Allocated • ${load.toStringAsFixed(0)}٪' : 'Allocation ${load.toStringAsFixed(0)}٪',
            child: Column(children: memberItems.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => _editAllocation(item),
              leading: CircleAvatar(child: Text('${item.allocationPercent.round()}٪')),
              title: Text(item.project.isEmpty ? 'بدون پروژه' : item.project, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${item.role.isEmpty ? 'بدون نقش' : item.role} • ${item.weeklyHours.toStringAsFixed(0)} ساعت/هفته'),
              trailing: const Icon(Icons.chevron_left_rounded),
            )).toList()),
          );
        }).expand((w) => [w, const SizedBox(height: 10)]),
      ],
    );
  }

  Widget _dependencies() {
    final blocked = dependencies.where((e) => e.status == 'blocked').length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(children: [
          Expanded(child: _Metric(icon: Icons.account_tree_outlined, label: 'کل وابستگی', value: '${dependencies.length}')),
          const SizedBox(width: 10),
          Expanded(child: _Metric(icon: Icons.link_off_rounded, label: 'Blocked', value: '$blocked')),
        ]),
        const SizedBox(height: 16),
        if (dependencies.isEmpty) const _Empty(title: 'Dependency Map خالی است', subtitle: 'وابستگی بین پروژه‌ها را ثبت کن تا گلوگاه‌ها دیده شوند.'),
        ...dependencies.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _editDependency(item),
            leading: CircleAvatar(child: Icon(item.status == 'blocked' ? Icons.link_off_rounded : Icons.account_tree_outlined)),
            title: Text(item.project, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('وابسته به: ${item.dependsOn}\n${_dependencyType(item.dependencyType)} • ${_dependencyStatus(item.status)}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_left_rounded),
          ),
        )),
      ],
    );
  }

  Widget _budgets() {
    final planned = budgets.fold<double>(0, (sum, e) => sum + e.plannedCost);
    final actual = budgets.fold<double>(0, (sum, e) => sum + e.actualCost);
    final forecast = budgets.fold<double>(0, (sum, e) => sum + e.forecastCost);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(children: [
          Expanded(child: _Metric(icon: Icons.flag_outlined, label: 'Planned', value: _money(planned))),
          const SizedBox(width: 8),
          Expanded(child: _Metric(icon: Icons.payments_outlined, label: 'Actual', value: _money(actual))),
        ]),
        const SizedBox(height: 8),
        _Metric(icon: Icons.trending_up_rounded, label: 'Forecast', value: _money(forecast)),
        const SizedBox(height: 16),
        if (budgets.isEmpty) const _Empty(title: 'بودجه‌ای ثبت نشده', subtitle: 'هزینه برنامه‌ریزی‌شده، واقعی و Forecast هر پروژه را ثبت کن.'),
        ...budgets.map((item) {
          final ratio = item.plannedCost <= 0 ? 0.0 : (item.actualCost / item.plannedCost).clamp(0, 1).toDouble();
          final over = item.actualCost > item.plannedCost && item.plannedCost > 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _editBudget(item),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(item.project, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                    if (over) const Chip(label: Text('Over Budget')),
                  ]),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: ratio, minHeight: 8),
                  const SizedBox(height: 8),
                  Text('Planned ${_money(item.plannedCost)} • Actual ${_money(item.actualCost)} • Forecast ${_money(item.forecastCost)}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _editAllocation([ResourceAllocation? current]) async {
    final member = TextEditingController(text: current?.memberName ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final role = TextEditingController(text: current?.role ?? '');
    final percent = TextEditingController(text: '${current?.allocationPercent ?? 100}');
    final hours = TextEditingController(text: '${current?.weeklyHours ?? 40}');
    final saved = await showModalBottomSheet<ResourceAllocation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(current == null ? 'تخصیص منبع' : 'ویرایش تخصیص', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: member, decoration: const InputDecoration(labelText: 'نام عضو')),
          const SizedBox(height: 10),
          TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
          const SizedBox(height: 10),
          TextField(controller: role, decoration: const InputDecoration(labelText: 'نقش')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: percent, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Allocation %'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: hours, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ساعت هفتگی'))),
          ]),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {
            if (member.text.trim().isEmpty) return;
            Navigator.pop(context, ResourceAllocation(id: current?.id, memberName: member.text.trim(), project: project.text.trim(), role: role.text.trim(), allocationPercent: double.tryParse(percent.text) ?? 0, weeklyHours: double.tryParse(hours.text) ?? 0, startDate: current?.startDate, endDate: current?.endDate, createdAt: current?.createdAt ?? DateTime.now()));
          }, child: const Text('ذخیره')),
          if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteAllocation(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
        ])),
      ),
    );
    if (saved != null) await repo.saveAllocation(saved);
    await _load();
  }

  Future<void> _editDependency([ProjectDependency? current]) async {
    final project = TextEditingController(text: current?.project ?? '');
    final depends = TextEditingController(text: current?.dependsOn ?? '');
    final note = TextEditingController(text: current?.note ?? '');
    var type = current?.dependencyType ?? 'finish_to_start';
    var status = current?.status ?? 'active';
    final saved = await showModalBottomSheet<ProjectDependency>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(current == null ? 'وابستگی جدید' : 'ویرایش وابستگی', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
          const SizedBox(height: 10),
          TextField(controller: depends, decoration: const InputDecoration(labelText: 'وابسته به پروژه')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'نوع وابستگی'), items: const [
            DropdownMenuItem(value: 'finish_to_start', child: Text('Finish → Start')),
            DropdownMenuItem(value: 'start_to_start', child: Text('Start → Start')),
            DropdownMenuItem(value: 'finish_to_finish', child: Text('Finish → Finish')),
          ], onChanged: (v) => setSheetState(() => type = v ?? 'finish_to_start')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(initialValue: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: const [
            DropdownMenuItem(value: 'active', child: Text('فعال')),
            DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
            DropdownMenuItem(value: 'resolved', child: Text('حل‌شده')),
          ], onChanged: (v) => setSheetState(() => status = v ?? 'active')),
          const SizedBox(height: 10),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {
            if (project.text.trim().isEmpty || depends.text.trim().isEmpty) return;
            Navigator.pop(context, ProjectDependency(id: current?.id, project: project.text.trim(), dependsOn: depends.text.trim(), dependencyType: type, status: status, note: note.text.trim(), createdAt: current?.createdAt ?? DateTime.now()));
          }, child: const Text('ذخیره')),
          if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteDependency(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
        ])),
      )),
    );
    if (saved != null) await repo.saveDependency(saved);
    await _load();
  }

  Future<void> _editBudget([ProjectBudget? current]) async {
    final project = TextEditingController(text: current?.project ?? '');
    final planned = TextEditingController(text: '${current?.plannedCost ?? 0}');
    final actual = TextEditingController(text: '${current?.actualCost ?? 0}');
    final forecast = TextEditingController(text: '${current?.forecastCost ?? 0}');
    final currency = TextEditingController(text: current?.currency ?? 'IRR');
    final saved = await showModalBottomSheet<ProjectBudget>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(current == null ? 'بودجه پروژه' : 'ویرایش بودجه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
          const SizedBox(height: 10),
          TextField(controller: planned, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Planned Cost')),
          const SizedBox(height: 10),
          TextField(controller: actual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Cost')),
          const SizedBox(height: 10),
          TextField(controller: forecast, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Forecast Cost')),
          const SizedBox(height: 10),
          TextField(controller: currency, decoration: const InputDecoration(labelText: 'واحد پول')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () {
            if (project.text.trim().isEmpty) return;
            Navigator.pop(context, ProjectBudget(id: current?.id, project: project.text.trim(), plannedCost: double.tryParse(planned.text) ?? 0, actualCost: double.tryParse(actual.text) ?? 0, forecastCost: double.tryParse(forecast.text) ?? 0, currency: currency.text.trim().isEmpty ? 'IRR' : currency.text.trim(), updatedAt: DateTime.now()));
          }, child: const Text('ذخیره')),
          if (current?.id != null) TextButton.icon(onPressed: () async { await repo.deleteBudget(current!.id!); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف')),
        ])),
      ),
    );
    if (saved != null) await repo.saveBudget(saved);
    await _load();
  }

  static String _dependencyType(String value) => switch (value) {
        'start_to_start' => 'Start → Start',
        'finish_to_finish' => 'Finish → Finish',
        _ => 'Finish → Start',
      };

  static String _dependencyStatus(String value) => switch (value) {
        'blocked' => 'Blocked',
        'resolved' => 'حل‌شده',
        _ => 'فعال',
      };

  static String _money(double value) {
    if (value.abs() >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Panel({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ]),
      );
}

class _RagDot extends StatelessWidget {
  final String rag;
  const _RagDot({required this.rag});

  @override
  Widget build(BuildContext context) {
    final color = switch (rag) {
      'red' => Colors.red,
      'amber' => Colors.amber,
      _ => Colors.green,
    };
    return Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class _TinyChip extends StatelessWidget {
  final String label;
  const _TinyChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          const Icon(Icons.dashboard_outlined, size: 42),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ]),
      );
}
