import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateTime = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _dateOnly = DateFormat('dd.MM.yyyy');

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTime.format(date.toLocal());
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateOnly.format(date.toLocal());
  }
}
