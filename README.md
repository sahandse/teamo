# تیمو | Teamo

اپلیکیشن فارسی و مدرن برای **مدیریت تیم، پروژه، پیگیری، Scrum و PMO** با Flutter.

## نسخه فعلی — 0.14.0

قابلیت‌های فعلی:

- مدیریت تسک و Kanban با ذخیره‌سازی آفلاین SQLite
- پروژه‌ها، جلسات، پیگیری‌ها و Reminder
- Product Backlog، Sprint Backlog، Burndown و Velocity
- Daily Scrum، Retrospective، Sprint Review و Definition of Done
- Risk / Issue Register، KPI / OKR، Change Request و Decision Log
- Stakeholder Register، Milestone و گزارش هفتگی PMO
- Executive PMO با RAG Health، Resource Planning، Dependency Map و Budget Tracking
- Portfolio Intelligence با Capacity Forecast، Critical Path، Portfolio Timeline، Cost Trend، Baseline vs Actual و Executive Weekly Digest
- Strategic PMO با Scenario Planning، What-if Analysis و Portfolio Prioritization
- Earned Value Management با PV / EV / AC / BAC و CPI / SPI / CV / SV / EAC
- Benefits Tracking و Executive Portfolio Report قابل کپی/خروجی متنی
- رابط RTL، تاریخ شمسی، تم روشن/تیره و اعلان‌های محلی
- دیتابیس آفلاین SQLite تا نسخه 12

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

## وضعیت انتشار

قابلیت‌های برنامه تا مرحله Strategic PMO تکمیل شده‌اند. مرحله بعد صرفاً **Release Readiness و QA نهایی** است. Tag، نسخه Release و انتشار عمومی فقط پس از تأیید صریح کاربر ساخته می‌شود.
