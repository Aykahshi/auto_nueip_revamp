import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/calendar_utils.dart';

part 'clock_in_data.freezed.dart';
part 'clock_in_data.g.dart';

@freezed
sealed class ClockInData with _$ClockInData {
  const ClockInData._();

  const factory ClockInData({
    required DateTime date,
    required String status,
    String? clockIn,
    String? clockOut,
    String? reason,
  }) = _ClockInData;

  factory ClockInData.fromJson(Map<String, dynamic> json) =>
      _$ClockInDataFromJson(json);

  String get primaryInfo =>
      '${date.year}/${date.month}/${date.day} (${_getWeekday(date)})';

  String get secondaryInfo {
    String info = CalendarUtils.getClockInDisplayString('status', status);
    if (clockIn != null) {
      info += ', ${CalendarUtils.getClockInDisplayString("clockIn", clockIn!)}';
    }
    if (clockOut != null) {
      info +=
          ', ${CalendarUtils.getClockInDisplayString("clockOut", clockOut!)}';
    }
    if (reason != null) {
      info += ', ${CalendarUtils.getClockInDisplayString("reason", reason!)}';
    }
    return info;
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    if (date.weekday >= 1 && date.weekday <= 7) {
      return weekdays[date.weekday - 1];
    }
    return '';
  }
}
