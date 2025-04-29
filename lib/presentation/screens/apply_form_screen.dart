import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:syncfusion_flutter_datepicker/datepicker.dart'; // Import SF Date Picker

import '../../core/extensions/theme_extensions.dart';
import 'form_screen.dart'; // Assuming FormHistoryType is here

@RoutePage()
class ApplyFormScreen extends StatefulWidget {
  final FormHistoryType formType;

  const ApplyFormScreen({required this.formType, super.key});

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  // State variables for selected date and time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Date and Time formatters
  final DateFormat _dateFormatter = DateFormat('yyyy / MM / dd');
  // Time formatter handled by TimeOfDay.format

  // --- Date Picker Logic ---
  void _showDatePickerSheet() {
    DateTime? initialDate = _selectedDate ?? DateTime.now();
    DateTime? currentSheetSelection = _selectedDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final sheetTheme = sheetContext.theme;
        final sheetColorScheme = sheetTheme.colorScheme;
        final safeAreaBottom = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return StatefulBuilder(
          // Use StatefulBuilder to update picker state inside the sheet
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: safeAreaBottom),
              child: Container(
                constraints: BoxConstraints(
                  // Adjust height to match calendar screen
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                decoration: BoxDecoration(
                  color: sheetColorScheme.surfaceContainer,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.r(20)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                      child: Text(
                        widget.formType == FormHistoryType.leave
                            ? "選擇請假日期"
                            : "選擇請款申請日期",
                        style: sheetTheme.textTheme.titleLarge?.copyWith(
                          color: sheetColorScheme.onSurface,
                          fontSize: context.sp(22),
                        ),
                      ),
                    ),
                    Divider(height: context.h(16), thickness: context.w(0.5)),
                    Flexible(
                      child: SfDateRangePicker(
                        initialSelectedDate: initialDate,
                        view: DateRangePickerView.month,
                        selectionMode: DateRangePickerSelectionMode.single,
                        onSelectionChanged: (args) {
                          if (args.value is DateTime) {
                            // Update sheet state for immediate visual feedback if needed
                            // (though not strictly necessary for final selection)
                            setSheetState(() {
                              currentSheetSelection = args.value;
                            });
                          }
                        },
                        // --- Styling (copied from history screen, adjust as needed) ---
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
                            color: sheetColorScheme.outline.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: context.sp(14),
                          ),
                        ),
                        selectionTextStyle: TextStyle(
                          color: sheetColorScheme.onPrimary,
                          fontSize: context.sp(14),
                        ),
                        selectionColor: sheetColorScheme.primary,
                        minDate: DateTime(2010),
                        maxDate: DateTime(2030),
                        showNavigationArrow: true,
                      ),
                    ),
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
                              if (currentSheetSelection != null) {
                                // Update the main state only on confirmation
                                setState(() {
                                  _selectedDate = DateUtils.dateOnly(
                                    currentSheetSelection!,
                                  );
                                });
                              }
                              sheetContext.router.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                    Gap(context.h(10)), // Reduced gap
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Time Picker Logic ---
  Future<void> _showTimePickerSheet() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final colorScheme = context.colorScheme;
        final textTheme = context.textTheme;
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor:
                  colorScheme.surfaceContainerLow, // Use lower surface for base
              // Dial styling
              dialBackgroundColor: colorScheme.surfaceContainer,
              dialHandColor: colorScheme.primary,
              dialTextColor: WidgetStateColor.resolveWith(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? colorScheme
                            .onPrimary // Text on dial (selected number)
                        : colorScheme.onSurfaceVariant,
              ), // Text on dial (unselected number)
              // Hour/Minute display (top left)
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? colorScheme
                            .primary // Selected Hour/Minute text
                        : colorScheme.onSurfaceVariant,
              ), // Unselected Hour/Minute text
              hourMinuteColor: WidgetStateColor.resolveWith(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : colorScheme.surfaceContainerHighest,
              ), // Background for unselected HM
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              // Day Period (AM/PM) styling
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? colorScheme
                            .onPrimary // Selected AM/PM text
                        : colorScheme.onSurfaceVariant,
              ), // Unselected AM/PM text
              dayPeriodColor: WidgetStateColor.resolveWith(
                (Set<WidgetState> states) =>
                    states.contains(WidgetState.selected)
                        ? colorScheme
                            .primary // Selected AM/PM background
                        : colorScheme.surfaceContainerHighest,
              ), // Unselected AM/PM background
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
                side: BorderSide.none, // Remove border
              ),
              dayPeriodBorderSide: BorderSide(
                color: colorScheme.outline.withValues(
                  alpha: 0.3,
                ), // Subtle border color
                width: 1,
              ),
              // Input mode styling
              inputDecorationTheme: InputDecorationTheme(
                border: InputBorder.none,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: context.w(12)),
                labelStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              // General shape and text styles
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  context.r(24),
                ), // Slightly larger radius
              ),
              hourMinuteTextStyle: textTheme.displayLarge?.copyWith(
                fontSize: context.sp(48),
                fontWeight: FontWeight.w500, // Reduced weight
              ),
              dayPeriodTextStyle: textTheme.labelMedium?.copyWith(
                fontSize: context.sp(12),
                fontWeight: FontWeight.w600,
              ),
              helpTextStyle: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: context.sp(14),
              ),
            ),
            // Button styling
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                textStyle: textTheme.labelLarge?.copyWith(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.bold,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.formType == FormHistoryType.leave ? '申請請假單' : '申請請款單';

    // Format selected date/time for display
    final String displayDate =
        _selectedDate != null ? _dateFormatter.format(_selectedDate!) : '請選擇日期';
    final String displayTime =
        _selectedTime != null
            ? _selectedTime!.format(context) // Use locale-aware formatting
            : '選擇時間'; // Shorter prompt for time

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 1,
        leading: const AutoLeadingButton(),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.i(16)),
        child: Column(
          children: [
            // --- Date and Time Selection Area ---
            Card(
              elevation: 1,
              margin: EdgeInsets.zero, // Remove default margin
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.i(12)),
                child: Column(
                  children: [
                    _buildPickerRow(
                      context: context,
                      icon: Icons.calendar_month_outlined,
                      label: displayDate,
                      onTap: _showDatePickerSheet,
                      isSelected: _selectedDate != null,
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    Divider(height: context.h(16), thickness: 0.5),
                    _buildPickerRow(
                      context: context,
                      icon: Icons.access_time_rounded,
                      label: displayTime,
                      onTap: _showTimePickerSheet,
                      isSelected: _selectedTime != null,
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                    // Add other form fields here later (Leave Type, Amount, etc.)
                  ],
                ),
              ),
            ),
            Gap(context.h(24)),
            // --- Placeholder for other form fields ---
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_outlined,
                      size: context.r(50), // Slightly smaller icon
                      color: context.colorScheme.outline.withValues(alpha: 0.7),
                    ),
                    Gap(context.h(12)),
                    Text(
                      '其他表單欄位 (待新增)',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Disable button if date/time is not selected (optional)
                onPressed:
                    (_selectedDate != null && _selectedTime != null)
                        ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('提交功能開發中')),
                          );
                        }
                        : null, // Disable if date or time is missing
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.h(16)),
                  textStyle: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(16),
                  ),
                ),
                child: const Text('提交申請'),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a row for date/time picker trigger
  Widget _buildPickerRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.r(4)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.h(10),
          horizontal: context.w(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.secondary,
              size: context.r(22),
            ),
            Gap(context.w(12)),
            Expanded(
              child: Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: context.sp(16),
                  color:
                      isSelected
                          ? context.colorScheme.onSurface
                          : context.colorScheme.outline,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.r(16),
              color: context.colorScheme.outline.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
