import 'dart:io'; // Import dart:io for File

import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:joker_state/joker_state.dart'; // Import JokerState

import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../data/models/employee_list.dart'; // Import new Employee model
import '../presenters/apply_form_presenter.dart'; // Import Presenter
import '../presenters/apply_form_ui_presenter.dart'; // Import UI Presenter
import '../widgets/apply_form_body.dart'; // Import the new body widget
import '../widgets/date_picker_sheet_builder.dart'; // Import the builder
import '../widgets/time_picker_theme_builder.dart'; // Import the time picker theme builder
import 'form_screen.dart'; // Assuming FormHistoryType is here

@RoutePage()
class ApplyFormScreen extends StatelessWidget {
  final FormHistoryType formType;

  const ApplyFormScreen({required this.formType, super.key});

  @override
  Widget build(BuildContext context) {
    final ApplyFormPresenter dataPresenter = Circus.find<ApplyFormPresenter>();
    final ApplyFormUiPresenter uiPresenter =
        Circus.find<ApplyFormUiPresenter>();

    final String title = formType == FormHistoryType.leave ? '申請請假單' : '申請請款單';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: context.colorScheme.shadow.withValues(alpha: 0.1),
        leading: const AutoLeadingButton(),
      ),
      body: dataPresenter.perform(
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

          return uiPresenter.perform(
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
                agentSearchController: uiPresenter.agentSearch,
                remarkController: uiPresenter.remark,
                onShowStartDatePicker:
                    () => _showDatePickerSheet(
                      context,
                      isStartDate: true,
                      ui: uiPresenter,
                      data: dataPresenter,
                    ),
                onShowStartTimePicker:
                    () => _showTimePickerSheet(
                      context,
                      isStartTime: true,
                      ui: uiPresenter,
                      data: dataPresenter,
                    ),
                onShowEndDatePicker:
                    () => _showDatePickerSheet(
                      context,
                      isStartDate: false,
                      ui: uiPresenter,
                      data: dataPresenter,
                    ),
                onShowEndTimePicker:
                    () => _showTimePickerSheet(
                      context,
                      isStartTime: false,
                      ui: uiPresenter,
                      data: dataPresenter,
                    ),
                onLeaveRuleChanged: (id) => uiPresenter.setLeaveRuleId(id),
                onAgentChanged: (employee) => uiPresenter.setAgent(employee),
                onPickFiles: () => _pickFiles(context, uiPresenter),
                onRemoveFile: (file) => uiPresenter.removeFile(file),
                onSubmit:
                    () => _submitForm(
                      context,
                      ui: uiPresenter,
                      data: dataPresenter,
                    ),
                isFormValid: uiState.isFormValid,
              );
            },
          );
        },
      ),
    );
  }
}

void _submitForm(
  BuildContext context, {
  required ApplyFormUiPresenter ui,
  required ApplyFormPresenter data,
}) {
  final debouncer = CueGate.debounce(delay: const Duration(milliseconds: 500));
  final formatter = DateFormat('yyyy-MM-dd');

  // Use CueGate to prevent multiple rapid clicks
  debouncer.trigger(() {
    final uiState = ui.state;
    final dataState = data.state;

    // Set UI to submitting state
    ui.setSubmitting(true);
    ui.setErrorMessage(null);

    // Get form data from UI state
    final String startDateStr = formatter.format(uiState.selectedStartDate!);
    final String endDateStr = formatter.format(uiState.selectedEndDate!);

    // Create complete DateTime objects for generating leave entries
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

    // Check if work hours data is available
    if (dataState.workHours == null || dataState.workHours!.isEmpty) {
      ui.setSubmitting(false);
      ui.setErrorMessage('無法提交：缺少工時資料。請確保已選擇有效的日期和時間。');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法提交：缺少工時資料。請確保已選擇有效的日期和時間。')),
      );
      return;
    }

    // Generate multi-day leave entries
    final leaveEntries = data.generateLeaveEntries(
      workHoursList: dataState.workHours!,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );

    // Check if there are valid leave entries
    if (leaveEntries.isEmpty) {
      ui.setSubmitting(false);
      ui.setErrorMessage('無法提交：所選時間範圍內沒有有效的工作時間。');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無法提交：所選時間範圍內沒有有效的工作時間。')));
      return;
    }

    // Check if leave type is selected
    if (uiState.selectedLeaveRuleId == null) {
      ui.setSubmitting(false);
      ui.setErrorMessage('請選擇假別類型');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇假別類型')));
      return;
    }

    // Check if agent is selected
    if (uiState.selectedAgent == null) {
      ui.setSubmitting(false);
      ui.setErrorMessage('請選擇代理人');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇代理人')));
      return;
    }

    // Get auth session
    final session = AuthUtils.getAuthSession();

    // Submit leave form with callbacks
    data.submitLeaveForm(
      ruleId: uiState.selectedLeaveRuleId!,
      startDate: startDateStr,
      endDate: endDateStr,
      leaveEntries: leaveEntries,
      agent: (uiState.selectedAgent!.id!, uiState.selectedAgent!.sn!),
      remark: ui.remark.text,
      files: uiState.selectedFiles,
      cookie: session.cookie!,
      onSuccess: () {
        // Reset UI submitting state
        ui.setSubmitting(false);

        // Show success message and navigate back
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('申請已提交成功！')));
        // Use Auto Route to navigate back
        context.pop();
      },
      onFailed: (errorMessage) {
        // Reset UI submitting state
        ui.setSubmitting(false);

        // Show error message (只設置錯誤訊息，不顯示 Snackbar)
        ui.setErrorMessage(errorMessage);
      },
    );
  });
}

void _checkAndTriggerWorkHourCalculation(
  ApplyFormUiPresenter ui,
  ApplyFormPresenter data,
) {
  final uiState = ui.state;

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
      data.cauculateWorkHour(
        dates: datesToFetch,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );
    }
  }
}

Future<void> _showTimePickerSheet(
  BuildContext context, {
  required bool isStartTime,
  required ApplyFormUiPresenter ui,
  required ApplyFormPresenter data,
}) async {
  final uiState = ui.state;
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
      ui.setStartTime(picked);
    } else {
      ui.setEndTime(picked);
    }
    _checkAndTriggerWorkHourCalculation(ui, data);
  }
}

void _showDatePickerSheet(
  BuildContext context, {
  required bool isStartDate,
  required ApplyFormUiPresenter ui,
  required ApplyFormPresenter data,
}) {
  final uiState = ui.state;
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
              ui.setStartDate(selectedDate);
            } else {
              ui.setEndDate(selectedDate);
            }
            _checkAndTriggerWorkHourCalculation(ui, data);
          }
        },
      );
    },
  );
}

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

Future<void> _pickFiles(BuildContext context, ApplyFormUiPresenter ui) async {
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
      ui.setFiles(files);
    } else {
      // User canceled
    }
  } catch (e) {
    debugPrint('Error picking files: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('檔案選擇失敗: ${e.toString()}')));
  }
}
