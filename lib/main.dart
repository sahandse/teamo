import 'package:flutter/material.dart';

void main() => runApp(const TeamoApp());

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
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          elevation: 0,
          indicatorColor: scheme.primary.withValues(alpha: .12),
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

  final pages = const [
    DashboardPage(),
    TasksPage(),
    ProjectsPage(),
    MeetingsPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context),
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

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('افزودن سریع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _QuickChip(icon: Icons.task_alt_rounded, label: 'تسک'),
                  _QuickChip(icon: Icons.event_rounded, label: 'جلسه'),
                  _QuickChip(icon: Icons.flag_rounded, label: 'پیگیری'),
                  _QuickChip(icon: Icons.layers_rounded, label: 'پروژه'),
                  _QuickChip(icon: Icons.warning_amber_rounded, label: 'ریسک'),
                  _QuickChip(icon: Icons.note_alt_rounded, label: 'یادداشت'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Text('سلام 👋', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text('امروز را شفاف و سبک مدیریت کن', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          Text('مرکز کار امروز', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('کارها، جلسات و پیگیری‌های مهم در یک نگاه', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: const [
              _StatCard(icon: Icons.task_alt_rounded, title: 'تسک امروز', value: '۵'),
              _StatCard(icon: Icons.layers_rounded, title: 'پروژه فعال', value: '۳'),
              _StatCard(icon: Icons.event_rounded, title: 'جلسه امروز', value: '۲'),
              _StatCard(icon: Icons.flag_rounded, title: 'پیگیری', value: '۴'),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'پروژه در تمرکز', action: 'همه پروژه‌ها'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(child: Icon(Icons.phone_android_rounded)),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('اپلیکیشن تیمو', style: TextStyle(fontWeight: FontWeight.w900)), Text('Sprint 1 • در حال اجرا', style: TextStyle(fontSize: 12))])),
                      Text('۶۵٪', style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(value: .65, minHeight: 8)),
                  const SizedBox(height: 14),
                  const Row(children: [Icon(Icons.schedule_rounded, size: 16), SizedBox(width: 6), Text('۵ روز تا پایان اسپرینت'), Spacer(), Icon(Icons.groups_2_outlined, size: 16), SizedBox(width: 6), Text('۶ عضو')]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'برنامه امروز', action: 'تقویم'),
          const SizedBox(height: 10),
          const _TimelineItem(time: '09:00', title: 'Daily Scrum', subtitle: 'تیم توسعه'),
          const _TimelineItem(time: '11:30', title: 'تحویل طراحی', subtitle: 'پروژه تیمو'),
          const _TimelineItem(time: '14:00', title: 'جلسه وضعیت پروژه', subtitle: 'PMO'),
          const _TimelineItem(time: '17:00', title: 'پیگیری قرارداد', subtitle: 'نیازمند پاسخ'),
        ],
      ),
    );
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = {
      'بک‌لاگ': ['طراحی صفحه ورود', 'مستندسازی API'],
      'در حال انجام': ['داشبورد اصلی', 'Drag & Drop کانبان'],
      'بررسی': ['بازبینی UI/UX'],
      'انجام شد': ['ساخت ساختار پروژه'],
    };

    return SafeArea(
      child: Column(
        children: [
          const _PageHeader(title: 'کارها', subtitle: 'کانبان ساده برای تمرکز روی جریان کار'),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.entries.map((entry) {
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Badge(label: Text('${entry.value.length}'))]),
                        const SizedBox(height: 12),
                        ...entry.value.map((task) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(task, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text('اپ تیمو', style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 12),
                                  const Row(children: [Icon(Icons.schedule_rounded, size: 15), SizedBox(width: 6), Text('امروز', style: TextStyle(fontSize: 11)), Spacer(), CircleAvatar(radius: 12, child: Text('س', style: TextStyle(fontSize: 10)))]),
                                ]),
                              ),
                            )),
                        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('افزودن کار')),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: const [
            _PageHeader(title: 'پروژه‌ها', subtitle: 'نمای PMO، سلامت پروژه و پیشرفت'),
            _ProjectCard(title: 'اپلیکیشن تیمو', progress: .65, status: 'در مسیر'),
            SizedBox(height: 12),
            _ProjectCard(title: 'پنل مدیریت سازمان', progress: .40, status: 'با ریسک'),
            SizedBox(height: 12),
            _ProjectCard(title: 'سامانه گزارش‌گیری', progress: .20, status: 'تاخیر'),
          ],
        ),
      );
}

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: const [
            _PageHeader(title: 'جلسات', subtitle: 'دستور جلسه، مصوبات و Action Itemها'),
            _MeetingCard(title: 'Daily Scrum', time: '09:00', meta: '۱۵ دقیقه • تیم توسعه'),
            SizedBox(height: 12),
            _MeetingCard(title: 'بررسی وضعیت پروژه', time: '14:00', meta: '۴۵ دقیقه • PMO'),
            SizedBox(height: 12),
            _MeetingCard(title: 'جلسه با مشتری', time: '17:30', meta: '۳۰ دقیقه • فروش و پروژه'),
          ],
        ),
      );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: const [
            _PageHeader(title: 'بیشتر', subtitle: 'ابزارهای اسکرام و PMO'),
            _MenuTile(icon: Icons.sprint_rounded, title: 'اسپرینت‌ها', subtitle: 'Sprint Goal، Velocity و Burndown'),
            _MenuTile(icon: Icons.flag_outlined, title: 'پیگیری‌ها', subtitle: 'منتظر پاسخ، سررسید گذشته و Snooze'),
            _MenuTile(icon: Icons.warning_amber_rounded, title: 'ریسک‌ها و مسائل', subtitle: 'Risk Register و Issue Log'),
            _MenuTile(icon: Icons.insights_rounded, title: 'گزارش‌ها', subtitle: 'گزارش مدیریتی پروژه و تیم'),
            _MenuTile(icon: Icons.settings_outlined, title: 'تنظیمات', subtitle: 'ظاهر، اعلان‌ها و تنظیمات پروژه'),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({required this.icon, required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(child: Icon(icon, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(title, style: Theme.of(context).textTheme.bodySmall)])),
          ]),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  const _SectionTitle({required this.title, required this.action});
  @override
  Widget build(BuildContext context) => Row(children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const Spacer(), TextButton(onPressed: () {}, child: Text(action))]);
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  const _TimelineItem({required this.time, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(child: Text(time.substring(0, 2))),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('$time • $subtitle'),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      );
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
        ]),
      );
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final double progress;
  final String status;
  const _ProjectCard({required this.title, required this.progress, required this.status});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const CircleAvatar(child: Icon(Icons.layers_rounded)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))), Text(status, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 8)),
            const SizedBox(height: 8),
            Text('${(progress * 100).round()}٪ پیشرفت', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}

class _MeetingCard extends StatelessWidget {
  final String title;
  final String time;
  final String meta;
  const _MeetingCard({required this.title, required this.time, required this.meta});
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: const CircleAvatar(child: Icon(Icons.event_rounded)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text('$time • $meta')),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left_rounded),
        ),
      );
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: () {});
}
