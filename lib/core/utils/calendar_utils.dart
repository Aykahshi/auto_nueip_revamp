import 'package:flutter/material.dart';

import '../../features/calendar/data/models/attendance_details.dart'; // Import needed model

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
    // Priority 1: Specific events override attendance status
    if (overtime != null && overtime.isNotEmpty) return '加班';
    if (timeoff != null && timeoff.isNotEmpty) return '請假';

    // Priority 2: Check absence first (曠職)
    if (attendance != null && attendance.isAbsent) return '曠職';

    // Priority 3: Check missing punch (缺卡) - Requires at least one punch
    // Assumes isMissPunch correctly flags if either clockIn or clockOut is missing when expected.
    if (attendance != null && attendance.isMissPunch) return '缺卡';

    // Priority 4: Holiday (only if not OT/Leave/Absent/MissPunch)
    if (isHoliday) return '假日';

    // Priority 5: Attendance status if it's a workday with *complete* punches
    // (If we reached here, it implies !isAbsent and !isMissPunch)
    if (attendance != null) {
      if (attendance.isLate && attendance.isLeaveEarly) return '遲到/早退';
      if (attendance.isLate) return '遲到';
      if (attendance.isLeaveEarly) return '早退';

      // If attendance exists, isn't absent, isn't missing punch, and isn't late/early,
      // and we've passed the isMissPunch check, it implies punches are complete.
      return '正常';
    }

    // Priority 6: No data at all (Workday, no attendance record)
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
        return Icons.auto_awesome;
      case '無資料':
        return Icons.help_outline;
      // Default assumes leave type
      default:
        return Icons.event_busy_outlined;
    }
  }
}
