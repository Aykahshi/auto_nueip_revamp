import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// A widget that displays the SfCalendar with specific configurations.
class CalendarViewWidget extends StatelessWidget {
  final DateTime initialDate;
  final Set<DateTime> holidays;
  final Function(DateTime) onSelectionChanged;
  final CalendarController controller;

  const CalendarViewWidget({
    required this.initialDate,
    required this.holidays,
    required this.onSelectionChanged,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());

    return Card(
      margin: const EdgeInsets.all(
        8.0,
      ), // Keep card margin for visual separation
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
            textStyle: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.transparent,
          ),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            backgroundColor: Colors.transparent,
          ),
          cellBorderColor: Colors.transparent,
          todayHighlightColor:
              colorScheme.primary, // Keep default today highlight
          selectionDecoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: colorScheme.primary, width: 1.5),
            shape: BoxShape.circle,
          ),
          onSelectionChanged: (CalendarSelectionDetails details) {
            if (details.date is DateTime) {
              onSelectionChanged(
                details.date as DateTime,
              ); // Pass selected date up
            }
          },
          monthCellBuilder: (BuildContext context, MonthCellDetails details) {
            final cellDate = DateUtils.dateOnly(details.date);
            final isToday = DateUtils.isSameDay(cellDate, today);
            // Check selection based on controller's selected date
            final isSelected =
                controller.selectedDate != null &&
                DateUtils.isSameDay(cellDate, controller.selectedDate!);
            final isHoliday = holidays.contains(cellDate);
            final bool isOutsideMonth =
                cellDate.month != controller.displayDate?.month;

            Color textColor =
                isOutsideMonth
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurface;
            FontWeight fontWeight = FontWeight.normal;
            BoxDecoration? decoration;

            if (isSelected) {
              decoration = BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: colorScheme.primary, width: 1.5),
                shape: BoxShape.circle,
              );
              textColor = isHoliday ? colorScheme.error : colorScheme.primary;
              fontWeight = FontWeight.bold;
            } else if (isToday) {
              decoration = BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              );
              textColor = isHoliday ? colorScheme.error : colorScheme.primary;
              fontWeight = FontWeight.bold;
            } else if (isHoliday && !isOutsideMonth) {
              textColor = colorScheme.error;
            }

            return Container(
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(
                details.date.day.toString(),
                style: TextStyle(color: textColor, fontWeight: fontWeight),
              ),
            );
          },
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
