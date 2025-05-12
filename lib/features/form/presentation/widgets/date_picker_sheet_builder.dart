import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/theme_extensions.dart';

/// Builds the content for the date picker modal bottom sheet.
Widget buildDatePickerSheetContent({
  required BuildContext sheetContext,
  required bool isStartDate,
  required DateTime? initialDate,
  required DateTime?
  selectedStartDateForMinDate, // Pass start date for minDate logic
  required Function(DateTime?) onSelectionConfirmed,
}) {
  DateTime? currentSheetSelection = initialDate;
  final sheetTheme = sheetContext.theme;
  final sheetColorScheme = sheetTheme.colorScheme;
  final safeAreaBottom = MediaQuery.viewInsetsOf(sheetContext).bottom;

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setSheetState) {
      return Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: context.vh * 0.5),
          decoration: BoxDecoration(
            color: sheetColorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(20)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Drag handle
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.h(10)),
                child: Container(
                  width: context.w(40),
                  height: context.h(5),
                  decoration: BoxDecoration(
                    color: sheetColorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(context.r(10)),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                child: Text(
                  isStartDate ? "選擇開始日期" : "選擇結束日期",
                  style: sheetTheme.textTheme.titleLarge?.copyWith(
                    color: sheetColorScheme.onSurface,
                    fontSize: context.sp(22),
                  ),
                ),
              ),
              Divider(height: context.h(16), thickness: context.w(0.5)),
              // Date Picker
              Flexible(
                child: SfDateRangePicker(
                  initialSelectedDate: initialDate,
                  view: DateRangePickerView.month,
                  selectionMode: DateRangePickerSelectionMode.single,
                  onSelectionChanged: (args) {
                    if (args.value is DateTime) {
                      setSheetState(() {
                        currentSheetSelection = args.value;
                      });
                    }
                  },
                  backgroundColor: Colors.transparent,
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    firstDayOfWeek: 1,
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(
                      textStyle: TextStyle(
                        color: sheetColorScheme.onSurfaceVariant,
                        fontSize: context.sp(12),
                      ),
                    ),
                  ),
                  headerStyle: DateRangePickerHeaderStyle(
                    backgroundColor: Colors.transparent,
                    textAlign: TextAlign.center,
                    textStyle: sheetTheme.textTheme.titleMedium?.copyWith(
                      color: sheetColorScheme.onSurface,
                      fontSize: context.sp(16),
                    ),
                  ),
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: TextStyle(
                      color: sheetColorScheme.onSurface,
                      fontSize: context.sp(14),
                    ),
                    todayTextStyle: TextStyle(
                      color: sheetColorScheme.primary,
                      fontSize: context.sp(14),
                    ),
                    todayCellDecoration: BoxDecoration(
                      border: Border.all(color: sheetColorScheme.primary),
                      shape: BoxShape.circle,
                    ),
                    disabledDatesTextStyle: TextStyle(
                      color: sheetColorScheme.outline.withValues(alpha: 0.5),
                      fontSize: context.sp(14),
                    ),
                  ),
                  selectionTextStyle: TextStyle(
                    color: sheetColorScheme.onPrimary,
                    fontSize: context.sp(14),
                  ),
                  selectionColor: sheetColorScheme.primary,
                  minDate:
                      isStartDate
                          ? DateTime(2010)
                          : (selectedStartDateForMinDate ??
                              DateTime(2010)), // Use passed start date
                  maxDate: DateTime(2030),
                  showNavigationArrow: true,
                ),
              ),
              // Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: sheetColorScheme.secondary,
                          fontSize: context.sp(14),
                        ),
                      ),
                      onPressed: () => sheetContext.router.pop(),
                    ),
                    Gap(context.w(8)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sheetColorScheme.primary,
                        foregroundColor: sheetColorScheme.onPrimary,
                      ),
                      child: const Text('確定'),
                      onPressed: () {
                        // Pass the final selection back via callback
                        onSelectionConfirmed(currentSheetSelection);
                        sheetContext.router.pop();
                      },
                    ),
                  ],
                ),
              ),
              Gap(context.h(10)),
            ],
          ),
        ),
      );
    },
  );
}
