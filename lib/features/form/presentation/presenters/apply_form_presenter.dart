import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joker_state/joker_state.dart';

import '../../../nueip/data/repositories/nueip_repository_impl.dart';
import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../data/models/work_hour.dart';
import '../../domain/entities/apply_form_state.dart';
import '../screens/form_screen.dart';

/// ApplyFormPresenter 負責處理申請表單的業務邏輯
class ApplyFormPresenter extends Presenter<ApplyFormState> {
  final NueipRepository _repository;

  ApplyFormPresenter({required FormHistoryType formType})
    : _repository = Circus.find<NueipRepositoryImpl>(),
      super(ApplyFormState(formType: formType));

  @override
  void onReady() {
    super.onReady();
    fetchAllInitialData();
  }

  /// 並行獲取所有初始資料 (員工清單和假別規則)
  Future<void> fetchAllInitialData() async {
    // 更新狀態為載入中
    trickWith((s) => s.copyWith(isLoadingInitialData: true, hasError: false));

    final employeeResult = await _repository.getEmployees().run();

    final leaveRuleResult = await _repository.getLeaveRules().run();

    // 處理員工資料結果
    employeeResult.fold(
      (employeeFailure) => trickWith(
        (s) => s.copyWith(
          isLoadingInitialData: false,
          hasError: true,
          errorMessage: '載入員工清單失敗: ${employeeFailure.message}',
          errorStatus: employeeFailure.status,
        ),
      ),
      (departments) {
        // 處理假別規則結果
        leaveRuleResult.fold(
          (leaveRuleFailure) => trickWith(
            (s) => s.copyWith(
              isLoadingInitialData: false,
              hasError: true,
              errorMessage: '載入假別規則失敗: ${leaveRuleFailure.message}',
              errorStatus: leaveRuleFailure.status,
              // 即使假別規則載入失敗，仍保留部門資料
              departmentEmployees: departments,
            ),
          ),
          // 兩個請求都成功
          (leaveRules) => trickWith(
            (s) => s.copyWith(
              isLoadingInitialData: false,
              hasError: false,
              departmentEmployees: departments,
              leaveRules: leaveRules,
              errorMessage: null, // 清除先前的錯誤
              errorStatus: null,
            ),
          ),
        );
      },
    );
  }

  Future<void> submitLeaveForm({
    required String ruleId,
    required String startDate,
    required String endDate,
    required List<(String date, String start, String end, int hour, int min)> leaveEntries,
    required String agentId,
    required String remark,
    List<File>? files,
    required String cookie,
    VoidCallback? onSuccess,
    Function(String message)? onFailed,
  }) async {
    // 更新狀態為提交中
    trickWith((s) => s.copyWith(isSubmitting: true, hasError: false));

    // 直接使用 repository 的 sendLeaveForm 方法
    final result =
        await _repository
            .sendLeaveForm(
              ruleId: ruleId,
              startDate: startDate,
              endDate: endDate,
              leaveEntries: leaveEntries,
              agentId: agentId,
              remark: remark,
              files: files,
              cookie: cookie,
            )
            .run();

    result.fold(
      // 處理失敗
      (failure) {
        final errorMessage = '提交請假表單失敗: ${failure.message}';
        trickWith(
          (s) => s.copyWith(
            isSubmitting: false,
            hasError: true,
            errorMessage: errorMessage,
            errorStatus: failure.status,
          ),
        );
        // 呼叫失敗回調
        if (onFailed != null) {
          onFailed(errorMessage);
        }
      },
      // 處理成功
      (response) {
        trickWith(
          (s) => s.copyWith(
            isSubmitting: false,
            hasError: false,
            errorMessage: null,
            errorStatus: null,
          ),
        );
        // 呼叫成功回調
        if (onSuccess != null) {
          onSuccess();
        }
      },
    );
  }

