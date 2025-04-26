import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/extensions/theme_extensions.dart'; // Import theme extension

class FilterArea extends StatelessWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final VoidCallback onSelectRange;
  final VoidCallback onSetYesterday;
  final VoidCallback onSetToday;
  final VoidCallback onSetThisWeek;
  final VoidCallback onSetThisMonth;
  final VoidCallback onClear;
  final VoidCallback onQuery;

  const FilterArea({
    super.key, // Add key
    this.selectedStartDate,
    this.selectedEndDate,
    required this.onSelectRange,
    required this.onSetYesterday,
    required this.onSetToday,
    required this.onSetThisWeek,
    required this.onSetThisMonth,
    required this.onClear,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    final commonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.r(8)), // Use context.r
    ); // Define common shape
    final buttonStyle = ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(8),
      ), // Use context.w/h
      textStyle: context.textTheme.labelMedium?.copyWith(
        fontSize: context.sp(12), // Use context.sp
      ),
      shape: commonShape, // Apply common shape
    );
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(8),
      ), // Use context.w/h
      textStyle: context.textTheme.labelMedium?.copyWith(
        fontSize: context.sp(12), // Use context.sp
      ),
      foregroundColor: context.colorScheme.error,
      side: BorderSide(
        color: context.colorScheme.error.withValues(alpha: 0.5),
        width: context.w(1),
      ), // Use context.w for width
      shape: commonShape, // Apply common shape
    );

    String dateRangeText;
    if (selectedStartDate == null) {
      dateRangeText = '點此選擇日期區間';
    } else if (selectedEndDate == null ||
        selectedStartDate == selectedEndDate) {
      dateRangeText =
          '${selectedStartDate!.year}/${selectedStartDate!.month}/${selectedStartDate!.day}';
    } else {
      dateRangeText =
          '${selectedStartDate!.year}/${selectedStartDate!.month}/${selectedStartDate!.day} - ${selectedEndDate!.year}/${selectedEndDate!.month}/${selectedEndDate!.day}';
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.0,
      shape: const RoundedRectangleBorder(),
      color: context.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: EdgeInsets.all(context.i(12)), // Use context.i
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onSelectRange,
              borderRadius: BorderRadius.circular(
                context.r(8),
              ), // Use context.r
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ), // Use context.w/h
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    context.r(8),
                  ), // Use context.r
                  color: context.colorScheme.surface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: context.r(20), // Use context.r
                          color: context.colorScheme.primary,
                        ),
                        SizedBox(width: context.w(12)), // Use context.w
                        Text(
                          dateRangeText,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: context.sp(16), // Use context.sp
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: context.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(10)), // Use context.h
            Wrap(
              spacing: context.w(8), // Use context.w
              runSpacing: context.h(8), // Use context.h
              children: [
                ElevatedButton(
                  onPressed: onSetYesterday,
                  style: buttonStyle,
                  child: const Text('昨日'),
                ),
                ElevatedButton(
                  onPressed: onSetToday,
                  style: buttonStyle,
                  child: const Text('本日'),
                ),
                ElevatedButton(
                  onPressed: onSetThisWeek,
                  style: buttonStyle,
                  child: const Text('本週'),
                ),
                ElevatedButton(
                  onPressed: onSetThisMonth,
                  style: buttonStyle,
                  child: const Text('本月'),
                ),
              ],
            ),
            SizedBox(height: context.h(10)), // Use context.h
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onClear,
                  style: outlinedButtonStyle,
                  child: const Text('清除查詢'),
                ),
                SizedBox(width: context.w(8)), // Use context.w
                ElevatedButton.icon(
                  onPressed: onQuery,
                  icon: Icon(
                    Icons.search,
                    size: context.r(18),
                  ), // Use context.r
                  label: Text(
                    '查詢',
                    style: TextStyle(
                      fontSize: context.sp(14),
                    ), // Use context.sp
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    foregroundColor: context.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(10),
                    ), // Use context.w/h
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
