import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../data/models/employee_list.dart';
import '../../domain/entities/apply_form_ui_state.dart';

/// 管理 ApplyFormScreen 的 UI 狀態的 Presenter
class ApplyFormUiPresenter extends Presenter<ApplyFormUiState> {
  final DateFormat _dateFormatter = DateFormat('yyyy / MM / dd');

  /// 建構子
  ApplyFormUiPresenter() : super(const ApplyFormUiState());

  @override
  onInit() {
    debugPrint('ApplyFormUiPresenter.onInit()');
    super.onInit();
  }

  @override
  onDone() {
    debugPrint('ApplyFormUiPresenter.onDone()');
    super.onDone();
  }

  /// 取得合併開始日期時間
  DateTime? get startDateTime {
    if (state.selectedStartDate == null || state.selectedStartTime == null) {
      return null;
    }

    return DateTime(
      state.selectedStartDate!.year,
      state.selectedStartDate!.month,
      state.selectedStartDate!.day,
      state.selectedStartTime!.hour,
      state.selectedStartTime!.minute,
    );
  }

  /// 取得合併結束日期時間
  DateTime? get endDateTime {
    if (state.selectedEndDate == null || state.selectedEndTime == null) {
      return null;
    }

    return DateTime(
      state.selectedEndDate!.year,
      state.selectedEndDate!.month,
      state.selectedEndDate!.day,
      state.selectedEndTime!.hour,
      state.selectedEndTime!.minute,
    );
  }

  /// Calculate and set leave duration
  void calculateDuration() {
    if (startDateTime != null && endDateTime != null) {
      if (endDateTime!.isAfter(startDateTime!)) {
        final duration = endDateTime!.difference(startDateTime!);
        final durationText = formatDuration(duration);

        trickWith(
          (s) => s.copyWith(
            calculatedDuration: duration,
            displayDuration: durationText,
          ),
        );

        // Always validate form after changing any field
        validateForm();
      } else {
        trickWith(
          (s) => s.copyWith(
            calculatedDuration: Duration.zero,
            displayDuration: '0 小時 0 分鐘',
          ),
        );

        // Always validate form after changing any field
        validateForm();
      }
    } else {
      trickWith(
        (s) => s.copyWith(calculatedDuration: null, displayDuration: '請選擇起始時間'),
      );
      
      // Always validate form after changing any field
      validateForm();
    }
  }

  /// Set start date
  void setStartDate(DateTime? date) {
    if (date == null) return;

    final confirmedDate = DateUtils.dateOnly(date);
    final String displayDate = _dateFormatter.format(confirmedDate);

    // If end date is before start date, clear end date
    final endDate = state.selectedEndDate;

    if (endDate != null && endDate.isBefore(confirmedDate)) {
      trickWith(
        (s) => s.copyWith(
          selectedStartDate: confirmedDate,
          displayStartDate: displayDate,
          selectedEndDate: null,
          selectedEndTime: null,
          displayEndDate: '選擇結束日期',
          displayEndTime: '選擇結束時間',
        ),
      );
    } else {
      trickWith(
        (s) => s.copyWith(
          selectedStartDate: confirmedDate,
          displayStartDate: displayDate,
        ),
      );
    }

    // Calculate duration will also validate the form
    calculateDuration();
  }

  /// Set end date
  void setEndDate(DateTime? date) {
    if (date == null) return;

    final confirmedDate = DateUtils.dateOnly(date);
    final startDate = state.selectedStartDate;

    // Check if end date is before start date
    if (startDate != null && confirmedDate.isBefore(startDate)) {
      // End date cannot be before start date, do not set
      return;
    }

    final String displayDate = _dateFormatter.format(confirmedDate);

    trickWith(
      (s) => s.copyWith(
        selectedEndDate: confirmedDate,
        displayEndDate: displayDate,
      ),
    );

    // Calculate duration will also validate the form
    calculateDuration();
  }

  /// Set start time
  void setStartTime(TimeOfDay? time) {
    if (time == null) return;

    final String timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    trickWith(
      (s) => s.copyWith(selectedStartTime: time, displayStartTime: timeString),
    );

    // Calculate duration will also validate the form
    calculateDuration();
  }

  /// Set end time
  void setEndTime(TimeOfDay? time) {
    if (time == null) return;

    final String timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    trickWith(
      (s) => s.copyWith(selectedEndTime: time, displayEndTime: timeString),
    );

    // Calculate duration will also validate the form
    calculateDuration();
  }

  /// Set leave rule ID
  void setLeaveRuleId(String? id) {
    trickWith((s) => s.copyWith(selectedLeaveRuleId: id));
    // Always validate form after changing any field
    validateForm();
  }

  /// Set agent
  void setAgent(Employee? employee) {
    trickWith((s) => s.copyWith(selectedAgent: employee));
    // Always validate form after changing any field
    validateForm();
  }

  /// Set selected files
  void setFiles(List<File> files) {
    trickWith((s) => s.copyWith(selectedFiles: files));
    // Always validate form after changing any field
    validateForm();
  }

  /// Remove file
  void removeFile(File file) {
    final newFiles = [...state.selectedFiles]..remove(file);
    trickWith((s) => s.copyWith(selectedFiles: newFiles));
    // Always validate form after changing any field
    validateForm();
  }

  /// Format duration for display
  String formatDuration(Duration? duration) {
    if (duration == null) return '請選擇起始時間';
    if (duration == Duration.zero) return '0 小時 0 分鐘';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours 小時 $minutes 分鐘';
  }
  
  /// Set submitting state
  void setSubmitting(bool isSubmitting) {
    trickWith((s) => s.copyWith(isSubmitting: isSubmitting));
  }
  
  /// Set error message
  void setErrorMessage(String? errorMessage) {
    trickWith((s) => s.copyWith(errorMessage: errorMessage));
  }

  // Current remark value for form validation
  String _currentRemark = '';
  
  /// Set current remark value
  void setRemark(String value) {
    _currentRemark = value;
    validateForm();
  }

  /// Validate if the form is valid
  void validateForm({String? remark}) {
    // Use provided remark or current stored remark
    final remarkToCheck = remark ?? _currentRemark;
    
    final isValid =
        state.selectedStartDate != null &&
        state.selectedStartTime != null &&
        state.selectedEndDate != null &&
        state.selectedEndTime != null &&
        state.calculatedDuration != null &&
        state.calculatedDuration! > Duration.zero &&
        state.selectedLeaveRuleId != null &&
        state.selectedAgent != null &&
        remarkToCheck.isNotEmpty;

    trickWith((s) => s.copyWith(isFormValid: isValid));
  }
}
