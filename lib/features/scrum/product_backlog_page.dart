import 'package:flutter/material.dart';

import '../../data/sprint_repository.dart';
import '../../data/work_item_repository.dart';
import '../../models/sprint_item.dart';
import '../../models/work_item.dart';

class ProductBacklogPage extends StatefulWidget {
  final SprintItem? initialSprint;
  const ProductBacklogPage({super.key, this.initialSprint});

  @override
  State<ProductBacklogPage> createState() => _ProductBacklogPageState();
}

class _ProductBacklogPageState extends State<ProductBacklogPage> with SingleTickerProviderStateMixin {
  final _repo = WorkItemRepository();
  final _sprintRepo = SprintRepository();
  late final TabController _tabs;
  List<WorkItem> items = [];
  List<SprintItem> sprints = [];
  SprintItem? selectedSprint;
  WorkItemType? typeFilter;
  String query = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    selectedSprint = widget.initialSprint;
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([_repo.all(), _sprintRepo.all()]);
    if (!mounted) return;
    setState(() {
      items = results[0] as List<WorkItem>;
      sprints = results[1] as List<SprintItem>;
      selectedSprint ??= sprints.where((e) => e.status == SprintStatus.active).firstOrNull;
      loading = false;
    });
  }

  List<WorkItem> get backlogItems => items.where((e) {
        final noSprint = e.sprintId == null;
        final typeOk = typeFilter == null || e.type == typeFilter;
        final queryOk = query.trim().isEmpty || e.title.toLowerCase().contains(query.trim().toLowerCase()) || e.project.toLowerCase().contains(query.trim().toLowerCase());
        return noSprint && typeOk && queryOk;
      }).toList();

  List<WorkItem> get sprintItems => selectedSprint == null ? [] : items.where((e) => e.sprintId == selectedSprint!.id).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Backlog'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'بک‌لاگ'), Tab(text: 'Sprint Backlog'), Tab(text: 'تحلیل')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('آیتم'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_buildProductBacklog(), _buildSprintBacklog(), _buildAnalytics()],
            ),
    );
  }

  Widget _buildProductBacklog() {
    final points = backlogItems.fold<int>(0, (sum, e) => sum + e.storyPoints);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Row(children: [
          Expanded(child: _Metric(label: 'آیتم‌های بک‌لاگ', value: '${backlogItems.length}', icon: Icons.inventory_2_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _Metric(label: 'Story Point', value: '$points', icon: Icons.bolt_rounded)),
        ]),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'جستجو در عنوان یا پروژه'),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(label: const Text('همه'), selected: typeFilter == null, onSelected: (_) => setState(() => typeFilter = null)),
              const SizedBox(width: 8),
              ...WorkItemType.values.expand((type) => [
                    ChoiceChip(label: Text(_typeLabel(type)), selected: typeFilter == type, onSelected: (_) => setState(() => typeFilter = type)),
                    const SizedBox(width: 8),
                  ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (backlogItems.isEmpty) const _EmptyState(icon: Icons.inventory_2_outlined, title: 'بک‌لاگ خالی است', subtitle: 'Epic، Story، Task یا Bug جدید بساز.'),
        ...backlogItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WorkCard(
                item: item,
                onTap: () => _editItem(item),
                action: PopupMenuButton<String>(
                  tooltip: 'انتقال',
                  onSelected: (value) {
                    final id = int.tryParse(value);
                    final sprint = sprints.where((e) => e.id == id).firstOrNull;
                    if (sprint != null) _moveToSprint(item, sprint);
                  },
                  itemBuilder: (_) => sprints.where((e) => e.status != SprintStatus.completed).map((s) => PopupMenuItem(value: '${s.id}', child: Text('انتقال به ${s.title}'))).toList(),
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSprintBacklog() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: DropdownButtonFormField<int>(
          value: selectedSprint?.id,
          decoration: const InputDecoration(labelText: 'اسپرینت'),
          items: sprints.map((s) => DropdownMenuItem(value: s.id, child: Text(s.title))).toList(),
          onChanged: (id) => setState(() => selectedSprint = sprints.where((e) => e.id == id).firstOrNull),
        ),
      ),
      Expanded(
        child: selectedSprint == null
            ? const _EmptyState(icon: Icons.loop_rounded, title: 'اسپرینتی انتخاب نشده', subtitle: 'ابتدا یک Sprint بساز یا انتخاب کن.')
            : _SprintBoard(items: sprintItems, onChanged: _changeStatus, onEdit: _editItem, onRemove: _removeFromSprint),
      ),
    ]);
  }

  Widget _buildAnalytics() {
    final sprint = selectedSprint;
    if (sprint == null) return const _EmptyState(icon: Icons.insights_rounded, title: 'برای تحلیل یک Sprint انتخاب کن', subtitle: 'Burndown و Velocity بر اساس Story Point نمایش داده می‌شوند.');
    final total = sprintItems.fold<int>(0, (sum, e) => sum + e.storyPoints);
    final done = sprintItems.where((e) => e.status == WorkItemStatus.done).fold<int>(0, (sum, e) => sum + e.storyPoints);
    final remaining = (total - done).clamp(0, total);
    final velocity = sprints.where((e) => e.status == SprintStatus.completed).map((e) => e.completedPoints).toList();
    final maxV = velocity.isEmpty ? 1 : velocity.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        Text(sprint.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        if (sprint.goal.isNotEmpty) ...[const SizedBox(height: 4), Text(sprint.goal, style: Theme.of(context).textTheme.bodySmall)],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Metric(label: 'کل SP', value: '$total', icon: Icons.bolt_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _Metric(label: 'باقی‌مانده', value: '$remaining', icon: Icons.timelapse_rounded)),
        ]),
        const SizedBox(height: 18),
        _Panel(
          title: 'Burndown',
          subtitle: 'خط ایده‌آل در برابر باقی‌مانده فعلی',
          child: SizedBox(height: 190, child: CustomPaint(painter: _BurndownPainter(total: total.toDouble(), remaining: remaining.toDouble()))),
        ),
        const SizedBox(height: 14),
        _Panel(
          title: 'Velocity',
          subtitle: velocity.isEmpty ? 'پس از تکمیل Sprintها داده نمایش داده می‌شود.' : 'Story Point انجام‌شده در Sprintهای تکمیل‌شده',
          child: SizedBox(
            height: 150,
            child: velocity.isEmpty
                ? const Center(child: Text('هنوز Sprint تکمیل‌شده‌ای نداریم'))
                : Row(crossAxisAlignment: CrossAxisAlignment.end, children: velocity.asMap().entries.map((entry) {
                    final h = 100 * (entry.value / maxV);
                    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 5), Container(height: h.clamp(6, 100), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)))), const SizedBox(height: 5), Text('S${entry.key + 1}', style: Theme.of(context).textTheme.labelSmall)])));
                  }).toList()),
          ),
        ),
      ],
    );
  }

  Future<void> _moveToSprint(WorkItem item, SprintItem sprint) async {
    final updated = item.copyWith(sprintId: sprint.id, status: WorkItemStatus.ready);
    await _repo.update(updated);
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('به ${sprint.title} منتقل شد')));
  }

  Future<void> _removeFromSprint(WorkItem item) async {
    if (item.id == null) return;
    final dbItem = WorkItem(id: item.id, title: item.title, project: item.project, sprintId: null, type: item.type, status: WorkItemStatus.backlog, storyPoints: item.storyPoints, assignee: item.assignee, description: item.description, createdAt: item.createdAt);
    await _repo.update(dbItem);
    await _load();
  }

  Future<void> _changeStatus(WorkItem item, WorkItemStatus status) async {
    await _repo.update(item.copyWith(status: status));
    await _load();
  }

  Future<void> _editItem([WorkItem? current]) async {
    final title = TextEditingController(text: current?.title ?? '');
    final project = TextEditingController(text: current?.project ?? '');
    final assignee = TextEditingController(text: current?.assignee ?? '');
    final description = TextEditingController(text: current?.description ?? '');
    final points = TextEditingController(text: '${current?.storyPoints ?? 0}');
    var type = current?.type ?? WorkItemType.story;
    var status = current?.status ?? WorkItemStatus.backlog;
    var sprintId = current?.sprintId;

    final result = await showModalBottomSheet<WorkItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(current == null ? 'آیتم جدید' : 'ویرایش آیتم', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<WorkItemType>(value: type, decoration: const InputDecoration(labelText: 'نوع'), items: WorkItemType.values.map((e) => DropdownMenuItem(value: e, child: Text(_typeLabel(e)))).toList(), onChanged: (v) => setSheetState(() => type = v ?? type))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Story Point'))),
                ]),
                const SizedBox(height: 10),
                TextField(controller: project, decoration: const InputDecoration(labelText: 'پروژه')),
                const SizedBox(height: 10),
                TextField(controller: assignee, decoration: const InputDecoration(labelText: 'مسئول')),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(value: sprintId, decoration: const InputDecoration(labelText: 'Sprint'), items: [const DropdownMenuItem<int?>(value: null, child: Text('Product Backlog')), ...sprints.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.title)))], onChanged: (v) => setSheetState(() => sprintId = v)),
                const SizedBox(height: 10),
                DropdownButtonFormField<WorkItemStatus>(value: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: WorkItemStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_statusLabel(e)))).toList(), onChanged: (v) => setSheetState(() => status = v ?? status)),
                const SizedBox(height: 10),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'توضیحات / Acceptance Criteria')),
                const SizedBox(height: 16),
                FilledButton(onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  Navigator.pop(context, WorkItem(id: current?.id, title: title.text.trim(), project: project.text.trim(), sprintId: sprintId, type: type, status: status, storyPoints: int.tryParse(points.text) ?? 0, assignee: assignee.text.trim(), description: description.text.trim(), createdAt: current?.createdAt ?? DateTime.now()));
                }, child: const Text('ذخیره')),
                if (current?.id != null) TextButton.icon(onPressed: () async { await _repo.delete(current!.id!); if (context.mounted) Navigator.pop(context); await _load(); }, icon: const Icon(Icons.delete_outline_rounded), label: const Text('حذف آیتم')),
              ]),
            ),
          )),
    );
    if (result == null) return;
    if (current == null) {
      await _repo.create(result);
    } else {
      await _repo.update(result);
    }
    await _load();
  }

  static String _typeLabel(WorkItemType type) => switch (type) { WorkItemType.epic => 'Epic', WorkItemType.story => 'Story', WorkItemType.task => 'Task', WorkItemType.bug => 'Bug' };
  static String _statusLabel(WorkItemStatus status) => switch (status) { WorkItemStatus.backlog => 'Backlog', WorkItemStatus.ready => 'Ready', WorkItemStatus.doing => 'Doing', WorkItemStatus.review => 'Review', WorkItemStatus.done => 'Done' };
}

