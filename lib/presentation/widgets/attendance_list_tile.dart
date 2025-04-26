import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/theme_extensions.dart';
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
        // Use context from dialog builder for dialog-specific theme data
        final dialogTheme = Theme.of(dialogContext);
        final dialogColorScheme = dialogTheme.colorScheme;
        final dialogTextTheme = dialogTheme.textTheme;

        return AlertDialog(
          // Use a more subtle background
          backgroundColor: dialogColorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.r(16)),
          ),
          titlePadding: EdgeInsets.only(
            top: context.h(24),
            bottom: context.h(8),
          ),
          contentPadding: EdgeInsets.zero,
          title: Text(
            dialogTitle,
            textAlign: TextAlign.center,
            style: dialogTextTheme.titleLarge?.copyWith(
              color: dialogColorScheme.primary,
              fontSize: context.sp(22),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.w(20), 0, context.w(20), 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: tileData.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.r(12)),
                        border: Border.all(
                          color: tileData.statusColor.withValues(alpha: 0.3),
                          width: context.w(1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tileData.statusIcon,
                            size: context.r(14),
                            color: tileData.statusColor,
                          ),
                          Gap(context.w(4)),
                          Text(
                            tileData.statusTag,
                            style: dialogTextTheme.labelMedium?.copyWith(
                              color: tileData.statusColor,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                              fontSize: context.sp(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap(context.h(16)),
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
                        style: dialogTextTheme.bodyMedium?.copyWith(
                          fontSize: context.sp(14),
                        ),
                      ),
                    ]),
                  if (tileData.statusTag == '曠職')
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(16)),
                        child: Text(
                          '曠職',
                          style: dialogTextTheme.titleLarge?.copyWith(
                            color: dialogColorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(22),
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
                        padding: EdgeInsets.symmetric(vertical: context.h(16)),
                        child: Text(
                          '無出勤紀錄',
                          style: dialogTextTheme.bodyLarge?.copyWith(
                            color: dialogColorScheme.onSurfaceVariant,
                            fontSize: context.sp(16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actionsPadding: EdgeInsets.only(
            bottom: context.h(8),
            right: context.w(16),
          ),
          actions: [
            TextButton(
              child: Text('關閉', style: TextStyle(fontSize: context.sp(14))),
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
    return [
      Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: context.sp(14),
        ),
      ),
      Gap(context.h(4)),
      Card(
        elevation: 0,
        color: context.colorScheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(context.i(12)),
          child: Column(children: children),
        ),
      ),
      Gap(context.h(12)),
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
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: context.sp(14),
              ),
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
    final leaveRecord = timeoffs.first; // Get only the first record

    return [
      DetailInfoRow(
        icon: Icons.category_outlined,
        label: '請假類別',
        value: leaveRecord.ruleName ?? 'N/A',
        valueColor: context.colorScheme.secondary,
      ),
      DetailInfoRow(
        icon: Icons.access_time_outlined,
        label: '請假時段',
        value: leaveRecord.time ?? '--',
        valueColor: context.colorScheme.secondary,
      ),
      if (leaveRecord.remark != null && leaveRecord.remark!.isNotEmpty)
        DetailInfoRow(
          icon: Icons.notes_outlined,
          label: '請假原因',
          value: leaveRecord.remark ?? 'N/A',
          valueColor: context.colorScheme.secondary,
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
      borderRadius: BorderRadius.circular(context.r(10)), // Match Card shape
      child: Card(
        elevation: 0.5,
        margin: EdgeInsets.symmetric(
          horizontal: context.w(8),
          vertical: context.h(4.5),
        ), // Use context.w/h
        color:
            context
                .colorScheme
                .surfaceContainerHighest, // Use context.colorScheme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(10)), // Use context.r
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(10),
          ), // Use context.w/h
          child: Row(
            children: [
              // Left side: Date and Weekday
              SizedBox(
                width:
                    tileData.showYear
                        ? context.w(80) // Use context.w
                        : context.w(65), // Adjust width if year is shown
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      datePart, // Directly use the formatted date
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            tileData.showYear
                                ? context.sp(13) // Use context.sp
                                : context.sp(16), // Use context.sp
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gap(context.h(3)), // Use context.h
                    Text(
                      weekdayPart, // Use the calculated weekday
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        height: 1.1,
                        fontSize: context.sp(12), // Use context.sp
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: context.w(16), // Use context.w
                thickness: context.w(1), // Use context.w
                indent: context.h(5), // Use context.h
                endIndent: context.h(5), // Use context.h
              ),
              // Middle: Details Column
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: context.w(4), // Use context.w
                  ), // Keep slight indent for details
                  child: contentDetails,
                ),
              ),
              Gap(context.w(8)), // Use context.w
              // Right side: Status Tag (Container)
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: context.w(75), // Minimum width for the status tag
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(4),
                  ), // Use context.w/h
                  decoration: BoxDecoration(
                    color: tileData.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      context.r(12),
                    ), // Use context.r
                    border: Border.all(
                      color: tileData.statusColor.withValues(alpha: 0.3),
                      width: context.w(1), // Use context.w
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center content
                    children: [
                      Icon(
                        tileData.statusIcon,
                        size: context.r(14), // Use context.r
                        color: tileData.statusColor,
                      ),
                      Gap(context.w(4)), // Use context.w
                      Flexible(
                        // Allow text to wrap if needed, though unlikely with minWidth
                        child: Text(
                          tileData.statusTag,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: tileData.statusColor,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            fontSize: context.sp(12), // Use context.sp
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
    return Padding(
      padding: EdgeInsets.only(top: context.h(3)), // Use context.h
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: context.r(15), // Use context.r
            color:
                color?.withValues(alpha: 0.8) ??
                context.colorScheme.secondary.withValues(
                  alpha: 0.7,
                ), // Use context.colorScheme
          ),
          Gap(context.w(5)), // Use context.w
          Expanded(
            child: Text(
              text,
              maxLines: maxLines, // Use passed maxLines
              style: context.textTheme.bodySmall?.copyWith(
                color:
                    color ??
                    context
                        .colorScheme
                        .onSurfaceVariant, // Use context.colorScheme
                height: 1.2, // Adjust line height
                fontSize: context.sp(12), // Use context.sp
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
