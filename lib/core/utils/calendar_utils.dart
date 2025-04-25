import 'package:flutter/material.dart';

import '../../data/models/attendance_details.dart'; // Import needed model

sealed class CalendarUtils {
  const CalendarUtils._(); // Private constructor to prevent instantiation

  /// Returns the localized name of the weekday.
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '週一';
      case 2:
        return '週二';
      case 3:
        return '週三';
      case 4:
        return '週四';
      case 5:
        return '週五';
      case 6:
        return '週六';
      case 7:
        return '週日';
      default:
        return '';
    }
  }

  /// Formats duration into "X 小時 Y 分鐘".
  static String formatDuration(num hours, num mins) {
    if (hours == 0 && mins == 0) return '--';
    String result = '';
    if (hours > 0) {
      result += '$hours 小時';
    }
    if (mins > 0) {
      if (result.isNotEmpty) result += ' ';
      result += '$mins 分鐘';
    }
    return result;
  }

  /// Formats total minutes into "X hours Y minutes".
  static String formatMinutes(num? totalMinutes) {
    if (totalMinutes == null || totalMinutes <= 0) return '--';

    final hours = totalMinutes ~/ 60; // Integer division for hours
    final minutes = totalMinutes % 60; // Remainder for minutes

    String result = '';
    if (hours > 0) {
      result += '$hours 小時';
    }
    if (minutes > 0) {
      if (result.isNotEmpty) result += ' ';
      result += '$minutes 分鐘';
    }
    // Handle case where totalMinutes is less than 1 minute but not 0?
    // If totalMinutes can be fractional, adjust logic.
    // Assuming integer minutes for now.
    if (result.isEmpty) return '0 分鐘'; // Or handle as needed
    return result;
  }

  /// Determines the primary status tag based on attendance and time off data.
  static String getAttendanceStatusTag(
    Attendance? attendance,
    List<TimeOffRecord>? timeoff,
    List<OvertimeRecord>? overtime,
    bool isHoliday,
  ) {
    // Priority 1: Overtime
    if (overtime != null && overtime.isNotEmpty) {
      return '加班';
    }
    // Priority 2: Time Off (Leave)
    if (timeoff != null && timeoff.isNotEmpty) {
      // If time off exists, the tag is simply "請假"
      return '請假';
    }

    // --- Only check below if no Overtime and no Time Off ---

    // Priority 3: Holiday (if no OT/Leave)
    if (isHoliday) return '假日';

    // Priority 4: Attendance Status (Workday, no OT/Leave)
    if (attendance != null) {
      if (attendance.isAbsent) return '曠職';
      if (attendance.isMissPunch) return '缺卡';
      if (attendance.isLate && attendance.isLeaveEarly) return '遲到/早退';
      if (attendance.isLate) return '遲到';
      if (attendance.isLeaveEarly) return '早退';
      // If punch in/out exists but no other issues
      return '正常';
    }

    // Priority 5: No data at all (Workday, no record)
    return '無資料';
  }

  /// Returns the appropriate color for a given status tag.
  static Color getStatusTagColor(String tag, ColorScheme colorScheme) {
    switch (tag) {
      case '正常':
        return Colors.green.shade600;
      case '遲到':
      case '早退':
      case '遲到/早退':
      case '缺卡':
        return Colors.orange.shade700;
      case '曠職':
        return colorScheme.error;
      case '加班':
        return Colors.red.shade600;
      case '假日':
      case '無資料':
        return Colors.blueGrey.shade500;
      // Default assumes leave type - use the secondary theme color
      default:
        return colorScheme.secondary;
    }
  }

  /// Returns the appropriate icon for a given status tag.
  static IconData getStatusTagIcon(String tag) {
    switch (tag) {
      case '正常':
        return Icons.check_circle_outline;
      case '遲到':
      case '早退':
      case '遲到/早退':
        return Icons.watch_later_outlined;
      case '缺卡':
        return Icons.report_problem_outlined;
      case '曠職':
        return Icons.person_off_outlined;
      case '加班':
        return Icons.more_time_outlined;
      case '假日':
        return Icons.cake_outlined;
      case '無資料':
        return Icons.help_outline;
      // Default assumes leave type
      default:
        return Icons.event_busy_outlined;
    }
  }
}
