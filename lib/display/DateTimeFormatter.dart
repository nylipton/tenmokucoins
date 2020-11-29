import 'package:intl/intl.dart';

/// Use this to format a [DateTime] to a [String]
class DateTimeFormatter {
  static DateFormat timeFormat = DateFormat.jm();

  static DateFormat dateAndTimeFormat = DateFormat.yMd().add_jm();

  static String format(DateTime tm) {
    var today = DateTime.now();
    var val = (tm.day == today.day)
        ? 'today ' + timeFormat.format(tm)
        : dateAndTimeFormat.format(tm);
    return val;
  }
}
