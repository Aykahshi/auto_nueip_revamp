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

  /// 計算並設定請假時間
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

        // 檢查表單有效性
        validateForm();
      } else {
        trickWith(
          (s) => s.copyWith(
            calculatedDuration: Duration.zero,
            displayDuration: '0 小時 0 分鐘',
          ),
        );

        // 檢查表單有效性
        validateForm();
      }
    } else {
      trickWith(
        (s) => s.copyWith(calculatedDuration: null, displayDuration: '請選擇起始時間'),
      );
    }
  }

  /// 設置開始日期
  void setStartDate(DateTime? date) {
    if (date == null) return;

    final confirmedDate = DateUtils.dateOnly(date);
    final String displayDate = _dateFormatter.format(confirmedDate);

    // 如果結束日期在開始日期之前，清除結束日期
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

    calculateDuration();
  }

  /// 設置結束日期
  void setEndDate(DateTime? date) {
    if (date == null) return;

    final confirmedDate = DateUtils.dateOnly(date);
    final startDate = state.selectedStartDate;

    // 檢查結束日期是否在開始日期之前
    if (startDate != null && confirmedDate.isBefore(startDate)) {
      // 結束日期不能早於開始日期，不進行設定
      return;
    }

    final String displayDate = _dateFormatter.format(confirmedDate);

    trickWith(
      (s) => s.copyWith(
        selectedEndDate: confirmedDate,
        displayEndDate: displayDate,
      ),
    );

    calculateDuration();
  }

  /// 設置開始時間
  void setStartTime(TimeOfDay? time) {
    if (time == null) return;

    final String timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    trickWith(
      (s) => s.copyWith(selectedStartTime: time, displayStartTime: timeString),
    );

    calculateDuration();
  }

  /// 設置結束時間
  void setEndTime(TimeOfDay? time) {
    if (time == null) return;

    final String timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    trickWith(
      (s) => s.copyWith(selectedEndTime: time, displayEndTime: timeString),
    );

    calculateDuration();
  }

  /// 設置假別規則 ID
  void setLeaveRuleId(String? id) {
    trickWith((s) => s.copyWith(selectedLeaveRuleId: id));
    validateForm();
  }

  /// 設置代理人
  void setAgent(Employee? employee) {
    trickWith((s) => s.copyWith(selectedAgent: employee));
    validateForm();
  }

  /// 設置選擇的檔案
  void setFiles(List<File> files) {
    trickWith((s) => s.copyWith(selectedFiles: files));
  }

  /// 移除檔案
  void removeFile(File file) {
    final newFiles = [...state.selectedFiles]..remove(file);
    trickWith((s) => s.copyWith(selectedFiles: newFiles));
  }

  /// 格式化顯示時間
  String formatDuration(Duration? duration) {
    if (duration == null) return '請選擇起始時間';
    if (duration == Duration.zero) return '0 小時 0 分鐘';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours 小時 $minutes 分鐘';
  }

  /// 驗證表單是否有效
  void validateForm({String? remark}) {
    final isValid =
        state.selectedStartDate != null &&
        state.selectedStartTime != null &&
        state.selectedEndDate != null &&
        state.selectedEndTime != null &&
        state.calculatedDuration != null &&
        state.calculatedDuration! > Duration.zero &&
        state.selectedLeaveRuleId != null &&
        state.selectedAgent != null &&
        (remark?.isNotEmpty ?? false);

    trickWith((s) => s.copyWith(isFormValid: isValid));
  }
}
