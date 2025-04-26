import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/theme_extensions.dart';
import '../../core/utils/calendar_utils.dart';
import '../../data/models/attendance_details.dart';
import 'detail_info_row.dart';

/// Displays the details for the selected day, showing attendance info or holiday status.
class SelectedDayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final AttendanceRecord? attendanceRecord;
  final String? holidayDescription;
  final bool isLoading;
  final bool isKnownHoliday;

  const SelectedDayDetailsCard({
    required this.selectedDate,
    required this.attendanceRecord,
    required this.holidayDescription,
    required this.isLoading,
    required this.isKnownHoliday,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String titleDate = DateFormat('yyyy / M / d').format(selectedDate);
    final String titleWeekday = CalendarUtils.getWeekdayName(
      selectedDate.weekday,
    );
    final String titleText = '$titleDate ($titleWeekday)';

    late String statusTag;
    late Color statusColor;
    late IconData statusIcon;

    if (isKnownHoliday && attendanceRecord == null) {
      statusTag = '假日';
      statusColor = CalendarUtils.getStatusTagColor(
        statusTag,
        context.colorScheme,
      );
      statusIcon = CalendarUtils.getStatusTagIcon(statusTag);
    } else {
      statusTag = CalendarUtils.getAttendanceStatusTag(
        attendanceRecord?.attendance,
        attendanceRecord?.timeoff,
        attendanceRecord?.overtime,
        isKnownHoliday,
      );
      statusColor = CalendarUtils.getStatusTagColor(
        statusTag,
        context.colorScheme,
      );
      statusIcon = CalendarUtils.getStatusTagIcon(statusTag);
    }

    return Card(
      key: ValueKey(selectedDate),
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      color: context.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.i(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(50)),
                  child: Text(
                    titleText,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                      fontSize: context.sp(16),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isLoading)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(12)),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: context.w(1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: context.r(14),
                            color: statusColor,
                          ),
                          SizedBox(width: context.w(4)),
                          Text(
                            statusTag,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              height: 1.1,
                              fontSize: context.sp(11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Divider(height: context.h(20), thickness: context.w(0.5)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildContent(context, statusTag, statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String statusTag,
    Color statusColor,
  ) {
    if (isLoading) {
      return const Center(
        key: ValueKey('loading_details'),
        child: CircularProgressIndicator(),
      );
    }

    if (statusTag == '請假' && attendanceRecord?.timeoff?.isNotEmpty == true) {
      return _buildLeaveDetailsContent(context, attendanceRecord!.timeoff!);
    }

    if (isKnownHoliday) {
      final bool hasMeaningfulRecord =
          attendanceRecord != null &&
          ((attendanceRecord!.overtime?.isNotEmpty ?? false) ||
              (attendanceRecord!.attendance != null &&
                  (attendanceRecord!.attendance!.duringHour) > 0));

      if (!hasMeaningfulRecord) {
        return _buildHolidayContent(context, holidayDescription, statusTag);
      }
    }

    if (attendanceRecord != null) {
      if (statusTag != '請假') {
        return _buildAttendanceDetailsList(
          context,
          attendanceRecord!,
          statusTag,
        );
      }
    }

    return Center(
      key: const ValueKey('no_data_details'),
      child: Text(
        '本日無出勤資料',
        style: context.textTheme.bodyLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontSize: context.sp(16),
        ),
      ),
    );
  }

  Widget _buildHolidayContent(
    BuildContext context,
    String? holidayDesc,
    String statusTag,
  ) {
    final statusColor = CalendarUtils.getStatusTagColor(
      statusTag,
      context.colorScheme,
    );
    final statusIcon = Icons.auto_awesome;
    final displayStatus =
        holidayDesc == null || holidayDesc.isEmpty ? '假日' : holidayDesc;

    return Container(
      key: ValueKey('holiday_${selectedDate.toIso8601String()}'),
      height: context.h(150),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.05),
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                statusIcon,
                size: context.r(52),
                color: statusColor.withValues(alpha: 0.9),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(end: 1.15, duration: 800.ms, curve: Curves.easeInOut)
              .fadeIn(),
          Gap(context.h(12)),
          Text(
            displayStatus,
            style: context.textTheme.titleMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: context.sp(16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildLeaveDetailsContent(
    BuildContext context,
    List<TimeOffRecord> timeoffRecords,
  ) {
    final leaveColor = context.colorScheme.secondary;

    return Container(
      key: const ValueKey('leave_details'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            timeoffRecords.mapIndexed((index, leave) {
              return Padding(
                padding: EdgeInsets.only(top: index > 0 ? context.h(12) : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailInfoRow(
                      icon: Icons.category_outlined,
                      label: '請假類別',
                      value: leave.ruleName ?? 'N/A',
                      valueColor: leaveColor,
                      valueStyle: context.textTheme.bodyMedium?.copyWith(
                        color: leaveColor,
                        fontSize: context.sp(14),
                      ),
                      useCompactFlex: true,
                    ),
                    DetailInfoRow(
                      icon: Icons.access_time_outlined,
                      label: '請假時間',
                      value: leave.time ?? '--',
                      valueColor: leaveColor,
                      valueStyle: context.textTheme.bodyMedium?.copyWith(
                        color: leaveColor,
                        fontSize: context.sp(14),
                      ),
                      useCompactFlex: true,
                    ),
                    if (leave.remark != null && leave.remark!.isNotEmpty)
                      DetailInfoRow(
                        icon: Icons.notes_outlined,
                        label: '請假原因',
                        value: leave.remark!,
                        valueColor: leaveColor,
                        valueStyle: context.textTheme.bodyMedium?.copyWith(
                          color: leaveColor,
                          fontSize: context.sp(14),
                        ),
                        useCompactFlex: true,
                      ),
                    if (index < timeoffRecords.length - 1)
                      Divider(
                        height: context.h(16),
                        thickness: context.w(0.5),
                        indent: context.w(16),
                        endIndent: context.w(16),
                      ),
                  ],
                ),
              );
            }).toList(),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildAttendanceDetailsList(
    BuildContext context,
    AttendanceRecord record,
    String statusTag,
  ) {
    final valueStyle = context.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.colorScheme.primary,
      fontSize: context.sp(16),
    );
    final labelStyle = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
      fontSize: context.sp(14),
    );
    final placeholderStyle = context.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.colorScheme.outline.withValues(alpha: 0.6),
      fontSize: context.sp(16),
    );

    String getPunchTime(List<PunchRecord>? punches) {
      return punches?.firstOrNull?.time ?? '-- : --';
    }

    final bool hasPunches =
        (record.punch?.onPunch.isNotEmpty ?? false) &&
        (record.punch?.offPunch.isNotEmpty ?? false);
    final num hours = record.attendance?.duringHour ?? 0;
    final num mins = record.attendance?.duringMin ?? 0;
    final showDuration = hasPunches && (hours > 0 || mins > 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('details_${record.dateInfo?.date}'),
        children: [
          if (record.workTime != null && record.workTime!.isNotEmpty)
            DetailInfoRow(
              icon: Icons.schedule_outlined,
              label: '工作時間',
              value: record.workTime!,
              valueStyle: valueStyle,
              labelStyle: labelStyle,
              placeholderStyle: placeholderStyle,
              useCompactFlex: true,
            ),
          DetailInfoRow(
            icon: Icons.login_outlined,
            label: '上班打卡',
            value: getPunchTime(record.punch?.onPunch),
            valueStyle: valueStyle,
            labelStyle: labelStyle,
            placeholderStyle: placeholderStyle,
            useCompactFlex: true,
          ),
          DetailInfoRow(
            icon: Icons.logout_outlined,
            label: '下班打卡',
            value: getPunchTime(record.punch?.offPunch),
            valueStyle: valueStyle,
            labelStyle: labelStyle,
            placeholderStyle: placeholderStyle,
            useCompactFlex: true,
          ),
          if (showDuration)
            DetailInfoRow(
              icon: Icons.timer_outlined,
              label: '實際工時',
              value: CalendarUtils.formatDuration(hours, mins),
              valueStyle: valueStyle,
              labelStyle: labelStyle,
              placeholderStyle: placeholderStyle,
              useCompactFlex: true,
            ),
          if (record.overtime != null && record.overtime!.isNotEmpty)
            _buildOvertimeRow(context, record.overtime!.first, labelStyle),
          Gap(context.h(8)),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  Widget _buildOvertimeRow(
    BuildContext context,
    OvertimeRecord ot,
    TextStyle? labelStyle,
  ) {
    final num? totalMinutes = num.tryParse(ot.totalTime ?? '');
    return DetailInfoRow(
      icon: Icons.more_time_outlined,
      label: '加班記錄',
      value:
          '${ot.remark ?? 'N/A'} (${CalendarUtils.formatMinutes(totalMinutes)})',
      valueColor: Colors.red.shade600,
      valueStyle: context.textTheme.bodyMedium?.copyWith(
        color: Colors.red.shade600,
        fontSize: context.sp(14),
      ),
      labelStyle: labelStyle,
      useCompactFlex: true,
    );
  }
}
