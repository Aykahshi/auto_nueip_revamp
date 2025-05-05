import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../data/models/leave_record.dart';

class LeaveRecordListTile extends StatelessWidget {
  final LeaveRecord record;
  final VoidCallback onTap;

  const LeaveRecordListTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  // --- Helper Functions (Status, Formatting) ---
  Color _getStatusColor(num signStatus, BuildContext context) {
    if (signStatus == 2) return Colors.green.shade600; // Approved
    if (signStatus == 3) return context.colorScheme.error; // Rejected
    return Colors.orange.shade700; // Pending or other
  }

  IconData _getStatusIcon(num signStatus) {
    if (signStatus == 2) return Icons.check_circle_outline; // Approved
    if (signStatus == 3) return Icons.cancel_outlined; // Rejected
    return Icons.hourglass_empty_outlined; // Pending or other
  }

  String _getStatusText(num signStatus) {
    if (signStatus == 2) return '核准';
    if (signStatus == 3) return '駁回';
    if (signStatus < 2) return '簽核中';
    return '未知';
  }

  String _formatDateRange(String? startTime, String? endTime) {
    try {
      final start =
          startTime != null
              ? DateFormat('yyyy-MM-dd HH:mm').parse(startTime)
              : null;
      final end =
          endTime != null
              ? DateFormat('yyyy-MM-dd HH:mm').parse(endTime)
              : null;

      if (start != null && end != null) {
        final startDateStr = DateFormat('MM/dd').format(start);
        final endDateStr = DateFormat('MM/dd').format(end);
        final startTimeStr = DateFormat('HH:mm').format(start);
        final endTimeStr = DateFormat('HH:mm').format(end);

        if (DateUtils.isSameDay(start, end)) {
          // Same day: 04/01 09:00 - 18:00
          return '$startDateStr $startTimeStr - $endTimeStr';
        } else {
          // Different days: 04/01 09:00 - 04/02 18:00
          return '$startDateStr $startTimeStr - $endDateStr $endTimeStr';
        }
      } else if (start != null) {
        // Only start date available (should not happen often for leave)
        return '${DateFormat('MM/dd HH:mm').format(start)} - 未知';
      }
      return '日期錯誤';
    } catch (e) {
      debugPrint('Error parsing leave date range in tile: $e');
      return '日期格式錯誤';
    }
  }

  // --- New Helper for Icon Rows ---
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: context.h(3)),
      child: Row(
        children: [
          Icon(
            icon,
            size: context.r(14),
            color: context.colorScheme.secondary.withValues(alpha: 0.8),
          ),
          Gap(context.w(5)),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontSize: context.sp(12),
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  // --- End Helpers ---

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(record.signStatus, context);
    final statusIcon = _getStatusIcon(record.signStatus);
    final statusText = _getStatusText(record.signStatus);
    final dateRange = _formatDateRange(record.startTime, record.endTime);
    final totalTime = record.formattedTotalHours;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(10)),
      child: Card(
        elevation: 0.8,
        margin: EdgeInsets.symmetric(
          vertical: context.h(5),
          horizontal: context.w(8),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(10)),
        ),
        color: context.colorScheme.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(context.i(12)),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Align items vertically center
            children: [
              // Left: Status Icon
              Icon(statusIcon, color: statusColor, size: context.r(28)),
              Gap(context.w(12)),
              // Middle: Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center, // Center column content vertically
                  children: [
                    Text(
                      record.ruleName ?? '未知假別',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: context.sp(15),
                        fontWeight: FontWeight.w500,
                        height: 1.2, // Adjust line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(context.h(4)),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_month_outlined,
                      text: '請假時間：$dateRange',
                    ),
                    if (totalTime != '--') // Only show if totalTime is valid
                      _buildInfoRow(
                        context,
                        icon: Icons.hourglass_empty_outlined,
                        text: '請假時數： $totalTime',
                      ),
                  ],
                ),
              ),
              Gap(context.w(8)),
              // Right: Status Tag
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(10), // More padding
                  vertical: context.h(5), // More padding
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    context.r(10),
                  ), // Larger radius
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