  Future<void> cauculateWorkHour({
    required List<String> dates,
    required DateTime? startDateTime,
    required DateTime? endDateTime,
  }) async {
    // 更新狀態為載入中，並清除先前的錯誤訊息 (如果有的話)
    trickWith(
      (s) => s.copyWith(
        isLoadingWorkHours: true,
        hasError: false,
        errorMessage: null, // 清除可能與工時相關的舊錯誤
        errorStatus: null, // 清除舊的錯誤狀態
      ),
    );

    // 檢查日期列表是否為空，避免不必要的API調用
    if (dates.isEmpty || startDateTime == null || endDateTime == null) {
      trickWith(
        (s) => s.copyWith(
          isLoadingWorkHours: false,
          workHours: [], // 確保 workHours 是空列表
          totalWorkHoursDuration: Duration.zero, //總時長為0
        ),
      );
      return;
    }

    final result = await _repository.getWorkHour(dates: dates).run();

    result.fold(
      (failure) => trickWith(
        (s) => s.copyWith(
          isLoadingWorkHours: false,
          hasError: true,
          errorMessage: '載入工時數據失敗: ${failure.message}',
          errorStatus: failure.status,
          workHours: null, // 失敗時清除工時數據
          totalWorkHoursDuration: null, // 失敗時清除總時長
        ),
      ),
      (workHoursList) {
        // 如果 API 成功返回但列表為空 (例如，選定範圍內沒有工作日或排班)
        if (workHoursList.isEmpty) {
          trickWith(
            (s) => s.copyWith(
              isLoadingWorkHours: false,
              hasError: false, // 技術上沒有錯誤，但沒有數據
              // 可以選擇性地設定一個提示訊息，說明為何沒有工時數據
              errorMessage:
                  dates.length == 1 ? '此日期非工作日或無排班。' : '選定日期範圍內查無工作日或排班資料。',
              workHours: workHoursList, // workHours 仍為空列表
              totalWorkHoursDuration: Duration.zero, // 總時長為0
            ),
          );
          return;
        }

        // 計算總工時（考慮用戶選擇的時間區間和休息時間）
        final Duration calculatedTotalDuration = _calculateTotalWorkHours(
          workHoursList: workHoursList,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        );

        trickWith(
          (s) => s.copyWith(
            isLoadingWorkHours: false,
            hasError: false,
            workHours: workHoursList,
            totalWorkHoursDuration: calculatedTotalDuration, // 使用計算出的總時長
            errorMessage: null, // 成功載入，清除錯誤訊息
            errorStatus: null, // 成功載入，清除錯誤狀態
          ),
        );
      },
    );
  }

  /// Generates a list of leave entries for multiple days based on work hours data
  /// Each entry contains date, start time, end time, hours, and minutes
  List<(String date, String start, String end, int hour, int min)> generateLeaveEntries({
    required List<WorkHour> workHoursList,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) {
    final List<(String date, String start, String end, int hour, int min)> entries = [];
    final bool isSameDay =
        startDateTime.year == endDateTime.year &&
        startDateTime.month == endDateTime.month &&
        startDateTime.day == endDateTime.day;

    // Format for time display in form submission
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final workHour in workHoursList) {
      // Parse the work date
      final DateTime workDate = DateTime.parse('${workHour.date} 00:00:00');
      
      // Work start and end time for this day
      final workStartDateTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        int.parse(workHour.startHour),
        int.parse(workHour.startMinute),
      );

      final workEndDateTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        int.parse(workHour.endHour),
        int.parse(workHour.endMinute),
      );

      // Adjust effective start and end times based on user selection
      DateTime effectiveStartTime;
      DateTime effectiveEndTime;

      // If this is the first day, use the later of form start time and work start time
      if (workDate.year == startDateTime.year &&
          workDate.month == startDateTime.month &&
          workDate.day == startDateTime.day) {
        effectiveStartTime =
            startDateTime.isAfter(workStartDateTime)
                ? startDateTime
                : workStartDateTime;
      } else {
        effectiveStartTime = workStartDateTime;
      }

      // If this is the last day, use the earlier of form end time and work end time
      if (workDate.year == endDateTime.year &&
          workDate.month == endDateTime.month &&
          workDate.day == endDateTime.day) {
        effectiveEndTime =
            endDateTime.isBefore(workEndDateTime)
                ? endDateTime
                : workEndDateTime;
      } else {
        effectiveEndTime = workEndDateTime;
      }

      // Skip if end time is before start time
      if (effectiveEndTime.isBefore(effectiveStartTime)) {
        continue;
      }

