import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final commonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ); // Define common shape
    final buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: theme.textTheme.labelMedium,
      shape: commonShape, // Apply common shape
    );
    final outlinedButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: theme.textTheme.labelMedium,
      foregroundColor: colorScheme.error,
      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
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
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onSelectRange,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: colorScheme.surface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          dateRangeText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onClear,
                  style: outlinedButtonStyle,
                  child: const Text('清除查詢'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onQuery,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('查詢'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
