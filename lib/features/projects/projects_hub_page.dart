import 'package:flutter/material.dart';

import '../../data/followup_repository.dart';
import '../../data/project_repository.dart';
import '../../models/followup_item.dart';
import '../../models/project_item.dart';
import '../../state/followup_store.dart';
import '../../state/project_store.dart';

class ProjectsHubPage extends StatefulWidget {
  const ProjectsHubPage({super.key});

  @override
  State<ProjectsHubPage> createState() => _ProjectsHubPageState();
}

class _ProjectsHubPageState extends State<ProjectsHubPage> {
  late final ProjectStore store;

  @override
  void initState() {
    super.initState();
    store = ProjectStore(ProjectRepository());
    store.addListener(_refresh);
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
        body: store.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  _Header(
                    title: 'پروژه‌ها',
                    subtitle: 'نمای زنده PMO، پیشرفت و سلامت پروژه‌ها',
                    action: IconButton.filledTonal(
                      onPressed: _createProject,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PortfolioSummary(items: store.items),
                  const SizedBox(height: 20),
                  if (store.items.isEmpty)
                    _EmptyState(
                      icon: Icons.layers_outlined,
                      title: 'هنوز پروژه‌ای نداری',
                      subtitle: 'اولین پروژه را بساز تا تسک‌ها، پیگیری‌ها و جلسات را به آن متصل کنی.',
                      button: 'ساخت پروژه',
                      onPressed: _createProject,
                    )
                  else
                    ...store.items.map((project) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProjectCard(
                            item: project,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailsPage(store: store, project: project),
                              ),
                            ),
                          ),
                        )),
                ],
              ),
      ),
    );
  }

  Future<void> _createProject() async {
    final created = await showModalBottomSheet<ProjectItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ProjectFormSheet(),
    );
    if (created != null) await store.add(created);
  }
}

class ProjectDetailsPage extends StatefulWidget {
  final ProjectStore store;
  final ProjectItem project;
  const ProjectDetailsPage({super.key, required this.store, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late ProjectItem item;

  @override
  void initState() {
    super.initState();
    item = widget.project;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات پروژه'),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surfaceContainerLow,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(_projectStatusLabel(item.status)),
              const SizedBox(height: 20),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: item.progress, minHeight: 10)),
              const SizedBox(height: 8),
              Text('${(item.progress * 100).round()}٪ پیشرفت', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 18),
          _InfoTile(icon: Icons.person_outline_rounded, title: 'مسئول پروژه', value: item.owner.isEmpty ? 'تعیین نشده' : item.owner),
          _InfoTile(icon: Icons.calendar_month_outlined, title: 'موعد', value: item.dueDate == null ? 'بدون موعد' : _date(item.dueDate!)),
          _InfoTile(icon: Icons.notes_rounded, title: 'توضیحات', value: item.description.isEmpty ? 'توضیحی ثبت نشده' : item.description),
        ],
      ),
    );
  }

  Future<void> _edit() async {
    final updated = await showModalBottomSheet<ProjectItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProjectFormSheet(initial: item),
    );
    if (updated == null) return;
    await widget.store.update(updated);
    setState(() => item = updated);
  }

  Future<void> _delete() async {
    if (item.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف پروژه؟'),
        content: const Text('این عملیات قابل بازگشت نیست.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.remove(item.id!);
      if (mounted) Navigator.pop(context);
    }
  }
}

class FollowupsPage extends StatefulWidget {
  const FollowupsPage({super.key});

  @override
  State<FollowupsPage> createState() => _FollowupsPageState();
}

class _FollowupsPageState extends State<FollowupsPage> {
  late final FollowupStore store;

  @override
  void initState() {
    super.initState();
    store = FollowupStore(FollowupRepository());
    store.addListener(_refresh);
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
    final open = store.items.where((e) => e.status != FollowupStatus.done).toList();
    final done = store.items.where((e) => e.status == FollowupStatus.done).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('پیگیری‌ها')),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add_rounded)),
      body: store.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                _FollowupSummary(total: store.items.length, open: open.length, done: done.length),
                const SizedBox(height: 20),
                Text('نیازمند پیگیری', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (open.isEmpty) const Text('مورد بازی وجود ندارد.') else ...open.map(_card),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('انجام‌شده', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...done.map(_card),
                ],
              ],
            ),
    );
  }

  Widget _card(FollowupItem item) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(child: Icon(item.status == FollowupStatus.done ? Icons.done_rounded : Icons.flag_outlined)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                if (item.context.isNotEmpty) Text(item.context, style: Theme.of(context).textTheme.bodySmall),
              ])),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'done') await store.markDone(item);
                  if (value == 'snooze') await store.snooze(item, DateTime.now().add(const Duration(days: 2)));
                  if (value == 'delete' && item.id != null) await store.remove(item.id!);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'done', child: Text('انجام شد')),
                  PopupMenuItem(value: 'snooze', child: Text('یادآوری ۲ روز دیگر')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Pill(icon: Icons.person_outline_rounded, text: item.assignee.isEmpty ? 'بدون مسئول' : item.assignee),
              _Pill(icon: Icons.calendar_today_outlined, text: item.dueDate == null ? 'بدون موعد' : _date(item.dueDate!)),
              _Pill(icon: Icons.sync_rounded, text: _followupStatusLabel(item.status)),
            ]),
          ]),
        ),
      );

  Future<void> _add() async {
    final created = await showModalBottomSheet<FollowupItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FollowupFormSheet(),
    );
    if (created != null) await store.add(created);
  }
}

