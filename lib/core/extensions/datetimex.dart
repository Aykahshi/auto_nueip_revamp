import 'package:intl/intl.dart';

extension StringToDateTime on String {
  DateTime parseDateTime() {
    int year = int.parse(substring(0, 4));
    int month = int.parse(substring(4, 6));
    int day = int.parse(substring(6, 8));

    DateTime date = DateTime(year, month, day);

    return date;
  }
}

extension DateTimeToString on DateTime {
  String timeFormat() {
    final String formattedTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(this).replaceAll(' ', '+');

    return formattedTime;
  }
}
