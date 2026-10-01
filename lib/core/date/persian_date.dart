import 'package:shamsi_date/shamsi_date.dart';

class PersianDate {
  const PersianDate._();

  static const _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static String short(DateTime value) {
    final j = Jalali.fromDateTime(value);
    return '${_fa(j.year)}/${_two(j.month)}/${_two(j.day)}';
  }

  static String full(DateTime value) {
    final j = Jalali.fromDateTime(value);
    final weekday = j.formatter.wN;
    return '$weekday، ${_fa(j.day)} ${_months[j.month - 1]} ${_fa(j.year)}';
  }

  static String monthTitle(DateTime value) {
    final j = Jalali.fromDateTime(value);
    return '${_months[j.month - 1]} ${_fa(j.year)}';
  }

  static String relative(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final days = date.difference(today).inDays;
    if (days == 0) return 'امروز';
    if (days == 1) return 'فردا';
    if (days == -1) return 'دیروز';
    if (days > 1 && days <= 7) return '${_fa(days)} روز دیگر';
    if (days < -1 && days >= -7) return '${_fa(days.abs())} روز گذشته';
    return short(value);
  }

  static String _two(int value) => _fa(value.toString().padLeft(2, '0'));

  static String _fa(Object input) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    var result = input.toString();
    for (var i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }
    return result;
  }
}
