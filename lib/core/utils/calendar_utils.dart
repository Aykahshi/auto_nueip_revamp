import 'package:flutter/material.dart';

sealed class CalendarUtils {
  const CalendarUtils._(); // Private constructor to prevent instantiation

  /// Returns the localized name of the weekday.
  static String getWeekdayName(int weekday, BuildContext context) {
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

  /// Returns localized display string for clock-in status or reason.
  static String getClockInDisplayString(String key, String value) {
    const statusMap = {
      'status': '狀態',
      'punchIn': '上班打卡',
      'punchOut': '下班打卡',
      'reason': '事由',
    };
    const valueMap = {
      'normal': '正常',
      'late': '遲到',
      'absent': '缺勤',
      'holiday': '假日/休息日', // This might be overridden by specific holiday name
      'personal_leave': '事假',
      // Add other reason mappings here
    };

    // For status and reason, look up the value. For times, use the value directly.
    if (key == 'status') {
      return valueMap[value] ??
          value; // Return localized status or original value
    } else if (key == 'reason') {
      return valueMap[value] ??
          value; // Return localized reason or original value
    } else {
      return value; // Return time string directly
    }
  }

  /// Returns the appropriate icon for a given punch-in status.
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'normal':
        return Icons.check_circle_outline;
      case 'late':
        return Icons.watch_later_outlined;
      case 'absent':
        return Icons.person_off_outlined;
      case 'holiday':
        return Icons.celebration_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Returns the appropriate color for a given punch-in status.
  static Color getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'normal':
        return Colors.green.shade600;
      case 'late':
        return Colors.orange.shade700;
      case 'absent':
        return colorScheme.error;
      case 'holiday':
        return Colors.blueGrey.shade500;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
