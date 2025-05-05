import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../core/extensions/theme_extensions.dart'; // Import theme extension

/// A widget that displays the SfCalendar with specific configurations.
class CalendarViewWidget extends StatelessWidget {
  final DateTime initialDate;
  final Set<DateTime> holidays;
  final Function(DateTime) onSelectionChanged;
  final CalendarController controller;
  final DateTime? selectedDate;

  const CalendarViewWidget({
    required this.initialDate,
    required this.holidays,
    required this.onSelectionChanged,
    required this.controller,
    required this.selectedDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    return Card(
      margin: EdgeInsets.all(context.i(8)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.i(8)),
        child: SfCalendar(
          controller: controller,
          view: CalendarView.month,
          initialSelectedDate: initialDate,
          initialDisplayDate: initialDate,
          monthViewSettings: const MonthViewSettings(
            showTrailingAndLeadingDates: true,
            numberOfWeeksInView: 6, // Ensure consistent height
          ),
          headerStyle: CalendarHeaderStyle(
            textAlign: TextAlign.center,
            textStyle: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: context.sp(22),
            ),
            backgroundColor: Colors.transparent,
          ),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurfaceVariant,
              fontSize: context.sp(12),
            ),
            backgroundColor: Colors.transparent,
          ),
          cellBorderColor: Colors.transparent,
          todayHighlightColor: context.colorScheme.primary,
          selectionDecoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: context.colorScheme.primary,
              width: context.w(1.5),
            ),
            shape: BoxShape.circle,
          ),
          onSelectionChanged: (CalendarSelectionDetails details) {
            if (details.date is DateTime) {
              onSelectionChanged(details.date as DateTime);
            }
          },
          monthCellBuilder: (BuildContext context, MonthCellDetails details) {
            final cellDate = DateUtils.dateOnly(details.date);
            final isToday = DateUtils.isSameDay(cellDate, today);
            final isSelected =
                selectedDate != null &&
                DateUtils.isSameDay(cellDate, selectedDate!);
            final isHoliday = holidays.contains(cellDate);
            final bool isOutsideMonth =
                cellDate.month != controller.displayDate?.month;

            Color textColor = context.colorScheme.onSurface; // Default
            FontWeight fontWeight = FontWeight.normal;
            BoxDecoration? decoration;

            if (isOutsideMonth) {
              // Style for dates outside the current month
              textColor = context.colorScheme.onSurface.withValues(alpha: 0.38);
              fontWeight = FontWeight.normal;
              decoration = null; // No special decoration
            } else {
              // --- Styles for dates within the current month ---
              // Default for inside month
              textColor = context.colorScheme.onSurface;
              fontWeight = FontWeight.normal;
              decoration = null;

              // Apply Holiday style
              if (isHoliday) {
                textColor = context.colorScheme.error;
              }

              // Apply Today style (overrides Holiday text color)
              if (isToday) {
                textColor = context.colorScheme.primary;
                fontWeight = FontWeight.bold;
                decoration = BoxDecoration(
                  color: context.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                );
              }

              // Apply Selected style (overrides Today and Holiday text color)
              if (isSelected) {
                textColor = context.colorScheme.primary;
                fontWeight = FontWeight.bold;
                // Apply border, keep today's background if applicable
                decoration = (decoration ?? const BoxDecoration()).copyWith(
                  border: Border.all(
                    color: context.colorScheme.primary,
                    width: context.w(1.5),
                  ),
                  shape: BoxShape.circle,
                  // Keep today's background color, otherwise transparent
                  color: isToday ? decoration?.color : Colors.transparent,
                );
              }
            }

            return Container(
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(
                details.date.day.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: context.sp(14),
                ),
              ),
            );
          },
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
