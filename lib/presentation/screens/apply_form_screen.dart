import 'dart:io'; // Import dart:io for File

import 'package:auto_route/auto_route.dart';
import 'package:dropdown_button2/dropdown_button2.dart'; // Import dropdown_button2 stable
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:syncfusion_flutter_datepicker/datepicker.dart'; // Import SF Date Picker

import '../../core/extensions/theme_extensions.dart';
import 'form_screen.dart'; // Assuming FormHistoryType is here

// --- Re-add Placeholder Data (Replace with actual models and data fetching) ---
class LeaveRule {
  final String id;
  final String name;

  LeaveRule({required this.id, required this.name});

  // Optional: For comparison in DropdownButton2
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveRule && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return name;
  }
}

class Employee {
  final String id;
  final String name;
  final String department; // Optional: for grouping/display

  Employee({required this.id, required this.name, required this.department});

  // Optional: For comparison in DropdownButton2
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '$name ($department)'; // For display in dropdown
  }
}
// --- End Re-add Placeholder Data ---

@RoutePage()
class ApplyFormScreen extends StatefulWidget {
  final FormHistoryType formType;

  const ApplyFormScreen({required this.formType, super.key});

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  // Form state variables
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  String? _selectedLeaveRuleId;
  // Employee? _selectedAgent; // Revert Employee object for agent
  // final TextEditingController _agentController =
  //     TextEditingController(); // Revert back to agent controller
  Employee? _selectedAgent; // Use Employee object for agent
  final TextEditingController _agentSearchController =
      TextEditingController(); // Re-add search controller
  final TextEditingController _remarkController = TextEditingController();
  List<File> _selectedFiles = [];
  Duration? _calculatedDuration;

  // --- Re-add Placeholder Data (Simulate API fetch) ---
  // Replace with actual data fetched from NueipService via Presenter/Bloc
  final List<LeaveRule> _leaveRules = [
    LeaveRule(id: 'rule_1', name: '特休假 (Annual Leave)'),
    LeaveRule(id: 'rule_2', name: '普通傷病假 (Sick Leave)'),
    LeaveRule(id: 'rule_3', name: '事假 (Personal Leave)'),
    LeaveRule(id: 'rule_4', name: '婚假 (Marriage Leave)'),
    LeaveRule(id: 'rule_5', name: '喪假 (Funeral Leave)'),
    LeaveRule(id: 'rule_6', name: '公假 (Official Leave)'),
  ];

  final List<Employee> _employees = [
    Employee(id: 'EMP001', name: '王大明', department: '研發部'),
    Employee(id: 'EMP002', name: '陳小美', department: '研發部'),
    Employee(id: 'EMP003', name: '林志強', department: '業務部'),
    Employee(id: 'EMP004', name: '黃玲玲', department: '業務部'),
    Employee(id: 'EMP005', name: '張建宏', department: '管理部'),
  ];
  // --- End Re-add Placeholder Data ---

  // --- Text Editing Controllers ---
  @override
  void dispose() {
    _agentSearchController.dispose(); // Dispose agent search controller
    // _agentController.dispose(); // No longer using original agent controller
    _remarkController.dispose();
    super.dispose();
  }

  // --- Date and Time formatters ---
  final DateFormat _dateFormatter = DateFormat('yyyy / MM / dd');
  // Time formatter handled by TimeOfDay.format

