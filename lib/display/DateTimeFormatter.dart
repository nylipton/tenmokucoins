import 'package:intl/intl.dart';

/// Use this to format a [DateTime] to a [String]
class DateTimeFormatter {
  static DateFormat timeFormat = DateFormat.jm( ) ;
  static DateFormat dateAndTimeFormat = DateFormat.yMd( ).add_jm();

  static String format(DateTime tm) {
    DateTime today = new DateTime.now();
    if( tm.day == today.day )
      return 'today ' + timeFormat.format( tm ) ;
    else
      return dateAndTimeFormat.format( tm ) ;
  }
}
