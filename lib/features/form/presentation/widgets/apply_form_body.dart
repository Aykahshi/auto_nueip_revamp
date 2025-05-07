import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../data/models/employee_list.dart';
import '../../domain/entities/apply_form_state.dart';
import '../../domain/entities/leave_rule.dart';
import 'dropdown_search_field.dart';
import 'file_picker_section.dart';
import 'form_text_field.dart';
import 'picker_row.dart';
import 'section_card.dart';

/// The main body widget for the ApplyFormScreen.
///
/// Contains the form fields and the submit button.
class ApplyFormBody extends StatelessWidget {
  // --- Data from State ---
  final ApplyFormState formState;
  final List<LeaveRule> leaveRules;
  final List<Employee> allEmployees;

  // --- Local UI State from Parent ---
  final DateTime? selectedStartDate;
  final String displayStartDate;
  final TimeOfDay? selectedStartTime;
  final String displayStartTime;
  final DateTime? selectedEndDate;
  final String displayEndDate;
  final TimeOfDay? selectedEndTime;
  final String displayEndTime;
  final Duration? calculatedDuration;
  final String displayDuration;
  final String? selectedLeaveRuleId;
  final Employee? selectedAgent;
  final List<File> selectedFiles;

  // --- Controllers from Parent ---
  final TextEditingController agentSearchController;
  final TextEditingController remarkController;

  // --- Callbacks from Parent ---
  final VoidCallback onShowStartDatePicker;
  final VoidCallback onShowStartTimePicker;
  final VoidCallback onShowEndDatePicker;
  final VoidCallback onShowEndTimePicker;
  final ValueChanged<String?> onLeaveRuleChanged;
  final ValueChanged<Employee?> onAgentChanged;
  final VoidCallback onPickFiles;
  final ValueChanged<File> onRemoveFile;
  final VoidCallback onSubmit;
  final bool isFormValid;

