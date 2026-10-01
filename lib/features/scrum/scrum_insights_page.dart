import 'package:flutter/material.dart';

import '../../core/date/persian_date.dart';
import '../../data/scrum_repository.dart';
import '../../data/sprint_repository.dart';
import '../../models/sprint_item.dart';

class ScrumInsightsPage extends StatefulWidget {
  const ScrumInsightsPage({super.key});

  @override
  State<ScrumInsightsPage> createState() => _ScrumInsightsPageState();
}

class _ScrumInsightsPageState extends State<ScrumInsightsPage> {
  final scrum = ScrumRepository();
  final sprintsRepo = SprintRepository();
  List<SprintItem> sprints = [];
  List<SprintSnapshot> snapshots = [];
  List<DailyScrumEntry> dailies = [];
  List<RetrospectiveEntry> retros = [];
  SprintItem? selected;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await sprintsRepo.all();
    selected = all.where((e) => e.status == SprintStatus.active).firstOrNull ?? (all.isEmpty ? null : all.first);
    sprints = all;
    await _loadSelected();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadSelected() async {
    final id = selected?.id;
    if (id == null) {
      snapshots = [];
      dailies = [];
      retros = [];
      return;
    }
    await scrum.syncSprintPoints(id);
    final data = await Future.wait([scrum.snapshots(id), scrum.dailyEntries(id), scrum.retros(id)]);
    snapshots = data[0] as List<SprintSnapshot>;
    dailies = data[1] as List<DailyScrumEntry>;
    retros = data[2] as List<RetrospectiveEntry>;
  }

  Future<void> _select(int? id) async {
    selected = sprints.where((e) => e.id == id).firstOrNull;
    setState(() => loading = true);
    await _loadSelected();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final completed = sprints.where((e) => e.status == SprintStatus.completed).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Scrum Insights')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selected?.id,
                  decoration: const InputDecoration(labelText: 'اسپرینت'),
                  items: sprints.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))).toList(),
                  onChanged: _select,
                ),
                const SizedBox(height: 14),
                if (selected == null)
                  const _Empty(title: 'هنوز اسپرینتی ندارید', subtitle: 'ابتدا از بخش اسپرینت‌ها یک Sprint بسازید.')
                else ...[
                  Row(children: [
                    Expanded(child: FilledButton.icon(onPressed: _captureSnapshot, icon: const Icon(Icons.camera_alt_outlined), label: const Text('ثبت وضعیت امروز'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: _openDaily, icon: const Icon(Icons.today_outlined), label: const Text('Daily Scrum'))),
                  ]),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: _openRetro, icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Retrospective')),
                  const SizedBox(height: 18),
                  _Panel(
                    title: 'Burndown روزانه',
                    subtitle: snapshots.isEmpty ? 'با «ثبت وضعیت امروز» تاریخچه واقعی شروع می‌شود.' : '${snapshots.length} Snapshot ثبت شده',
                    child: SizedBox(height: 210, child: CustomPaint(painter: _HistoryPainter(snapshots))),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Velocity چند Sprint',
                    subtitle: 'Story Point انجام‌شده در Sprintهای تکمیل‌شده',
                    child: SizedBox(height: 180, child: _VelocityChart(items: completed)),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Daily Scrumهای اخیر',
                    subtitle: '${dailies.length} ثبت',
                    child: dailies.isEmpty
                        ? const Text('هنوز گزارشی ثبت نشده.')
                        : Column(children: dailies.take(5).map((e) => ListTile(contentPadding: EdgeInsets.zero, title: Text(PersianDate.full(e.date)), subtitle: Text('امروز: ${e.today}${e.blockers.isEmpty ? '' : '\nBlocker: ${e.blockers}'}'))).toList()),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Retrospective',
                    subtitle: '${retros.length} جلسه ثبت شده',
                    child: retros.isEmpty
                        ? const Text('هنوز Retrospective ثبت نشده.')
                        : Column(children: retros.take(3).map((e) => ListTile(contentPadding: EdgeInsets.zero, title: Text(PersianDate.full(e.createdAt)), subtitle: Text('✅ ${e.wentWell}\n🔧 ${e.improve}\n🎯 ${e.actions}'))).toList()),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _captureSnapshot() async {
    final id = selected?.id;
    if (id == null) return;
    await scrum.captureToday(id);
    await _loadSelected();
    if (mounted) setState(() {});
  }

  Future<void> _openDaily() async {
    final id = selected?.id;
    if (id == null) return;
    final yesterday = TextEditingController();
    final today = TextEditingController();
    final blockers = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Daily Scrum', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: yesterday, maxLines: 3, decoration: const InputDecoration(labelText: 'دیروز چه کار کردم؟')),
            const SizedBox(height: 10),
            TextField(controller: today, maxLines: 3, decoration: const InputDecoration(labelText: 'امروز چه کار می‌کنم؟')),
            const SizedBox(height: 10),
            TextField(controller: blockers, maxLines: 3, decoration: const InputDecoration(labelText: 'Blocker / مانع')),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت Daily')),
          ]),
        ),
      ),
    );
    if (saved == true) {
      await scrum.saveDaily(DailyScrumEntry(sprintId: id, date: DateTime.now(), yesterday: yesterday.text.trim(), today: today.text.trim(), blockers: blockers.text.trim()));
      await _loadSelected();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openRetro() async {
    final id = selected?.id;
    if (id == null) return;
    final well = TextEditingController();
    final improve = TextEditingController();
    final actions = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Sprint Retrospective', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: well, maxLines: 3, decoration: const InputDecoration(labelText: 'چه چیزهایی خوب بود؟')),
            const SizedBox(height: 10),
            TextField(controller: improve, maxLines: 3, decoration: const InputDecoration(labelText: 'چه چیزی بهتر شود؟')),
            const SizedBox(height: 10),
            TextField(controller: actions, maxLines: 3, decoration: const InputDecoration(labelText: 'Action Itemهای اسپرینت بعد')),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره Retrospective')),
          ]),
        ),
      ),
    );
    if (saved == true) {
      await scrum.saveRetro(RetrospectiveEntry(sprintId: id, wentWell: well.text.trim(), improve: improve.text.trim(), actions: actions.text.trim(), createdAt: DateTime.now()));
      await _loadSelected();
      if (mounted) setState(() {});
    }
  }
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 14), child]),
      );
}

class _Empty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Empty({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)), child: Column(children: [const Icon(Icons.loop_rounded, size: 40), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center)]));
}

class _HistoryPainter extends CustomPainter {
  final List<SprintSnapshot> data;
  _HistoryPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()..color = const Color(0x33000000)..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    if (data.isEmpty) return;
    final maxPoints = data.map((e) => e.totalPoints).fold<int>(1, (a, b) => a > b ? a : b);
    final line = Paint()..color = const Color(0xFF536DFE)..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? 0.0 : size.width * i / (data.length - 1);
      final y = size.height - (data[i].remainingPoints / maxPoints) * (size.height - 12);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, line);
  }
  @override
  bool shouldRepaint(covariant _HistoryPainter oldDelegate) => oldDelegate.data != data;
}

class _VelocityChart extends StatelessWidget {
  final List<SprintItem> items;
  const _VelocityChart({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('داده‌ای برای Velocity وجود ندارد.'));
    final maxValue = items.map((e) => e.completedPoints).fold<int>(1, (a, b) => a > b ? a : b);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: items.take(6).map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${s.completedPoints}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Container(height: 110 * (s.completedPoints / maxValue).clamp(.08, 1), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8))), const SizedBox(height: 6), Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall)])))).toList());
  }
}
