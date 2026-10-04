import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _display = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) => _display.format(date);

  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static DateTime addPlanDuration(DateTime start, int durationInDays) {
    return start.add(Duration(days: durationInDays));
  }

  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  static bool isExpiringSoon(DateTime dueDate, {int withinDays = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = dueDate.difference(today).inDays;
    return diff >= 0 && diff <= withinDays;
  }
}
