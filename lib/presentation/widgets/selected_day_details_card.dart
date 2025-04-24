import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/calendar_utils.dart'; // Import utils
import '../../domain/entities/clock_in_data.dart';
import 'detail_info_row.dart'; // Import the new row widget

/// Displays the details for the selected day, showing clock-in info or holiday status.
class SelectedDayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final ClockInData? clockInData;
  final String? holidayDescription; // Explicit holiday description
  final bool isLoading;
  final bool isKnownHoliday; // Indicate if the date is a known holiday

  const SelectedDayDetailsCard({
    required this.selectedDate,
    required this.clockInData,
    required this.holidayDescription,
    required this.isLoading,
    required this.isKnownHoliday,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine the title
    final String titleDate =
        DateUtils.isSameDay(selectedDate, DateTime.now())
            ? '今天'
            : '${selectedDate.month}/${selectedDate.day}';
    final String titleWeekday = CalendarUtils.getWeekdayName(
      selectedDate.weekday,
      context,
    );
    String titleSuffix = '';
    Color titleColor = colorScheme.primary; // Default title color

    if (isKnownHoliday) {
      titleSuffix = holidayDescription ?? '休假';
      titleColor = CalendarUtils.getStatusColor('holiday', colorScheme);
    } else if (clockInData != null && clockInData!.status != 'error') {
      titleSuffix = '打卡記錄';
    }

    final String titleText = '$titleDate ($titleWeekday) $titleSuffix'.trim();

    return Card(
      key: ValueKey(selectedDate), // Key based on the selected date
      margin: EdgeInsets.zero, // Remove default card margin
      elevation: 1,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Title ---
            Text(
              titleText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 20, thickness: 0.5),
            // --- Content Area (Loading/Error/Details) ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main content based on loading state, errors, or data.
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Loading indicator
    if (isLoading) {
      return const Center(
        key: ValueKey('loading_details'),
        child: CircularProgressIndicator(),
      );
    }

    // Handle known holiday status
    if (isKnownHoliday) {
      // If clockInData is null (shouldn't happen if isKnownHoliday is true, but as fallback)
      // create a dummy holiday object.
      final holidayData =
          clockInData ?? ClockInData(date: selectedDate, status: 'holiday');
      return _buildHolidayOrAbsentContent(
        context,
        holidayData,
        holidayDescription,
      );
    }

    // Handle error or no data for non-holidays
    if (clockInData == null || clockInData!.status == 'error') {
      return Center(
        key: const ValueKey('error_details'),
        child: Text(
          '無法載入打卡資料',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
        ),
      );
    }

    // Display clock-in details (Normal, Late, Absent)
    if (clockInData!.status == 'absent') {
      return _buildHolidayOrAbsentContent(context, clockInData!, null);
    } else {
      return _buildPunchInDetailsList(context, clockInData!);
    }
  }

  /// Builds the centered display for holidays or absences.
  Widget _buildHolidayOrAbsentContent(
    BuildContext context,
    ClockInData data,
    String? holidayDesc,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = CalendarUtils.getStatusColor(data.status, colorScheme);
    final statusIcon = CalendarUtils.getStatusIcon(data.status);
    // Use explicit holiday description if available and status is holiday
    final displayStatus =
        data.status == 'holiday'
            ? (holidayDesc ??
                CalendarUtils.getClockInDisplayString('status', data.status))
            : CalendarUtils.getClockInDisplayString('status', data.status);
    // Use reason from data if status is absent
    final displayReason =
        data.status == 'absent' && data.reason != null
            ? CalendarUtils.getClockInDisplayString('reason', data.reason!)
            : null;

    return Center(
      key: ValueKey('${data.status}_${data.date}'), // Unique key
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 48, color: statusColor.withValues(alpha: 0.8)),
          const SizedBox(height: 12), // Increased spacing
          Text(
            displayStatus,
            style: theme.textTheme.titleMedium?.copyWith(color: statusColor),
            textAlign: TextAlign.center,
          ),
          if (displayReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "($displayReason)", // Show reason in parentheses
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  /// Builds the list view for normal/late clock-in details.
  Widget _buildPunchInDetailsList(BuildContext context, ClockInData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = CalendarUtils.getStatusColor(data.status, colorScheme);
    final statusIcon = CalendarUtils.getStatusIcon(data.status);
    final statusDisplay = CalendarUtils.getClockInDisplayString(
      'status',
      data.status,
    );

    return ListView(
      key: ValueKey('details_${data.date}'), // Unique key
      padding: EdgeInsets.zero,
      children: [
        DetailInfoRow(
          icon: Icons.access_time_outlined,
          label: '上班打卡',
          value: data.clockIn ?? '--',
        ),
        DetailInfoRow(
          icon: Icons.access_time_filled_outlined,
          label: '下班打卡',
          value: data.clockOut ?? '--',
        ),
        DetailInfoRow(
          icon: statusIcon,
          label: '狀態',
          value: statusDisplay,
          valueColor: statusColor,
        ),
        if (data.reason != null)
          DetailInfoRow(
            icon: Icons.notes_outlined,
            label: '事由',
            value: CalendarUtils.getClockInDisplayString(
              'reason',
              data.reason!,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 200.ms);
  }
}
