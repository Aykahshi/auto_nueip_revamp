import 'dart:io'; // Import dart:io for File

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:joker_state/joker_state.dart'; // Import JokerState

import '../../../../core/extensions/theme_extensions.dart';
import '../../data/models/employee_list.dart'; // Import new Employee model
import '../presenters/apply_form_presenter.dart'; // Import Presenter
import '../presenters/apply_form_ui_presenter.dart'; // Import UI Presenter
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
  final TextEditingController _agentSearchController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  // --- Presenters ---
  late final ApplyFormPresenter _dataPresenter;
  late final ApplyFormUiPresenter _uiPresenter;

  // --- Text Editing Controllers Dispose ---
  @override
  void dispose() {
    _agentSearchController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 初始化數據 Presenter
    _dataPresenter = ApplyFormPresenter(formType: widget.formType);

    // 初始化 UI Presenter
    _uiPresenter = ApplyFormUiPresenter();

    // ! TOFIX: need to fix JokerState dispose issue
    // ! this is a temporary fix
    _uiPresenter.addListener(() {});

    // 監聽備註欄位變化以更新表單驗證
    _remarkController.addListener(_validateForm);
  }

  // --- Date and Time formatters ---
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  // Time formatter handled by TimeOfDay.format

  // --- Date Picker Logic (Modified for Start/End) ---
  void _showDatePickerSheet({required bool isStartDate}) {
    final uiState = _uiPresenter.state;
    DateTime? initialDate =
        (isStartDate ? uiState.selectedStartDate : uiState.selectedEndDate) ??
        DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return buildDatePickerSheetContent(
          sheetContext: sheetContext,
          isStartDate: isStartDate,
          initialDate: initialDate,
          selectedStartDateForMinDate: uiState.selectedStartDate,
          onSelectionConfirmed: (DateTime? selectedDate) {
            if (selectedDate != null) {
              if (isStartDate) {
                _uiPresenter.setStartDate(selectedDate);
              } else {
                _uiPresenter.setEndDate(selectedDate);
              }
              _checkAndTriggerWorkHourCalculation();
            }
          },
        );
      },
    );
  }

  // --- Time Picker Logic (Modified for Start/End) ---
  Future<void> _showTimePickerSheet({required bool isStartTime}) async {
    final uiState = _uiPresenter.state;
    final TimeOfDay initialTime =
        (isStartTime ? uiState.selectedStartTime : uiState.selectedEndTime) ??
        TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder:
          (builderContext, child) =>
              buildTimePickerTheme(context: builderContext, child: child),
    );

    if (picked != null) {
      if (isStartTime) {
        _uiPresenter.setStartTime(picked);
      } else {
        _uiPresenter.setEndTime(picked);
      }
      _checkAndTriggerWorkHourCalculation();
    }
  }

  // 新增：檢查並觸發工時計算的方法
  void _checkAndTriggerWorkHourCalculation() {
    final uiState = _uiPresenter.state;

    // 檢查是否所有日期時間都已選擇
    if (uiState.selectedStartDate != null &&
        uiState.selectedEndDate != null &&
        uiState.selectedStartTime != null &&
        uiState.selectedEndTime != null) {
      // 生成日期列表
      final List<String> datesToFetch = [];
      DateTime currentDate = uiState.selectedStartDate!;

      while (!currentDate.isAfter(uiState.selectedEndDate!)) {
        datesToFetch.add(DateFormat('yyyy-MM-dd').format(currentDate));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 創建完整的 DateTime 對象
      final startDateTime = DateTime(
        uiState.selectedStartDate!.year,
        uiState.selectedStartDate!.month,
        uiState.selectedStartDate!.day,
        uiState.selectedStartTime!.hour,
        uiState.selectedStartTime!.minute,
      );

      final endDateTime = DateTime(
        uiState.selectedEndDate!.year,
        uiState.selectedEndDate!.month,
        uiState.selectedEndDate!.day,
        uiState.selectedEndTime!.hour,
        uiState.selectedEndTime!.minute,
      );

      // 呼叫 Presenter 方法計算工時
      if (datesToFetch.isNotEmpty) {
        _dataPresenter.cauculateWorkHour(
          dates: datesToFetch,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        );
      }
    }
  }

  // --- File Picker Logic ---
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.media,
      );

      if (result != null) {
        final files =
            result.paths
                .where((path) => path != null)
                .map((path) => File(path!))
                .toList();
        _uiPresenter.setFiles(files);
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
    final uiState = _uiPresenter.state;

    // 從 UI 狀態中獲取表單資料
    final String startDateStr = _dateFormatter.format(
      uiState.selectedStartDate!,
    );
    final String endDateStr = _dateFormatter.format(uiState.selectedEndDate!);

    final String startTimeStr =
        '${uiState.selectedStartTime!.hour.toString().padLeft(2, '0')}:${uiState.selectedStartTime!.minute.toString().padLeft(2, '0')}';

    final String endTimeStr =
        '${uiState.selectedEndTime!.hour.toString().padLeft(2, '0')}:${uiState.selectedEndTime!.minute.toString().padLeft(2, '0')}';

    final int hours = uiState.calculatedDuration!.inHours;
    final int minutes = uiState.calculatedDuration!.inMinutes.remainder(60);

    debugPrint('Form Data:');
    debugPrint('  Rule ID: ${uiState.selectedLeaveRuleId}');
    debugPrint('  Start Date: $startDateStr');
    debugPrint('  End Date: $endDateStr');
    debugPrint('  Start Time: $startTimeStr');
    debugPrint('  End Time: $endTimeStr');
    debugPrint('  Hours: $hours');
    debugPrint('  Minutes: $minutes');
    debugPrint(
      '  Agent ID: ${uiState.selectedAgent?.id} (${uiState.selectedAgent?.name})',
    );
    debugPrint('  Remark: ${_remarkController.text}');
    debugPrint('  Files: ${uiState.selectedFiles.map((f) => f.path).toList()}');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('提交功能開發中 (資料已打印至控制台)')));
    // TODO: Call presenter.submitLeaveForm(...);
  }

  // --- 驗證表單
  void _validateForm() {
    _uiPresenter.validateForm(remark: _remarkController.text);
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        widget.formType == FormHistoryType.leave ? '申請請假單' : '申請請款單';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: context.colorScheme.shadow.withValues(alpha: 0.1),
        leading: const AutoLeadingButton(),
      ),
      body: _dataPresenter.perform(
        builder: (context, dataState) {
          // 處理數據載入中和錯誤狀態
          if (dataState.isLoadingInitialData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dataState.hasError &&
              dataState.departmentEmployees.isEmpty &&
              dataState.leaveRules.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(context.i(16)),
                child: Text(
                  '載入表單初始資料時發生錯誤: \n${dataState.errorMessage}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ),
            );
          }

          final allEmployees = _getAllEmployees(dataState.departmentEmployees);

          return _uiPresenter.perform(
            builder: (context, uiState) {
              return ApplyFormBody(
                formState: dataState,
                leaveRules: dataState.leaveRules,
                allEmployees: allEmployees,
                selectedStartDate: uiState.selectedStartDate,
                displayStartDate: uiState.displayStartDate,
                selectedStartTime: uiState.selectedStartTime,
                displayStartTime:
                    uiState.selectedStartTime?.format(context) ?? '選擇開始時間',
                selectedEndDate: uiState.selectedEndDate,
                displayEndDate: uiState.displayEndDate,
                selectedEndTime: uiState.selectedEndTime,
                displayEndTime:
                    uiState.selectedEndTime?.format(context) ?? '選擇結束時間',
                calculatedDuration: uiState.calculatedDuration,
                displayDuration: uiState.displayDuration,
                selectedLeaveRuleId: uiState.selectedLeaveRuleId,
                selectedAgent: uiState.selectedAgent,
                selectedFiles: uiState.selectedFiles,
                agentSearchController: _agentSearchController,
                remarkController: _remarkController,
                onShowStartDatePicker:
                    () => _showDatePickerSheet(isStartDate: true),
                onShowStartTimePicker:
                    () => _showTimePickerSheet(isStartTime: true),
                onShowEndDatePicker:
                    () => _showDatePickerSheet(isStartDate: false),
                onShowEndTimePicker:
                    () => _showTimePickerSheet(isStartTime: false),
                onLeaveRuleChanged: (id) => _uiPresenter.setLeaveRuleId(id),
                onAgentChanged: (employee) => _uiPresenter.setAgent(employee),
                onPickFiles: _pickFiles,
                onRemoveFile: (file) => _uiPresenter.removeFile(file),
                onSubmit: _submitForm,
                isFormValid: uiState.isFormValid,
              );
            },
          );
        },
      ),
    );
  }
}
