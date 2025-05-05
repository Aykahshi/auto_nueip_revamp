import 'dart:io'; // Import dart:io for File

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:joker_state/joker_state.dart'; // Import JokerState

import '../../../../core/extensions/theme_extensions.dart';
import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../data/models/employee_list.dart'; // Import new Employee model
import '../presenters/apply_form_presenter.dart'; // Import Presenter
import '../widgets/apply_form_body.dart'; // Import the new body widget
import '../widgets/date_picker_sheet_builder.dart'; // Import the builder
import '../widgets/time_picker_theme_builder.dart'; // Import the time picker theme builder
import 'form_screen.dart'; // Assuming FormHistoryType is here

@RoutePage()
class ApplyFormScreen extends StatefulWidget {
  final FormHistoryType formType;

  const ApplyFormScreen({required this.formType, super.key});

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  // --- State Variables (Managed by Screen) ---
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  String? _selectedLeaveRuleId;
  Employee? _selectedAgent; // Use new Employee model
  final TextEditingController _agentSearchController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  List<File> _selectedFiles = [];
  Duration? _calculatedDuration;

  // --- Presenter --- (Initialized in initState or build)
  late final ApplyFormPresenter _presenter;

  // --- Text Editing Controllers Dispose ---
  @override
  void dispose() {
    _agentSearchController.dispose();
    _remarkController.dispose();
    // Dispose presenter IF it's managed solely by this screen
    // If registered globally via Circus, it might be handled elsewhere.
    // Consider using Circus.findOrSummon and managing lifecycle if needed.
    // _presenter.dispose(); // Example if locally managed
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize the presenter - requires NueipRepository
    // Assuming NueipRepository is registered in Circus
    _presenter = ApplyFormPresenter(
      formType: widget.formType,
      nueipRepository:
          Circus.find<NueipRepositoryImpl>(), // Find repository via Circus
    );
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

  // --- Duration Calculation --- (Calls Presenter if needed)
  void _calculateAndSetDuration() {
    if (_startDateTime != null && _endDateTime != null) {
      if (_endDateTime!.isAfter(_startDateTime!)) {
        setState(() {
          _calculatedDuration = _endDateTime!.difference(_startDateTime!);
          // Optionally, call presenter to fetch work hours based on new range
          _presenter.fetchWorkHoursByDateRange(
            startDate: _startDateTime!,
            endDate: _endDateTime!,
          );
        });
      } else {
        setState(() {
          _calculatedDuration = Duration.zero;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('結束時間必須晚於開始時間'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      setState(() {
        _calculatedDuration = null;
      });
    }
  }

  // --- Date Picker Logic (Modified for Start/End) ---
  void _showDatePickerSheet({required bool isStartDate}) {
    DateTime? initialDate =
        (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    // Removed currentSheetSelection, handled within the builder

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        // Use the extracted builder function
        return buildDatePickerSheetContent(
          sheetContext: sheetContext,
          isStartDate: isStartDate,
          initialDate: initialDate,
          selectedStartDateForMinDate: _selectedStartDate,
          onSelectionConfirmed: (DateTime? selectedDate) {
            if (selectedDate != null) {
              setState(() {
                final confirmedDate = DateUtils.dateOnly(selectedDate);
                if (isStartDate) {
                  _selectedStartDate = confirmedDate;
                  if (_selectedEndDate != null &&
                      _selectedEndDate!.isBefore(_selectedStartDate!)) {
                    _selectedEndDate = null;
                    _selectedEndTime = null;
                  }
                } else {
                  if (_selectedStartDate != null &&
                      confirmedDate.isBefore(_selectedStartDate!)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('結束日期不能早於開始日期'),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );
                    }
                  } else {
                    _selectedEndDate = confirmedDate;
                  }
                }
                _calculateAndSetDuration();
              });
            }
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
      // Use the extracted theme builder
      builder:
          (builderContext, child) =>
              buildTimePickerTheme(context: builderContext, child: child),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
        _calculateAndSetDuration();
      });
    }
  }

  // --- File Picker Logic ---
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _selectedFiles =
              result.paths
                  .where((path) => path != null)
                  .map((path) => File(path!))
                  .toList();
        });
      } else {
        // User canceled
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('檔案選擇失敗: ${e.toString()}')));
    }
  }

  // --- Form Validation --- (Keep this logic here as it depends on local state)
  bool _isFormValid() {
    return _selectedStartDate != null &&
        _selectedStartTime != null &&
        _selectedEndDate != null &&
        _selectedEndTime != null &&
        _calculatedDuration != null &&
        _calculatedDuration! > Duration.zero &&
        _selectedLeaveRuleId != null &&
        _selectedAgent != null &&
        _remarkController.text.isNotEmpty;
  }

  // --- Format Duration --- (Can stay here or move to utils)
  String _formatDuration(Duration? duration) {
    if (duration == null) return '請選擇起始時間';
    if (duration == Duration.zero) return '0 小時 0 分鐘';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours 小時 $minutes 分鐘';
  }

  // --- Helper to flatten departments to employees --- (Can stay here or move to utils/presenter)
  List<Employee> _getAllEmployees(
    Map<String, (String?, List<Employee>)> departmentEmployees,
  ) {
    final List<Employee> employees = [];
    for (var entry in departmentEmployees.entries) {
      employees.addAll(entry.value.$2);
    }
    employees.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return employees;
  }

  // --- Submit Logic (Placeholder) ---
  void _submitForm() {
    // Gather data and call API/Presenter
    final String startDateStr = _dateFormatter.format(_selectedStartDate!);
    final String endDateStr = _dateFormatter.format(_selectedEndDate!);
    final String startTimeStr =
        '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}';
    final String endTimeStr =
        '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}';
    final int hours = _calculatedDuration!.inHours;
    final int minutes = _calculatedDuration!.inMinutes.remainder(60);

    debugPrint('Form Data:');
    debugPrint('  Rule ID: $_selectedLeaveRuleId');
    debugPrint('  Start Date: $startDateStr');
    debugPrint('  End Date: $endDateStr');
    debugPrint('  Start Time: $startTimeStr');
    debugPrint('  End Time: $endTimeStr');
    debugPrint('  Hours: $hours');
    debugPrint('  Minutes: $minutes');
    debugPrint('  Agent ID: ${_selectedAgent?.id} (${_selectedAgent?.name})');
    debugPrint('  Remark: ${_remarkController.text}');
    debugPrint('  Files: ${_selectedFiles.map((f) => f.path).toList()}');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('提交功能開發中 (資料已打印至控制台)')));
    // TODO: Call presenter.submitLeaveForm(...);
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.formType == FormHistoryType.leave ? '申請請假單' : '申請請款單';

    // Calculate display strings here to pass to the body
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: context.colorScheme.shadow.withValues(alpha: 0.1),
        leading: const AutoLeadingButton(),
      ),
      body: _presenter.perform(
        builder: (context, state) {
          // Handle Loading and Top-level Error states
          // Using state flags from single state model
          if (state.isLoadingInitialData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Show general error if initial load failed significantly
          // Error during work hour fetch is handled via SnackBar in ApplyFormBody
          if (state.hasError &&
              state.departmentEmployees.isEmpty &&
              state.leaveRules.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.i(16)),
                child: Text(
                  '載入表單初始資料時發生錯誤: \n${state.errorMessage}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ),
            );
          }

          // Flatten employees for the dropdown
          final allEmployees = _getAllEmployees(state.departmentEmployees);

          // Build the main form body using the extracted widget
          return ApplyFormBody(
            formState: state,
            leaveRules: state.leaveRules,
            allEmployees: allEmployees,
            selectedStartDate: _selectedStartDate,
            displayStartDate: displayStartDate,
            selectedStartTime: _selectedStartTime,
            displayStartTime: displayStartTime,
            selectedEndDate: _selectedEndDate,
            displayEndDate: displayEndDate,
            selectedEndTime: _selectedEndTime,
            displayEndTime: displayEndTime,
            calculatedDuration: _calculatedDuration,
            displayDuration: displayDuration,
            selectedLeaveRuleId: _selectedLeaveRuleId,
            selectedAgent: _selectedAgent,
            selectedFiles: _selectedFiles,
            agentSearchController: _agentSearchController,
            remarkController: _remarkController,
            onShowStartDatePicker:
                () => _showDatePickerSheet(isStartDate: true),
            onShowStartTimePicker:
                () => _showTimePickerSheet(isStartTime: true),
            onShowEndDatePicker: () => _showDatePickerSheet(isStartDate: false),
            onShowEndTimePicker: () => _showTimePickerSheet(isStartTime: false),
            onLeaveRuleChanged: (id) {
              setState(() {
                _selectedLeaveRuleId = id;
              });
            },
            onAgentChanged: (employee) {
              setState(() {
                _selectedAgent = employee;
              });
            },
            onPickFiles: _pickFiles,
            onRemoveFile: (file) {
              setState(() {
                _selectedFiles.remove(file);
              });
            },
            onSubmit: _submitForm, // Pass the submit function
            isFormValid: _isFormValid(), // Pass validity check result
          );
        },
      ),
    );
  }
}
