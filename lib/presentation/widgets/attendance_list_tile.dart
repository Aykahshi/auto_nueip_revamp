import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/utils/calendar_utils.dart';
import '../../data/models/attendance_details.dart';
import '../screens/calendar_screen.dart';
import './detail_info_row.dart';

/// Renders an attendance record item for the range query list.
/// Tappable to show a detailed dialog.
class AttendanceListTile extends StatelessWidget {
  // Receive the processed data record
  final AttendanceTileData tileData;

  const AttendanceListTile({super.key, required this.tileData});

  // Method to show the details dialog
  Future<void> _showDetailsDialog(BuildContext context) {
    final record = tileData.record;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Format the full date for the dialog title
    String dialogTitleDate = '未知日期';
    String dialogTitleWeekday = '';
    try {
      final dateStringForDialog = record.dateInfo?.date;
      if (dateStringForDialog != null) {
        DateTime? parsedDateForDialog;
        try {
          parsedDateForDialog = DateFormat(
            'yyyy-MM-dd',
          ).parseStrict(dateStringForDialog);
        } catch (_) {
          /* Handle error if needed */
        }
        if (parsedDateForDialog != null) {
          dialogTitleDate = DateFormat(
            'yyyy / M / d',
          ).format(parsedDateForDialog);
          dialogTitleWeekday =
              '(${CalendarUtils.getWeekdayName(parsedDateForDialog.weekday)})';
        }
      }
    } catch (_) {
      /* Handle error if needed */
    }

    final String dialogTitle = '$dialogTitleDate $dialogTitleWeekday';

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Use a more subtle background
          backgroundColor: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          titlePadding: const EdgeInsets.only(top: 24, bottom: 8),
          contentPadding:
              EdgeInsets.zero, // Remove default padding, handle inside content
          title: Text(
            dialogTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
          ),
          content: Container(
            width: double.maxFinite, // Ensure container takes width
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6, // Max height
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tileData.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: tileData.statusColor.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tileData.statusIcon,
                            size: 14,
                            color: tileData.statusColor,
                          ),
                          const Gap(4),
                          Text(
                            tileData.statusTag,
                            style: textTheme.labelMedium?.copyWith(
                              color: tileData.statusColor,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(16),
                  // Display details based on record data
                  if (record.attendance != null &&
                      !record.attendance!.isAbsent &&
                      tileData.statusTag != '無資料')
                    ..._buildSection(
                      context,
                      '出勤資訊',
                      // Pass record.punch back to the helper
                      _buildAttendanceDialogDetails(
                        context,
                        record.attendance!,
                        record.punch,
                      ),
                    ),
                  if (record.timeoff != null && record.timeoff!.isNotEmpty)
                    ..._buildSection(
                      context,
                      '請假記錄',
                      _buildTimeoffDialogDetails(context, record.timeoff!),
                    ),
                  if (record.overtime != null && record.overtime!.isNotEmpty)
                    ..._buildSection(
                      context,
                      '加班記錄',
                      _buildOvertimeDialogDetails(context, record.overtime!),
                    ),
                  if (record.dateInfo?.holiday != null &&
                      record.dateInfo!.holiday!.isNotEmpty &&
                      tileData.statusTag == '假日')
                    ..._buildSection(context, '假日說明', [
                      Text(
                        record.dateInfo!.holiday!,
                        style: textTheme.bodyMedium,
                      ),
                    ]),
                  if (tileData.statusTag == '曠職')
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          '曠職',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (tileData.statusTag == '無資料' &&
                      record.attendance == null &&
                      (record.timeoff?.isEmpty ?? true) &&
                      (record.overtime?.isEmpty ?? true))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          '無出勤紀錄',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 16),
          actions: [
            TextButton(
              child: const Text('關閉'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  // Helper to create a section with title and content widgets
  List<Widget> _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return [
      Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const Gap(4),
      Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(children: children),
        ),
      ),
      const Gap(12), // Space between sections
    ];
  }

  // Helper to build attendance details for the dialog
  List<Widget> _buildAttendanceDialogDetails(
    BuildContext context,
    Attendance attendance,
    PunchData? punch, // Restore PunchData? parameter
  ) {
    // Restore punch time calculation
    final String onPunchTime = punch?.onPunch.firstOrNull?.time ?? '--:--';
    final String offPunchTime = punch?.offPunch.firstOrNull?.time ?? '--:--';
    final String duration = CalendarUtils.formatDuration(
      attendance.duringHour,
      attendance.duringMin,
    );
    // Restore workTime calculation (assuming it's on record)
    final String? workTime = tileData.record.workTime;

    List<Widget> details = [];
    // Restore punch time rows
    if (punch != null &&
        (punch.onPunch.isNotEmpty || punch.offPunch.isNotEmpty)) {
      details.add(
        DetailInfoRow(
          icon: Icons.login_outlined,
          label: '上班打卡',
          value: onPunchTime,
        ),
      );
      details.add(
        DetailInfoRow(
          icon: Icons.logout_outlined,
          label: '下班打卡',
          value: offPunchTime,
        ),
      );
    }
    // Keep duration row
    if (duration != '--' && duration != 'N/A') {
      details.add(
        DetailInfoRow(
          icon: Icons.timer_outlined,
          label: '實際工時',
          value: duration,
        ),
      );
    }
    // Restore workTime row
    if (workTime != null && workTime.isNotEmpty) {
      details.add(
        DetailInfoRow(
          icon: Icons.schedule_outlined,
          label: '工作時間',
          value: workTime,
        ),
      );
    }

    // Restore punch remark logic
    final onPunchRemark =
        punch?.onPunch
            .firstWhere(
              (p) => p.remark != null && p.remark!.isNotEmpty,
              orElse:
                  () => const PunchRecord(
                    date: '',
                    solvedStatus: 0,
                    signStatus: 0,
                    adjustBelong: false,
                    time: '',
                    type: '',
                    remark: null,
                  ),
            )
            .remark;
    final offPunchRemark =
        punch?.offPunch
            .firstWhere(
              (p) => p.remark != null && p.remark!.isNotEmpty,
              orElse:
                  () => const PunchRecord(
                    date: '',
                    solvedStatus: 0,
                    signStatus: 0,
                    adjustBelong: false,
                    time: '',
                    type: '',
                    remark: null,
                  ),
            )
            .remark;
    if (onPunchRemark != null) {
      details.add(
        DetailInfoRow(
          icon: Icons.sticky_note_2_outlined,
          label: '上班備註',
          value: onPunchRemark,
          maxLines: null,
        ),
      );
    }
    if (offPunchRemark != null) {
      details.add(
        DetailInfoRow(
          icon: Icons.sticky_note_2_outlined,
          label: '下班備註',
          value: offPunchRemark,
          maxLines: null,
        ),
      );
    }

    return details.isEmpty
        ? [
          Center(
            child: Text(
              '無有效出勤資訊',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ]
        : details;
  }

  // Helper to build time off details for the dialog (Show only first)
  List<Widget> _buildTimeoffDialogDetails(
    BuildContext context,
    List<TimeOffRecord> timeoffs,
  ) {
    if (timeoffs.isEmpty) return []; // Guard clause
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leaveRecord = timeoffs.first; // Get only the first record

    return [
      DetailInfoRow(
        icon: Icons.category_outlined,
        label: '請假類別',
        value: leaveRecord.ruleName ?? 'N/A',
        valueColor: colorScheme.secondary,
      ),
      DetailInfoRow(
        icon: Icons.access_time_outlined,
        label: '請假時段',
        value: leaveRecord.time ?? '--',
        valueColor: colorScheme.secondary,
      ),
      if (leaveRecord.remark != null && leaveRecord.remark!.isNotEmpty)
        DetailInfoRow(
          icon: Icons.notes_outlined,
          label: '請假原因',
          value: leaveRecord.remark ?? 'N/A',
          valueColor: colorScheme.secondary,
          maxLines: null,
        ),
    ];
  }

  // Helper to build overtime details for the dialog (Show only first)
  List<Widget> _buildOvertimeDialogDetails(
    BuildContext context,
    List<OvertimeRecord> overtimes,
  ) {
    if (overtimes.isEmpty) return []; // Guard clause
    final otRecord = overtimes.first; // Get only the first record
    final num? totalMinutes = num.tryParse(otRecord.totalTime ?? '');

    return [
      DetailInfoRow(
        icon: Icons.more_time_outlined,
        label: '加班時數',
        value: CalendarUtils.formatMinutes(totalMinutes),
        valueColor: Colors.red.shade600,
      ),
      if (otRecord.remark != null && otRecord.remark!.isNotEmpty)
        DetailInfoRow(
          icon: Icons.notes_outlined,
          label: '加班事由',
          value: otRecord.remark!,
          valueColor: Colors.red.shade600,
          maxLines: null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final record = tileData.record;

    // Recompute date parts here as build is called separately
    String datePart = tileData.formattedDate;
    String weekdayPart = '--';
    try {
      final dateStringForWeekday = record.dateInfo?.date;
      if (dateStringForWeekday != null) {
        DateTime? parsedDateForWeekday;
        try {
          parsedDateForWeekday = DateFormat(
            'yyyy-MM-dd',
          ).parseStrict(dateStringForWeekday);
        } catch (_) {
          debugPrint(
            'ListTile: Failed to parse date $dateStringForWeekday for weekday',
          );
        }
        if (parsedDateForWeekday != null) {
          weekdayPart = CalendarUtils.getWeekdayName(
            parsedDateForWeekday.weekday,
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Error processing date for weekday: ${record.dateInfo?.date} - $e',
      );
    }

    // Helper to format punch times
    String getPunchTime(List<PunchRecord>? punches) {
      return punches?.firstOrNull?.time ?? 'N/A';
    }

    // Helper to format duration
    String formatWorkDuration() {
      final attendance = record.attendance;
      if (attendance == null ||
          (attendance.duringHour == 0 && attendance.duringMin == 0)) {
        return 'N/A';
      }
      return CalendarUtils.formatDuration(
        attendance.duringHour,
        attendance.duringMin,
      );
    }

    // Determine content based on status tag
    Widget contentDetails;
    if (tileData.statusTag == '請假') {
      final leave = record.timeoff?.firstOrNull;
      contentDetails = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent excessive height
        children: [
          if (leave != null)
            _buildDetailRow(
              context,
              icon: Icons.category_outlined,
              text: '${leave.ruleName ?? "N/A"} (${leave.time ?? "--"})',
              color: tileData.statusColor,
            ),
          if (leave?.remark != null && leave!.remark!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.notes_outlined,
              text: leave.remark!,
              color: tileData.statusColor,
            ),
        ],
      );
    } else if (tileData.statusTag == '加班') {
      final ot = record.overtime?.firstOrNull;
      contentDetails = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ot != null)
            _buildDetailRow(
              context,
              icon: Icons.more_time_outlined,
              text:
                  '${ot.remark ?? "N/A"} (${CalendarUtils.formatMinutes(num.tryParse(ot.totalTime ?? ''))})',
              color: tileData.statusColor,
            ),
        ],
      );
    } else if (tileData.statusTag == '假日') {
      contentDetails = _buildDetailRow(
        context,
        icon: Icons.auto_awesome,
        text:
            record.dateInfo?.holiday != null &&
                    record.dateInfo!.holiday!.isNotEmpty
                ? record.dateInfo!.holiday!
                : '假日',
        color: tileData.statusColor,
      );
    } else if (tileData.statusTag == '無資料') {
      contentDetails = _buildDetailRow(
        context,
        icon: Icons.help_outline,
        text: '本日無出勤紀錄',
        color: tileData.statusColor.withValues(alpha: 0.7),
      );
    } else {
      // Default: show punch times and duration
      contentDetails = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailRow(
            context,
            icon: Icons.login_outlined,
            text: '上班: ${getPunchTime(record.punch?.onPunch)}',
          ),
          _buildDetailRow(
            context,
            icon: Icons.logout_outlined,
            text: '下班: ${getPunchTime(record.punch?.offPunch)}',
          ),
          if (record.attendance !=
              null) // Only show duration if attendance exists
            _buildDetailRow(
              context,
              icon: Icons.timer_outlined,
              text: '工時: ${formatWorkDuration()}',
            ),
        ],
      );
    }

    return InkWell(
      // Wrap Card with InkWell
      onTap: () => _showDetailsDialog(context), // Call the dialog method
      borderRadius: BorderRadius.circular(10.0), // Match Card shape
      child: Card(
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.5),
        color: colorScheme.surfaceContainerHighest, // Slightly higher contrast
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Left side: Date and Weekday
              SizedBox(
                width:
                    tileData.showYear
                        ? 80
                        : 65, // Adjust width if year is shown
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      datePart, // Directly use the formatted date
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            tileData.showYear
                                ? 13
                                : null, // Slightly smaller if year included
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(3),
                    Text(
                      weekdayPart, // Use the calculated weekday
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const VerticalDivider(
                width: 16,
                thickness: 1,
                indent: 5,
                endIndent: 5,
              ),
              // Middle: Details Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                  ), // Keep slight indent for details
                  child: contentDetails,
                ),
              ),
              const Gap(8), // Add some spacing before the tag
              // Right side: Status Tag (Container)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 75, // Minimum width for the status tag
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: tileData.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: tileData.statusColor.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center content
                    children: [
                      Icon(
                        tileData.statusIcon,
                        size: 14,
                        color: tileData.statusColor,
                      ),
                      const Gap(4),
                      Flexible(
                        // Allow text to wrap if needed, though unlikely with minWidth
                        child: Text(
                          tileData.statusTag,
                          style: textTheme.labelMedium?.copyWith(
                            color: tileData.statusColor,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis, // Handle overflow
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated helper widget with new color logic
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color, // Specific color for status (like leave, OT)
    int? maxLines = 1, // Allow specifying maxLines
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Use provided color for both icon and text if available,
    // otherwise, use default theme colors.
    final Color iconColor =
        color?.withValues(alpha: 0.8) ??
        colorScheme.secondary.withValues(alpha: 0.7);
    final Color textColor = color ?? colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: iconColor, // Apply determined icon color
          ),
          const Gap(5),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines, // Use passed maxLines
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor, // Apply determined text color
                height: 1.2, // Adjust line height
                overflow:
                    maxLines == 1
                        ? TextOverflow.ellipsis
                        : null, // Only ellipsis if maxLines is 1
              ),
            ),
          ),
        ],
      ),
    );
  }
}