  // --- Combined DateTime getter ---
  DateTime? get _startDateTime {
    if (_selectedStartDate == null || _selectedStartTime == null) return null;
    return DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );
  }

  DateTime? get _endDateTime {
    if (_selectedEndDate == null || _selectedEndTime == null) return null;
    return DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );
  }

  // --- Duration Calculation ---
  void _calculateAndSetDuration() {
    if (_startDateTime != null && _endDateTime != null) {
      if (_endDateTime!.isAfter(_startDateTime!)) {
        setState(() {
          _calculatedDuration = _endDateTime!.difference(_startDateTime!);
        });
      } else {
        // Handle invalid range (end before start) - show 0 or an error
        setState(() {
          _calculatedDuration = Duration.zero;
        });
        // Optionally show a snackbar or error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('結束時間必須晚於開始時間'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      setState(() {
        _calculatedDuration = null; // Reset if dates/times are incomplete
      });
    }
  }

  // --- Date Picker Logic (Modified for Start/End) ---
  void _showDatePickerSheet({required bool isStartDate}) {
    DateTime? initialDate =
        (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    DateTime? currentSheetSelection =
        isStartDate ? _selectedStartDate : _selectedEndDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final sheetTheme = sheetContext.theme;
        final sheetColorScheme = sheetTheme.colorScheme;
        final safeAreaBottom = MediaQuery.viewInsetsOf(sheetContext).bottom;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: safeAreaBottom),
              child: Container(
                constraints: BoxConstraints(
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
                        isStartDate ? "選擇開始日期" : "選擇結束日期", // Dynamic title
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
                            setSheetState(() {
                              currentSheetSelection = args.value;
                            });
                          }
                        },
                        // --- Styling ---
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
                        // Set min/max dynamically if needed based on start/end
                        minDate: isStartDate ? DateTime(2010) : null,
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
                                setState(() {
                                  if (isStartDate) {
                                    _selectedStartDate = DateUtils.dateOnly(
                                      currentSheetSelection!,
                                    );
                                    // Reset end date if it's before new start date
                                    if (_selectedEndDate != null &&
                                        _selectedEndDate!.isBefore(
                                          _selectedStartDate!,
                                        )) {
                                      _selectedEndDate = null;
                                      _selectedEndTime =
                                          null; // Also reset time
                                    }
                                  } else {
                                    _selectedEndDate = DateUtils.dateOnly(
                                      currentSheetSelection!,
                                    );
                                  }
                                  _calculateAndSetDuration(); // Recalculate duration
                                });
                              }
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
      },
    );
  }

  // --- Time Picker Logic (Modified for Start/End) ---
  Future<void> _showTimePickerSheet({required bool isStartTime}) async {
    final TimeOfDay initialTime =
        (isStartTime ? _selectedStartTime : _selectedEndTime) ??
        TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final colorScheme = context.colorScheme;
        final textTheme = context.textTheme;
        // --- Time Picker Theme (Keep existing) ---
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
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
        _calculateAndSetDuration(); // Recalculate duration
      });
    }
  }

  // --- File Picker Logic ---
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Allow multiple files based on API
        type: FileType.any, // Or specify types like FileType.image
      );

      if (result != null) {
        setState(() {
          // Convert PlatformFile to File - note: path might be null on web
          _selectedFiles =
              result.paths
                  .where((path) => path != null)
                  .map((path) => File(path!))
                  .toList();
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      // Handle error
      debugPrint('Error picking files: $e');
      // Add mounted check before using context across async gap
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('檔案選擇失敗: ${e.toString()}')));
    }
  }

  // --- Form Validation ---
  bool get _isFormValid {
    // Add checks for all required fields based on `sendLeaveForm`
    return _selectedStartDate != null &&
        _selectedStartTime != null &&
        _selectedEndDate != null &&
        _selectedEndTime != null &&
        _calculatedDuration != null &&
        _calculatedDuration! > Duration.zero && // Ensure duration is positive
        _selectedLeaveRuleId != null && // Check if leave type is selected
        // _agentController.text.isNotEmpty && // Revert back to checking agent controller text
        _selectedAgent != null && // Check if agent is selected
        _remarkController.text.isNotEmpty; // Check if remark is entered
    // File check is optional based on API requirements
  }

  // --- Format Duration ---
  String _formatDuration(Duration? duration) {
    if (duration == null) return '請選擇起始時間';
    if (duration == Duration.zero) return '0 小時 0 分鐘';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours 小時 $minutes 分鐘';
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.formType == FormHistoryType.leave
            ? '申請請假單'
            : '申請請款單'; // Assume請款單 later

    // Format selected date/time for display
    final String displayStartDate =
        _selectedStartDate != null
            ? _dateFormatter.format(_selectedStartDate!)
            : '選擇開始日期';
    final String displayStartTime =
        _selectedStartTime != null
            ? _selectedStartTime!.format(context)
            : '選擇開始時間';
    final String displayEndDate =
        _selectedEndDate != null
            ? _dateFormatter.format(_selectedEndDate!)
            : '選擇結束日期';
    final String displayEndTime =
        _selectedEndTime != null ? _selectedEndTime!.format(context) : '選擇結束時間';
    final String displayDuration = _formatDuration(_calculatedDuration);

    // Placeholder for leave types - replace with actual data fetching
    // Removed old leaveTypes list

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0.5, // Subtle elevation
        shadowColor: context.colorScheme.shadow.withValues(alpha: 0.1),
        leading: const AutoLeadingButton(),
      ),
      body: SingleChildScrollView(
        // Make body scrollable
        child: Padding(
          padding: EdgeInsets.all(context.i(16)),
          child: Column(
            children: [
              // --- Date and Time Selection Area ---
              _buildSectionCard(
                context,
                children: [
                  _buildPickerRow(
                    context: context,
                    icon: Icons.calendar_today_outlined, // Changed icon
                    label: displayStartDate,
                    onTap: () => _showDatePickerSheet(isStartDate: true),
                    isSelected: _selectedStartDate != null,
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  _buildPickerRow(
                    context: context,
                    icon: Icons.access_time_outlined, // Changed icon
                    label: displayStartTime,
                    onTap: () => _showTimePickerSheet(isStartTime: true),
                    isSelected: _selectedStartTime != null,
                  ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
                  Divider(height: context.h(16), thickness: 0.5),
                  _buildPickerRow(
                    context: context,
                    icon: Icons.event_available_outlined, // Changed icon
                    label: displayEndDate,
                    onTap: () => _showDatePickerSheet(isStartDate: false),
                    isSelected: _selectedEndDate != null,
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  _buildPickerRow(
                    context: context,
                    icon: Icons.update_outlined, // Changed icon
                    label: displayEndTime,
                    onTap: () => _showTimePickerSheet(isStartTime: false),
                    isSelected: _selectedEndTime != null,
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
                  Divider(height: context.h(16), thickness: 0.5),
                  // --- Calculated Duration Display ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.h(10),
                      horizontal: context.w(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom_outlined,
                          color:
                              _calculatedDuration != null &&
                                      _calculatedDuration! > Duration.zero
                                  ? context
                                      .colorScheme
                                      .tertiary // Use tertiary color
                                  : context.colorScheme.outline.withValues(
                                    alpha: 0.7,
                                  ),
                          size: context.r(22),
                        ),
                        Gap(context.w(12)),
                        Expanded(
                          child: Text(
                            displayDuration,
                            style: context.textTheme.bodyLarge?.copyWith(
                              fontSize: context.sp(16),
                              color:
                                  _calculatedDuration != null &&
                                          _calculatedDuration! > Duration.zero
                                      ? context.colorScheme.tertiary
                                      : context.colorScheme.outline,
                              fontWeight:
                                  _calculatedDuration != null &&
                                          _calculatedDuration! > Duration.zero
                                      ? FontWeight
                                          .w600 // Bold if calculated
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms), // Animate duration
                ],
              ),
              Gap(context.h(16)), // Spacing between cards
              // --- Leave Type, Agent, Remark, Files ---
              _buildSectionCard(
                context,
                children: [
                  // --- Leave Type Dropdown (Using DropdownButton2 Stable) ---
                  _buildDropdownSearch<LeaveRule>(
                    context: context,
                    label: '假別類型',
                    hint: '搜尋或選擇假別',
                    icon: Icons.category_outlined,
                    items: _leaveRules,
                    selectedItem: _leaveRules.firstWhere(
                      (r) => r.id == _selectedLeaveRuleId,
                      orElse: () => _leaveRules.first,
                    ), // Find selected or default to first
                    itemAsString: (rule) => rule.name,
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveRuleId = value?.id;
                      });
                    },
                    searchController: null, // No search for leave type
                    emptyBuilder:
                        (context, search) => const Center(child: Text('找不到假別')),
                    delay: 350.ms,
                  ),

                  Divider(height: context.h(16), thickness: 0.5),

                  // --- Agent Input (Using DropdownButton2 Stable) ---
                  _buildDropdownSearch<Employee>(
                    context: context,
                    label: '代理人',
                    hint: '搜尋或選擇代理人',
                    icon: Icons.person_search_outlined, // Changed icon
                    items: _employees,
                    selectedItem: _selectedAgent,
                    itemAsString: (emp) => '${emp.name} (${emp.department})',
                    onChanged: (value) {
                      setState(() {
                        _selectedAgent = value;
                      });
                    },
                    searchController: _agentSearchController,
                    emptyBuilder:
                        (context, search) => const Center(child: Text('找不到員工')),
                    delay: 400.ms,
                  ),

                  Divider(height: context.h(16), thickness: 0.5),

                  // --- Remark Input (Improved Styling) ---
                  _buildTextFormField(
                    context: context,
                    controller: _remarkController,
                    icon: Icons.edit_note_outlined,
                    labelText: '事由備註',
                    hintText: '請輸入請假事由...',
                    maxLines: 3,
                    isRemarkField: true, // Flag for remark styling
                    delay: 450.ms,
                  ),

                  Divider(height: context.h(16), thickness: 0.5),

                  // --- File Picker ---
                  _buildFilePickerSection(
                    context,
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                ],
              ),

              Gap(context.h(24)), // Spacing before button
              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isFormValid
                          ? () {
                            // Gather data and call API (replace with actual call)
                            final String startDateStr = _dateFormatter.format(
                              _selectedStartDate!,
                            );
                            final String endDateStr = _dateFormatter.format(
                              _selectedEndDate!,
                            );
                            final String startTimeStr =
                                '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
                            final String endTimeStr =
                                '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
                            final int hours = _calculatedDuration!.inHours;
                            final int minutes = _calculatedDuration!.inMinutes
                                .remainder(60);

                            debugPrint('Form Data:');
                            debugPrint('  Rule ID: $_selectedLeaveRuleId');
                            debugPrint('  Start Date: $startDateStr');
                            debugPrint('  End Date: $endDateStr');
                            debugPrint('  Start Time: $startTimeStr');
                            debugPrint('  End Time: $endTimeStr');
                            debugPrint('  Hours: $hours');
                            debugPrint('  Minutes: $minutes');
                            // debugPrint('  Agent ID: ${_agentController.text}'); // Log agent controller text
                            debugPrint(
                              '  Agent ID: ${_selectedAgent?.id}',
                            ); // Log selected agent ID
                            debugPrint('  Remark: ${_remarkController.text}');
                            debugPrint(
                              '  Files: ${_selectedFiles.map((f) => f.path).toList()}',
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('提交功能開發中 (資料已打印至控制台)'),
                              ),
                            );
                          }
                          : null, // Disable if form is invalid
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.h(16)),
                    textStyle: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(16),
                    ),
                    // Change background color when disabled
                    disabledBackgroundColor: context.colorScheme.onSurface
                        .withValues(alpha: 0.12),
                    disabledForegroundColor: context.colorScheme.onSurface
                        .withValues(alpha: 0.38),
                  ),
                  child: const Text('提交申請'),
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
              Gap(context.h(16)), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build section cards
  Widget _buildSectionCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0.5, // Subtle elevation
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.r(12),
        ), // Slightly more rounded
        side: BorderSide(
          color: context.colorScheme.outline.withValues(
            alpha: 0.2,
          ), // Subtle border
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(8),
        ), // Adjust padding
        child: Column(children: children),
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
          vertical: context.h(12), // Increased vertical padding
          horizontal: context.w(0), // Use card's horizontal padding
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
            Gap(context.w(16)), // Increased gap
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

  // Helper for TextFormField
  Widget _buildTextFormField({
    required BuildContext context,
    required TextEditingController controller,
    required IconData icon,
    required String labelText,
    required String hintText,
    required Duration delay,
    int maxLines = 1,
    bool isRemarkField = false, // Add flag for remark styling
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          size: context.r(20),
          color: context.colorScheme.secondary,
        ),
        labelText: labelText,
        hintText: hintText,
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.symmetric(
          vertical: context.h(12),
          horizontal: context.w(0), // Use card's padding
        ),
        // Apply different padding/alignment for remark field
        floatingLabelBehavior:
            isRemarkField
                ? FloatingLabelBehavior
                    .always // Keep label always visible
                : FloatingLabelBehavior.auto,
        isDense: isRemarkField, // Reduce vertical density for remark
        labelStyle: TextStyle(
          fontSize: context.sp(16),
          // Adjust label position slightly for remark
          height: isRemarkField ? 0.9 : null,
        ),
        hintStyle: TextStyle(
          fontSize: context.sp(16),
          color: context.colorScheme.outline,
        ),
        alignLabelWithHint: true, // Better alignment for multiline
      ),
      style: TextStyle(fontSize: context.sp(16)),
      maxLines: maxLines,
      onChanged:
          (_) => setState(() {}), // Trigger rebuild to check form validity
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1);
  }

  // Helper for File Picker Section
  Widget _buildFilePickerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_outlined,
              size: context.r(20),
              color: context.colorScheme.secondary,
            ),
            Gap(context.w(16)),
            Expanded(
              child: Text(
                '附件 (${_selectedFiles.length})', // Show file count
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: context.sp(16),
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            TextButton.icon(
              icon: Icon(
                Icons.add_photo_alternate_outlined,
                size: context.r(18),
              ),
              label: const Text('選擇檔案'),
              onPressed: _pickFiles,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(12),
                  vertical: context.h(8),
                ),
                textStyle: TextStyle(fontSize: context.sp(14)),
              ),
            ),
          ],
        ),
        // Display selected file names (optional)
        if (_selectedFiles.isNotEmpty) ...[
          Gap(context.h(8)),
          Wrap(
            // Use Wrap for multiple files
            spacing: context.w(8),
            runSpacing: context.h(4),
            children:
                _selectedFiles.map((file) {
                  final fileName = file.path.split('/').last;
                  return Chip(
                    label: Text(
                      fileName,
                      style: TextStyle(fontSize: context.sp(12)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedFiles.remove(file);
                      });
                    },
                    deleteIconColor: context.colorScheme.onSecondaryContainer
                        .withValues(alpha: 0.7),
                    backgroundColor: context.colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: context.w(8),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  // --- Re-add Helper for DropdownButton2 with Search (Stable Version) ---
  Widget _buildDropdownSearch<T>({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) itemAsString,
    required ValueChanged<T?> onChanged,
    required TextEditingController? searchController,
    required Widget Function(BuildContext, String?) emptyBuilder,
    required Duration delay,
    // Compare function not needed for stable version with value comparison
  }) {
    // Find the actual selected item object based on the stored ID/value if needed
    // For simple cases where T has == override or is primitive, direct comparison works.

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        // --- Button Customization --- Use selectedItemBuilder for better control
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min, // Important for alignment
              children: [
                Icon(
                  icon,
                  size: context.r(20),
                  color: context.colorScheme.secondary,
                ),
                Gap(context.w(16)),
                Expanded(
                  child: Text(
                    itemAsString(item), // Display string representation
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: context.sp(16),
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList();
        },
        hint: Row(
          children: [
            Icon(
              icon,
              size: context.r(20),
              color: context.colorScheme.secondary,
            ),
            Gap(context.w(16)),
            Expanded(
              child: Text(
                label, // Show label as hint
                style: context.textTheme.bodyLarge?.copyWith(
                  fontSize: context.sp(16),
                  color: context.colorScheme.outline,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item, // Use the object itself as value
                    child: Text(
                      itemAsString(item),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: context.sp(
                          14,
                        ), // Smaller font in dropdown list
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        value: selectedItem, // The currently selected object
        onChanged: onChanged,
        buttonStyleData: ButtonStyleData(
          padding: EdgeInsets.symmetric(
            vertical: context.h(0),
            horizontal: 0,
          ), // Reduced padding
          height: context.h(48), // Match text field height better
          elevation: 0, // Flat button
        ),
        iconStyleData: IconStyleData(
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            size: context.r(16),
            color: context.colorScheme.outline.withValues(alpha: 0.7),
          ),
          openMenuIcon: Icon(
            // Change icon when open
            Icons.arrow_drop_down_rounded,
            size: context.r(24),
            color: context.colorScheme.primary,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: context.h(250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            color:
                context
                    .colorScheme
                    .surfaceContainerLowest, // Use distinct color
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          offset: const Offset(0, 2), // Adjust dropdown position slightly
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: context.h(40),
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        ),
        // Add Search feature only if controller is provided (Stable Version API)
        dropdownSearchData:
            searchController != null
                ? DropdownSearchData(
                  searchController: searchController,
                  searchInnerWidgetHeight: context.h(50),
                  searchInnerWidget: Padding(
                    // Use Padding for consistent spacing
                    padding: EdgeInsets.only(
                      top: context.h(8),
                      bottom: context.h(4),
                      right: context.w(8),
                      left: context.w(8),
                    ),
                    child: TextFormField(
                      // expands: true, // May not be needed
                      // maxLines: null,
                      controller: searchController,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: context.sp(14),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.w(10),
                          vertical: context.h(10),
                        ),
                        hintText: '$hint...',
                        hintStyle: context.textTheme.bodySmall?.copyWith(
                          fontSize: context.sp(14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                          borderSide: BorderSide(
                            color: context.colorScheme.outline.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          // Highlight border when focused
                          borderRadius: BorderRadius.circular(context.r(8)),
                          borderSide: BorderSide(
                            color: context.colorScheme.primary,
                          ),
                        ),
                        prefixIcon: Icon(Icons.search, size: context.r(18)),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    // Match against the string representation of the item
                    // item is DropdownMenuItem<T>, access value via item.value
                    // Add null check for item.value
                    if (item.value == null) return false;
                    return itemAsString(
                      item.value as T,
                    ).toLowerCase().contains(searchValue.toLowerCase());
                  },
                  //Empty builder when no results detected - Removed noResultsWidget for v2.3.9
                  // noResultsWidget: emptyBuilder(context, searchController.text),
                )
                : null,
        // Clear search field when dropdown is closed
        onMenuStateChange: (isOpen) {
          if (!isOpen && searchController != null) {
            searchController.clear();
          }
        },
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1);
  }

  // --- End Re-add Helper ---
}