class MoreHubPage extends StatelessWidget {
  const MoreHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          const _Header(title: 'بیشتر', subtitle: 'ابزارهای Scrum و PMO در یک فضای خلوت'),
          const SizedBox(height: 18),
          _MenuCard(
            icon: Icons.flag_outlined,
            title: 'پیگیری‌ها',
            subtitle: 'منتظر پاسخ، سررسید گذشته و Snooze',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FollowupsPage())),
          ),
          const SizedBox(height: 10),
          const _MenuCard(icon: Icons.loop_rounded, title: 'اسپرینت‌ها', subtitle: 'Sprint Goal، Velocity و Burndown'),
          const SizedBox(height: 10),
          const _MenuCard(icon: Icons.warning_amber_rounded, title: 'ریسک‌ها و مسائل', subtitle: 'Risk Register و Issue Log'),
          const SizedBox(height: 10),
          const _MenuCard(icon: Icons.insights_rounded, title: 'گزارش‌ها', subtitle: 'گزارش مدیریتی پروژه و تیم'),
          const SizedBox(height: 10),
          const _MenuCard(icon: Icons.settings_outlined, title: 'تنظیمات', subtitle: 'ظاهر، اعلان‌ها و تنظیمات عمومی'),
        ],
      ),
    );
  }
}

class _ProjectFormSheet extends StatefulWidget {
  final ProjectItem? initial;
  const _ProjectFormSheet({this.initial});
  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  late final TextEditingController title;
  late final TextEditingController owner;
  late final TextEditingController description;
  late ProjectStatus status;
  late double progress;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    title = TextEditingController(text: item?.title ?? '');
    owner = TextEditingController(text: item?.owner ?? '');
    description = TextEditingController(text: item?.description ?? '');
    status = item?.status ?? ProjectStatus.active;
    progress = item?.progress ?? 0;
    dueDate = item?.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, bottom: MediaQuery.viewInsetsOf(context).bottom + 22),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.initial == null ? 'پروژه جدید' : 'ویرایش پروژه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'نام پروژه')),
          const SizedBox(height: 10),
          TextField(controller: owner, decoration: const InputDecoration(labelText: 'مسئول پروژه')),
          const SizedBox(height: 10),
          DropdownButtonFormField<ProjectStatus>(value: status, decoration: const InputDecoration(labelText: 'وضعیت'), items: ProjectStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(_projectStatusLabel(e)))).toList(), onChanged: (v) => setState(() => status = v ?? status)),
          const SizedBox(height: 14),
          Text('پیشرفت ${(progress * 100).round()}٪', style: const TextStyle(fontWeight: FontWeight.w800)),
          Slider(value: progress, onChanged: (v) => setState(() => progress = v)),
          OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(dueDate == null ? 'انتخاب موعد' : _date(dueDate!))),
          const SizedBox(height: 10),
          TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'توضیحات')),
          const SizedBox(height: 18),
          FilledButton(onPressed: _save, child: const Text('ذخیره پروژه')),
        ]),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (value != null) setState(() => dueDate = value);
  }

  void _save() {
    if (title.text.trim().isEmpty) return;
    final old = widget.initial;
    Navigator.pop(context, ProjectItem(id: old?.id, title: title.text.trim(), owner: owner.text.trim(), status: status, progress: progress, dueDate: dueDate, description: description.text.trim(), createdAt: old?.createdAt ?? DateTime.now()));
  }
}

class _FollowupFormSheet extends StatefulWidget {
  const _FollowupFormSheet();
  @override
  State<_FollowupFormSheet> createState() => _FollowupFormSheetState();
}