class _SprintBoard extends StatelessWidget {
  final List<WorkItem> items;
  final Future<void> Function(WorkItem, WorkItemStatus) onChanged;
  final void Function(WorkItem) onEdit;
  final Future<void> Function(WorkItem) onRemove;
  const _SprintBoard({required this.items, required this.onChanged, required this.onEdit, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    const statuses = [WorkItemStatus.ready, WorkItemStatus.doing, WorkItemStatus.review, WorkItemStatus.done];
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: statuses.map((status) {
        final list = items.where((e) => e.status == status).toList();
        return DragTarget<WorkItem>(
          onAcceptWithDetails: (details) => onChanged(details.data, status),
          builder: (context, candidate, rejected) => Container(
            width: 285,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22), border: candidate.isNotEmpty ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null),
            child: ListView(children: [
              Row(children: [Text(_ProductBacklogPageState._statusLabel(status), style: const TextStyle(fontWeight: FontWeight.w900)), const Spacer(), CircleAvatar(radius: 13, child: Text('${list.length}', style: const TextStyle(fontSize: 11)))]),
              const SizedBox(height: 10),
              ...list.map((item) => LongPressDraggable<WorkItem>(data: item, feedback: Material(color: Colors.transparent, child: SizedBox(width: 260, child: _WorkCard(item: item, onTap: () {}, action: const SizedBox.shrink()))), childWhenDragging: Opacity(opacity: .35, child: _WorkCard(item: item, onTap: () {}, action: const SizedBox.shrink())), child: _WorkCard(item: item, onTap: () => onEdit(item), action: IconButton(onPressed: () => onRemove(item), icon: const Icon(Icons.keyboard_return_rounded))))),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _WorkCard extends StatelessWidget {
  final WorkItem item;
  final VoidCallback onTap;
  final Widget action;
  const _WorkCard({required this.item, required this.onTap, required this.action});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Text(_ProductBacklogPageState._typeLabel(item.type), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))), const Spacer(), action]),
              const SizedBox(height: 6),
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (item.description.isNotEmpty) ...[const SizedBox(height: 4), Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)],
              const SizedBox(height: 9),
              Wrap(spacing: 8, runSpacing: 6, children: [if (item.storyPoints > 0) _Mini(icon: Icons.bolt_rounded, text: '${item.storyPoints} SP'), if (item.assignee.isNotEmpty) _Mini(icon: Icons.person_outline_rounded, text: item.assignee), if (item.project.isNotEmpty) _Mini(icon: Icons.layers_outlined, text: item.project)]),
            ]),
          ),
        ),
      );
}