  const ApplyFormBody({
    required this.formState,
    required this.leaveRules,
    required this.allEmployees,
    required this.selectedStartDate,
    required this.displayStartDate,
    required this.selectedStartTime,
    required this.displayStartTime,
    required this.selectedEndDate,
    required this.displayEndDate,
    required this.selectedEndTime,
    required this.displayEndTime,
    required this.calculatedDuration,
    required this.displayDuration,
    required this.selectedLeaveRuleId,
    required this.selectedAgent,
    required this.selectedFiles,
    required this.agentSearchController,
    required this.remarkController,
    required this.onShowStartDatePicker,
    required this.onShowStartTimePicker,
    required this.onShowEndDatePicker,
    required this.onShowEndTimePicker,
    required this.onLeaveRuleChanged,
    required this.onAgentChanged,
    required this.onPickFiles,
    required this.onRemoveFile,
    required this.onSubmit,
    required this.isFormValid,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Show error message SnackBar if needed (moved from parent)
    if (formState.hasError && formState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formState.errorMessage!)));
      });
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.i(16)),
        child: Column(
          children: [
            // --- Date and Time Selection Area ---
            SectionCard(
              children: [
                PickerRow(
                  icon: Icons.calendar_today_outlined,
                  label: displayStartDate,
                  onTap: onShowStartDatePicker,
                  isSelected: selectedStartDate != null,
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                PickerRow(
                  icon: Icons.access_time_outlined,
                  label: displayStartTime,
                  onTap: onShowStartTimePicker,
                  isSelected: selectedStartTime != null,
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
                Divider(height: context.h(16), thickness: 0.5),
                PickerRow(
                  icon: Icons.event_available_outlined,
                  label: displayEndDate,
                  onTap: onShowEndDatePicker,
                  isSelected: selectedEndDate != null,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                PickerRow(
                  icon: Icons.update_outlined,
                  label: displayEndTime,
                  onTap: onShowEndTimePicker,
                  isSelected: selectedEndTime != null,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
              ],
            ),
            Gap(context.h(16)),

            // --- 工時顯示區塊 ---
            if (selectedStartDate != null &&
                selectedEndDate != null &&
                selectedStartTime != null &&
                selectedEndTime != null) // 只有在所有日期時間都選好時顯示
              SectionCard(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: context.w(14)),
                              child: Icon(
                                Icons.timer_outlined,
                                size: context.r(22),
                                color: context.colorScheme.primary,
                              ),
                            ),
                            Gap(context.w(16)),
                            Text(
                              '預估總工時：',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: context.w(14)),
                          child:
                              formState.isLoadingWorkHours
                                  ? SizedBox(
                                    height: context.r(16),
                                    width: context.r(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.colorScheme.tertiary,
                                    ),
                                  )
                                  : Text(
                                    formState.displayTotalWorkHours,
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.primary,
                                        ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (formState.hasError &&
                      formState.errorMessage != null &&
                      (formState.errorMessage!.contains('工時') ||
                          formState.errorMessage!.contains('排班') ||
                          formState.errorMessage!.contains('工作日')))
                    Padding(
                      padding: EdgeInsets.only(
                        top: context.h(4),
                        left: context.w(14),
                        right: context.w(14),
                        bottom: context.h(8),
                      ),
                      child: Text(
                        formState.errorMessage!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.error,
                          fontSize: context.sp(12),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.1),
            Gap(context.h(16)),

            // --- Leave Type, Agent, Remark, Files ---
            SectionCard(
              children: [
                // --- Leave Type Dropdown ---
                DropdownSearchField<LeaveRule>(
                  label: '假別類型',
                  hint: '搜尋或選擇假別',
                  icon: Icons.category_outlined,
                  items: leaveRules, // Use data passed from parent
                  selectedItem: leaveRules.cast<LeaveRule?>().firstWhere(
                    (r) => r?.id == selectedLeaveRuleId,
                    orElse: () => null,
                  ),
                  itemAsString: (rule) => rule.ruleName,
                  onChanged: (value) => onLeaveRuleChanged(value?.id),
                  searchController: null,
                  emptyBuilder:
                      (context, search) => const Center(child: Text('找不到假別')),
                  delay: 350.ms,
                ),
                Divider(height: context.h(16), thickness: 0.5),
                // --- Agent Input ---
                DropdownSearchField<Employee>(
                  label: '代理人',
                  hint: '搜尋或選擇代理人',
                  icon: Icons.person_search_outlined,
                  items: allEmployees, // Use data passed from parent
                  selectedItem: selectedAgent,
                  itemAsString: (emp) => emp.name ?? '查無此員工',
                  onChanged: onAgentChanged,
                  searchController: agentSearchController,
                  emptyBuilder:
                      (context, search) => const Center(child: Text('找不到員工')),
                  delay: 400.ms,
                ),
                Divider(height: context.h(16), thickness: 0.5),
                // --- Remark Input ---
                FormTextField(
                  controller: remarkController,
                  icon: Icons.edit_note_outlined,
                  labelText: '事由備註',
                  hintText: '請輸入請假事由...',
                  maxLines: 3,
                  isRemarkField: true,
                  delay: 450.ms,
                ),
                Divider(height: context.h(16), thickness: 0.5),
                // --- File Picker ---
                FilePickerSection(
                  selectedFiles: selectedFiles,
                  onPickFiles: onPickFiles,
                  onRemoveFile: onRemoveFile,
                ),
              ],
            ),
            Gap(context.h(24)),
            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormValid ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.h(16)),
                  textStyle: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(16),
                  ),
                  disabledBackgroundColor: context.colorScheme.onSurface
                      .withValues(alpha: 0.12),
                  disabledForegroundColor: context.colorScheme.onSurface
                      .withValues(alpha: 0.38),
                ),
                // Show progress indicator when submitting
                child:
                    formState.isSubmitting
                        ? SizedBox(
                          height: context.r(20),
                          width: context.r(20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('提交申請'),
              ),
            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
            Gap(context.h(16)),
          ],
        ),
      ),
    );
  }
}
