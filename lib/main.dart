import 'package:flutter/material.dart';

import 'data/task_repository.dart';
import 'features/tasks/task_board_page.dart';
import 'state/task_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TeamoApp());
}

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

  ThemeData _theme(ColorScheme scheme) {
    return ThemeData(
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
    taskStore = TaskStore(TaskRepository());
    taskStore.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: taskStore),
      TaskBoardPage(store: taskStore),
      const ProjectsPage(),
      const MeetingsPage(),
      const MorePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: index == 1
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => index = 1),
              child: const Icon(Icons.add_rounded),
            ),
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
  const DashboardPage({super.key, required this.store});

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
    final done = widget.store.items.where((task) => task.status.name == 'done').length;
    final doing = widget.store.items.where((task) => task.status.name == 'doing').length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/teamo_logo.png', width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تیمو', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    Text('مدیریت تیم، پروژه و پیگیری', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: 26),
          Text('مرکز کار امروز', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('خلوت، سریع و متمرکز روی کارهای مهم', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _StatCard(icon: Icons.task_alt_rounded, title: 'کل کارها', value: '$all'),
              _StatCard(icon: Icons.play_circle_outline_rounded, title: 'در حال انجام', value: '$doing'),
              _StatCard(icon: Icons.done_all_rounded, title: 'انجام شده', value: '$done'),
              const _StatCard(icon: Icons.flag_outlined, title: 'پیگیری امروز', value: '۴'),
            ],
          ),
          const SizedBox(height: 24),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.auto_awesome_rounded)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تمرکز امروز', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('۳ کار اصلی را قبل از پایان روز جلو ببر')]))
                  ],
                ),
                const SizedBox(height: 18),
                const _FocusRow(label: 'تکمیل داشبورد اصلی', progress: .75),
                const SizedBox(height: 12),
                const _FocusRow(label: 'بازبینی طراحی کانبان', progress: .45),
                const SizedBox(height: 12),
                const _FocusRow(label: 'آماده‌سازی جلسه اسپرینت', progress: .25),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('برنامه امروز', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _TimelineItem(time: '09:00', title: 'Daily Scrum', subtitle: 'تیم توسعه'),
          const _TimelineItem(time: '14:00', title: 'بررسی وضعیت پروژه', subtitle: 'PMO'),
          const _TimelineItem(time: '17:00', title: 'پیگیری موارد باز', subtitle: '۳ مورد نیازمند پاسخ'),
        ],
      ),
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'پروژه‌ها',
      subtitle: 'نمای سبک PMO برای وضعیت و پیشرفت',
      children: [
        _ProjectCard(title: 'اپلیکیشن تیمو', progress: .65, status: 'در مسیر'),
        _ProjectCard(title: 'پنل مدیریت سازمان', progress: .40, status: 'با ریسک'),
        _ProjectCard(title: 'سامانه گزارش‌گیری', progress: .20, status: 'نیازمند توجه'),
      ],
    );
  }
}

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'جلسات',
      subtitle: 'جلسه، مصوبه و اقدام بعدی در یک مسیر',
      children: [
        _MeetingCard(title: 'Daily Scrum', meta: '09:00 • ۱۵ دقیقه • تیم توسعه'),
        _MeetingCard(title: 'بررسی وضعیت پروژه', meta: '14:00 • ۴۵ دقیقه • PMO'),
        _MeetingCard(title: 'جلسه با مشتری', meta: '17:30 • ۳۰ دقیقه • پروژه تیمو'),
      ],
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'بیشتر',
      subtitle: 'ابزارهای تکمیلی Scrum و PMO',
      children: [
        _MenuTile(icon: Icons.loop_rounded, title: 'اسپرینت‌ها', subtitle: 'Sprint Goal، Velocity و Burndown'),
        _MenuTile(icon: Icons.flag_outlined, title: 'پیگیری‌ها', subtitle: 'موارد منتظر پاسخ و سررسید گذشته'),
        _MenuTile(icon: Icons.warning_amber_rounded, title: 'ریسک‌ها و مسائل', subtitle: 'Risk Register و Issue Log'),
        _MenuTile(icon: Icons.insights_rounded, title: 'گزارش‌ها', subtitle: 'گزارش مدیریتی پروژه و تیم'),
        _MenuTile(icon: Icons.settings_outlined, title: 'تنظیمات', subtitle: 'ظاهر، اعلان‌ها و تنظیمات عمومی'),
      ],
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SimplePage({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        itemCount: children.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ]),
            );
          }
          return children[index - 1];
        },
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Row(children: [
          CircleAvatar(child: Icon(icon, size: 19)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ])),
        ]),
      );
}

class _FocusRow extends StatelessWidget {
  final String label;
  final double progress;
  const _FocusRow({required this.label, required this.progress});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${(progress * 100).round()}٪')]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 7)),
        ],
      );
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  const _TimelineItem({required this.time, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 54, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w800))),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
        ]),
      );
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final double progress;
  final String status;
  const _ProjectCard({required this.title, required this.progress, required this.status});
  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const CircleAvatar(child: Icon(Icons.layers_outlined)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))), Text(status, style: Theme.of(context).textTheme.labelSmall)]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8)),
          const SizedBox(height: 8),
          Text('${(progress * 100).round()}٪ پیشرفت', style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _MeetingCard extends StatelessWidget {
  final String title;
  final String meta;
  const _MeetingCard({required this.title, required this.meta});
  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Row(children: [
          const CircleAvatar(child: Icon(Icons.event_note_rounded)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(meta, style: Theme.of(context).textTheme.bodySmall)])),
          const Icon(Icons.chevron_left_rounded),
        ]),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => _GlassCard(
        child: Row(children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
          const Icon(Icons.chevron_left_rounded),
        ]),
      );
}
