import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/calendar_utils.dart';

part 'punch_in_data.freezed.dart';
part 'punch_in_data.g.dart';

@freezed
sealed class PunchInData with _$PunchInData {
  const PunchInData._();

  const factory PunchInData({
    required DateTime date,
    required String status,
    String? punchIn,
    String? punchOut,
    String? reason,
  }) = _PunchInData;

  factory PunchInData.fromJson(Map<String, dynamic> json) =>
      _$PunchInDataFromJson(json);

  String get primaryInfo =>
      '${date.year}/${date.month}/${date.day} (${_getWeekday(date)})';

  String get secondaryInfo {
    String info = CalendarUtils.getPunchInDisplayString('status', status);
    if (punchIn != null) {
      info += ', ${CalendarUtils.getPunchInDisplayString("punchIn", punchIn!)}';
    }
    if (punchOut != null) {
      info +=
          ', ${CalendarUtils.getPunchInDisplayString("punchOut", punchOut!)}';
    }
    if (reason != null) {
      info += ', ${CalendarUtils.getPunchInDisplayString("reason", reason!)}';
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
