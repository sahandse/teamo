import 'package:flutter/material.dart';

import 'data/task_repository.dart';
import 'features/meetings/meetings_page.dart';
import 'features/projects/projects_hub_page.dart';
import 'features/tasks/task_board_page.dart';
import 'state/task_store.dart';

class TeamoApp extends StatelessWidget {
  const TeamoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(
      seedColor: const Color(0xFF536DFE),
      brightness: Brightness.light,
      surface: const Color(0xFFF7F8FC),
    );
    final dark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
      surface: const Color(0xFF11131A),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تیمو',
      locale: const Locale('fa', 'IR'),
      themeMode: ThemeMode.system,
      theme: _theme(light),
      darkTheme: _theme(dark),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeShell(),
    );
  }

  ThemeData _theme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          elevation: 0,
          indicatorColor: scheme.primary.withOpacity(.12),
        ),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  late final TaskStore taskStore;

  @override
  void initState() {
    super.initState();
    taskStore = TaskStore(TaskRepository())..load();
  }

  @override
  void dispose() {
    taskStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: taskStore, onOpen: (value) => setState(() => index = value)),
      TaskBoardPage(store: taskStore),
      const ProjectsHubPage(),
      const MeetingsPage(),
      const MoreHubPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.check_box_outlined), selectedIcon: Icon(Icons.check_box_rounded), label: 'کارها'),
          NavigationDestination(icon: Icon(Icons.layers_outlined), selectedIcon: Icon(Icons.layers_rounded), label: 'پروژه‌ها'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'جلسات'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'بیشتر'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final TaskStore store;
  final ValueChanged<int> onOpen;
  const DashboardPage({super.key, required this.store, required this.onOpen});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) {
    final all = widget.store.items.length;
    final done = widget.store.items.where((e) => e.status.name == 'done').length;
    final doing = widget.store.items.where((e) => e.status.name == 'doing').length;
    final completion = all == 0 ? 0.0 : done / all;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/teamo_logo.png', width: 48, height: 48, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تیمو', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text('مدیریت تیم، پروژه و پیگیری', style: Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.surfaceContainerLow]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('مرکز کار امروز', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('کارهای مهم، پروژه‌ها و جلسات را در یک نگاه مدیریت کن.'),
              const SizedBox(height: 18),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: completion, minHeight: 9)),
              const SizedBox(height: 8),
              Text('${(completion * 100).round()}٪ کارها تکمیل شده', style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _Stat(icon: Icons.task_alt_rounded, label: 'کل کارها', value: '$all', onTap: () => widget.onOpen(1)),
              _Stat(icon: Icons.play_circle_outline_rounded, label: 'در حال انجام', value: '$doing', onTap: () => widget.onOpen(1)),
              _Stat(icon: Icons.done_all_rounded, label: 'انجام‌شده', value: '$done', onTap: () => widget.onOpen(1)),
              _Stat(icon: Icons.event_note_outlined, label: 'جلسات', value: 'تقویم', onTap: () => widget.onOpen(3)),
            ],
          ),
          const SizedBox(height: 22),
          Text('دسترسی سریع', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Shortcut(icon: Icons.layers_outlined, label: 'پروژه‌ها', onTap: () => widget.onOpen(2))),
            const SizedBox(width: 10),
            Expanded(child: _Shortcut(icon: Icons.event_note_rounded, label: 'جلسات', onTap: () => widget.onOpen(3))),
          ]),
        ],
      ),
    );
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
          Text('بیشتر', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('ابزارهای Scrum و PMO', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          const _MoreTile(icon: Icons.loop_rounded, title: 'اسپرینت‌ها', subtitle: 'Sprint Goal، Velocity و Burndown'),
          const _MoreTile(icon: Icons.flag_outlined, title: 'پیگیری‌ها', subtitle: 'موارد منتظر پاسخ و سررسید گذشته'),
          const _MoreTile(icon: Icons.warning_amber_rounded, title: 'ریسک‌ها و مسائل', subtitle: 'Risk Register و Issue Log'),
          const _MoreTile(icon: Icons.insights_rounded, title: 'گزارش‌ها', subtitle: 'گزارش مدیریتی پروژه و تیم'),
          const _MoreTile(icon: Icons.settings_outlined, title: 'تنظیمات', subtitle: 'ظاهر، اعلان‌ها و تنظیمات عمومی'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _Stat({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            CircleAvatar(child: Icon(icon, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ])),
          ]),
        ),
      );
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [Icon(icon), const SizedBox(width: 9), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), const Icon(Icons.chevron_left_rounded, size: 18)]),
        ),
      );
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MoreTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
          const Icon(Icons.chevron_left_rounded),
        ]),
      );
}