      // Calculate basic duration for this day
      final basicDuration = effectiveEndTime.difference(effectiveStartTime);

      // Handle rest time
      Duration restToSubtract = Duration.zero;

      for (var restInterval in workHour.rest) {
        if (restInterval.length < 2) continue;

        // Parse rest start and end times
        final restStart = DateTime.tryParse(restInterval[0]);
        final restEnd = DateTime.tryParse(restInterval[1]);

        if (restStart == null || restEnd == null) continue;

        // Adjust for same day scenario
        if (isSameDay &&
            workDate.year == startDateTime.year &&
            workDate.month == startDateTime.month &&
            workDate.day == startDateTime.day) {
          // Case 1: If both start and end times are before rest start, don't subtract
          if (effectiveStartTime.isBefore(restStart) &&
              effectiveEndTime.isBefore(restStart)) {
            continue;
          }

          // Case 2: If both start and end times are after rest end, don't subtract
          if (effectiveStartTime.isAfter(restEnd) &&
              effectiveEndTime.isAfter(restEnd)) {
            continue;
          }
        }

        // Calculate overlap between rest time and effective work time
        DateTime overlapStart =
            effectiveStartTime.isAfter(restStart)
                ? effectiveStartTime
                : restStart;
        DateTime overlapEnd =
            effectiveEndTime.isBefore(restEnd) ? effectiveEndTime : restEnd;

        // If there's overlap, calculate and add rest time to subtract
        if (!overlapEnd.isBefore(overlapStart)) {
          restToSubtract += overlapEnd.difference(overlapStart);
        }
      }

      // Calculate actual duration after subtracting rest time
      final actualDuration =
          basicDuration > restToSubtract
              ? basicDuration - restToSubtract
              : Duration.zero;
      
      // Skip days with zero work hours
      if (actualDuration == Duration.zero) {
        continue;
      }
      
      // Create entry for this day
      final entry = (
        dateFormat.format(workDate),                     // date
        timeFormat.format(effectiveStartTime),           // start time
        timeFormat.format(effectiveEndTime),             // end time
        actualDuration.inHours,                          // hours
        actualDuration.inMinutes.remainder(60)           // minutes
      );
      