class _FollowupFormSheetState extends State<_FollowupFormSheet> {
  final title = TextEditingController();
  final contextCtrl = TextEditingController();
  final assignee = TextEditingController();
  final note = TextEditingController();
  DateTime? dueDate;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, bottom: MediaQuery.viewInsetsOf(context).bottom + 22),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('پیگیری جدید', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان')),
            const SizedBox(height: 10),
            TextField(controller: contextCtrl, decoration: const InputDecoration(labelText: 'مرتبط با پروژه / جلسه / شخص')),
            const SizedBox(height: 10),
            TextField(controller: assignee, decoration: const InputDecoration(labelText: 'مسئول')),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(dueDate == null ? 'انتخاب موعد' : _date(dueDate!))),
            const SizedBox(height: 10),
            TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'یادداشت')),
            const SizedBox(height: 18),
            FilledButton(onPressed: _save, child: const Text('ذخیره پیگیری')),
          ]),
        ),
      );

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (value != null) setState(() => dueDate = value);
  }

  void _save() {
    if (title.text.trim().isEmpty) return;
    Navigator.pop(context, FollowupItem(title: title.text.trim(), context: contextCtrl.text.trim(), assignee: assignee.text.trim(), dueDate: dueDate, note: note.text.trim(), createdAt: DateTime.now()));
  }
}

class _PortfolioSummary extends StatelessWidget {
  final List<ProjectItem> items;
  const _PortfolioSummary({required this.items});
  @override
  Widget build(BuildContext context) {
    final atRisk = items.where((e) => e.status == ProjectStatus.atRisk || e.status == ProjectStatus.delayed).length;
    final completed = items.where((e) => e.status == ProjectStatus.completed).length;
    return Row(children: [
      Expanded(child: _Metric(label: 'همه پروژه‌ها', value: '${items.length}', icon: Icons.layers_outlined)),
      const SizedBox(width: 10),
      Expanded(child: _Metric(label: 'نیازمند توجه', value: '$atRisk', icon: Icons.warning_amber_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _Metric(label: 'تکمیل‌شده', value: '$completed', icon: Icons.done_all_rounded)),
    ]);
  }
}

class _FollowupSummary extends StatelessWidget {
  final int total;
  final int open;
  final int done;
  const _FollowupSummary({required this.total, required this.open, required this.done});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _Metric(label: 'همه', value: '$total', icon: Icons.flag_outlined)),
        const SizedBox(width: 10),
        Expanded(child: _Metric(label: 'باز', value: '$open', icon: Icons.schedule_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _Metric(label: 'انجام', value: '$done', icon: Icons.done_rounded)),
      ]);
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, size: 19), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall)]),
      );
}

class _ProjectCard extends StatelessWidget {
  final ProjectItem item;
  final VoidCallback onTap;
  const _ProjectCard({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(child: const Icon(Icons.layers_outlined)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(_projectStatusLabel(item.status), style: Theme.of(context).textTheme.bodySmall)])),
              const Icon(Icons.chevron_left_rounded),
            ]),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: item.progress, minHeight: 8)),
            const SizedBox(height: 8),
            Row(children: [Text('${(item.progress * 100).round()}٪ پیشرفت'), const Spacer(), if (item.owner.isNotEmpty) Text(item.owner, style: Theme.of(context).textTheme.bodySmall)]),
          ]),
        ),
      );
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuCard({required this.icon, required this.title, required this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [CircleAvatar(child: Icon(icon)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])), const Icon(Icons.chevron_left_rounded)]),
        ),
      );
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const _Header({required this.title, required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])), if (action != null) action!]);
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onPressed;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, required this.button, required this.onPressed});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(26)),
        child: Column(children: [Icon(icon, size: 42), const SizedBox(height: 14), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(height: 8), Text(subtitle, textAlign: TextAlign.center), const SizedBox(height: 18), FilledButton(onPressed: onPressed, child: Text(button))]),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: CircleAvatar(child: Icon(icon)), title: Text(title), subtitle: Text(value));
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(text, style: Theme.of(context).textTheme.labelSmall)]));
}

String _projectStatusLabel(ProjectStatus value) => switch (value) {
      ProjectStatus.active => 'در مسیر',
      ProjectStatus.atRisk => 'با ریسک',
      ProjectStatus.delayed => 'دارای تأخیر',
      ProjectStatus.completed => 'تکمیل‌شده',
    };

String _followupStatusLabel(FollowupStatus value) => switch (value) {
      FollowupStatus.open => 'باز',
      FollowupStatus.waiting => 'منتظر پاسخ',
      FollowupStatus.snoozed => 'به تعویق افتاده',
      FollowupStatus.done => 'انجام‌شده',
    };

String _date(DateTime value) => '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
