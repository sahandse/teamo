# تیمو | Teamo

اپلیکیشن فارسی و مدرن برای **مدیریت تیم، پروژه، پیگیری، Scrum و PMO** با Flutter.

## نسخه فعلی — 0.13.0

قابلیت‌های فعلی:

- مدیریت تسک و Kanban با ذخیره‌سازی آفلاین SQLite
- پروژه‌ها، جلسات، پیگیری‌ها و Reminder
- Product Backlog، Sprint Backlog، Burndown و Velocity
- Daily Scrum، Retrospective، Sprint Review و Definition of Done
- Risk / Issue Register، KPI / OKR، Change Request و Decision Log
- Stakeholder Register، Milestone و گزارش هفتگی PMO
- Executive PMO با RAG Health، Resource Planning، Dependency Map و Budget Tracking
- **Portfolio Intelligence** با Capacity Forecast، Critical Path، Portfolio Timeline، Cost Trend، Baseline vs Actual و Executive Weekly Digest
- رابط RTL، تاریخ شمسی، تم روشن/تیره و اعلان‌های محلی

## هویت محصول

- نام: **تیمو**
- English: **Teamo**
- Android package: `ir.teamo.app`
- شعار: **مدیریت تیم، پروژه و پیگیری در یک‌جا**

## راه‌اندازی Android

```bash
bash setup_project.sh
flutter pub get
dart run flutter_launcher_icons
flutter run
```

GitHub Actions روی Pull Request و شاخه `main`، Analyze انجام می‌دهد و APK Debug می‌سازد.

## مرحله فعلی — Portfolio Intelligence

- Capacity Forecast اعضای تیم و تشخیص Over Allocation
- Critical Path مبتنی بر Dependencyها و Blockerها
- Portfolio Timeline با مقایسه موعد فعلی و Baseline
- ثبت Baseline پیشرفت، زمان و هزینه هر پروژه
- Cost Snapshot روزانه و Cost Trend
- Executive Weekly Digest خودکار از وضعیت Portfolio
- دیتابیس نسخه 11

## مرحله بعد

Scenario Planning، What-if Analysis، Earned Value Management (PV/EV/AC)، CPI/SPI، Portfolio Prioritization، Benefits Tracking و Executive PDF/CSV Report.