      entries.add(entry);
    }

    return entries;
  }

  /// 計算實際工時，考慮用戶選擇的時間區間與休息時間的關係
  Duration _calculateTotalWorkHours({
    required List<WorkHour> workHoursList,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) {
    Duration totalDuration = Duration.zero;
    final bool isSameDay =
        startDateTime.year == endDateTime.year &&
        startDateTime.month == endDateTime.month &&
        startDateTime.day == endDateTime.day;

    for (final workHour in workHoursList) {
      // 解析該天的日期
      final DateTime workDate = DateTime.parse('${workHour.date} 00:00:00');

      // 該天工作開始時間
      final workStartDateTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        int.parse(workHour.startHour),
        int.parse(workHour.startMinute),
      );

      // 該天工作結束時間
      final workEndDateTime = DateTime(
        workDate.year,
        workDate.month,
        workDate.day,
        int.parse(workHour.endHour),
        int.parse(workHour.endMinute),
      );

      // 根據表單選擇的時間，調整該天實際計算的開始和結束時間
      DateTime effectiveStartTime;
      DateTime effectiveEndTime;

      // 如果是第一天，使用表單開始時間和工作結束時間中較晚者作為開始
      if (workDate.year == startDateTime.year &&
          workDate.month == startDateTime.month &&
          workDate.day == startDateTime.day) {
        effectiveStartTime =
            startDateTime.isAfter(workStartDateTime)
                ? startDateTime
                : workStartDateTime;
      } else {
        effectiveStartTime = workStartDateTime;
      }

      // 如果是最後一天，使用表單結束時間和工作開始時間中較早者作為結束
      if (workDate.year == endDateTime.year &&
          workDate.month == endDateTime.month &&
          workDate.day == endDateTime.day) {
        effectiveEndTime =
            endDateTime.isBefore(workEndDateTime)
                ? endDateTime
                : workEndDateTime;
      } else {
        effectiveEndTime = workEndDateTime;
      }

      // 如果結束時間早於開始時間，則跳過
      if (effectiveEndTime.isBefore(effectiveStartTime)) {
        continue;
      }

      // 計算該天的基本工時
      final basicDuration = effectiveEndTime.difference(effectiveStartTime);

      // 處理休息時間
      Duration restToSubtract = Duration.zero;

      for (var restInterval in workHour.rest) {
        if (restInterval.length < 2) continue;

        // 解析休息時間的起止時間
        final restStart = DateTime.tryParse(restInterval[0]);
        final restEnd = DateTime.tryParse(restInterval[1]);

        if (restStart == null || restEnd == null) continue;

        // 調整 - 同一天的情況
        if (isSameDay &&
            workDate.year == startDateTime.year &&
            workDate.month == startDateTime.month &&
            workDate.day == startDateTime.day) {
          // 情況 1: 如果選擇的開始和結束時間都早於休息開始時間，則不扣除該休息時間
          if (effectiveStartTime.isBefore(restStart) &&
              effectiveEndTime.isBefore(restStart)) {
            continue;
          }

          // 情況 2: 如果選擇的開始和結束時間都晚於休息結束時間，則不扣除該休息時間
          if (effectiveStartTime.isAfter(restEnd) &&
              effectiveEndTime.isAfter(restEnd)) {
            continue;
          }
        }

        // 計算休息時間與有效工作時間的重疊部分
        DateTime overlapStart =
            effectiveStartTime.isAfter(restStart)
                ? effectiveStartTime
                : restStart;
        DateTime overlapEnd =
            effectiveEndTime.isBefore(restEnd) ? effectiveEndTime : restEnd;

        // 如果有重疊，計算並累加需要扣除的休息時間
        if (!overlapEnd.isBefore(overlapStart)) {
          restToSubtract += overlapEnd.difference(overlapStart);
        }
      }

      // 扣除休息時間後的實際工時
      final actualDuration =
          basicDuration > restToSubtract
              ? basicDuration - restToSubtract
              : Duration.zero;

      totalDuration += actualDuration;
    }

    return totalDuration;
  }

  // 日期時間選擇完成後觸發工時計算
  void onDateTimeSelectionComplete({
    required DateTime? startDate,
    required DateTime? endDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (startDate == null ||
        endDate == null ||
        startTime == null ||
        endTime == null) {
      trickWith(
        (s) => s.copyWith(
          workHours: null,
          totalWorkHoursDuration: null,
          isLoadingWorkHours: false,
          errorMessage: null,
          errorStatus: null,
        ),
      );
      return;
    }

    if (endDate.isBefore(startDate)) {
      trickWith(
        (s) => s.copyWith(
          isLoadingWorkHours: false,
          hasError: true,
          errorMessage: '結束日期不得早於開始日期。',
          workHours: null,
          totalWorkHoursDuration: null,
        ),
      );
      return;
    }

    // 創建包含日期和時間的完整 DateTime
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      trickWith(
        (s) => s.copyWith(
          isLoadingWorkHours: false,
          hasError: true,
          errorMessage: '結束時間不得早於開始時間。',
          workHours: null,
          totalWorkHoursDuration: null,
        ),
      );
      return;
    }

    final List<String> datesToFetch = [];
    DateTime currentDateIterator = startDate;
    while (!currentDateIterator.isAfter(endDate)) {
      datesToFetch.add(DateFormat('yyyy-MM-dd').format(currentDateIterator));
      if (datesToFetch.length > 366) {
        // Safety break for very large date ranges
        trickWith(
          (s) => s.copyWith(
            isLoadingWorkHours: false,
            hasError: true,
            errorMessage: '查詢日期範圍過大，請縮小範圍。',
            workHours: null,
            totalWorkHoursDuration: null,
          ),
        );
        return;
      }
      currentDateIterator = currentDateIterator.add(const Duration(days: 1));
    }

    if (datesToFetch.isNotEmpty) {
      cauculateWorkHour(
        dates: datesToFetch,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );
    } else {
      trickWith(
        (s) => s.copyWith(
          isLoadingWorkHours: false,
          workHours: [],
          totalWorkHoursDuration: Duration.zero,
        ),
      );
    }
  }
}