class _Mini extends StatelessWidget {
  final IconData icon; final String text;
  const _Mini({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 3), Text(text, style: Theme.of(context).textTheme.labelSmall)]);
}

class _Metric extends StatelessWidget {
  final String label, value; final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(child: Icon(icon, size: 18)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: Theme.of(context).textTheme.bodySmall)])]));
}

class _Panel extends StatelessWidget {
  final String title, subtitle; final Widget child;
  const _Panel({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 14), child]));
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)])));
}

class _BurndownPainter extends CustomPainter {
  final double total, remaining;
  _BurndownPainter({required this.total, required this.remaining});
  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()..color = Colors.grey.withOpacity(.25)..strokeWidth = 1;
    final ideal = Paint()..color = Colors.grey..strokeWidth = 2..style = PaintingStyle.stroke;
    final actual = Paint()..color = Colors.blueAccent..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axis);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), ideal);
    if (total <= 0) return;
    final y = size.height * (1 - (remaining / total).clamp(0.0, 1.0));
    final path = Path()..moveTo(0, 0)..lineTo(size.width * .5, y * .75)..lineTo(size.width, y);
    canvas.drawPath(path, actual);
  }
  @override
  bool shouldRepaint(covariant _BurndownPainter oldDelegate) => oldDelegate.total != total || oldDelegate.remaining != remaining;
}

extension _FirstOrNull<T> on Iterable<T> { T? get firstOrNull => isEmpty ? null : first; }
