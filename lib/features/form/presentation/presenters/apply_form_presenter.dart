import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:joker_state/joker_state.dart';

import '../../../nueip/domain/repositories/nueip_repository.dart';
import '../../domain/entities/apply_form_state.dart';
import '../screens/form_screen.dart';

/// ApplyFormPresenter 負責處理申請表單的業務邏輯
class ApplyFormPresenter extends Presenter<ApplyFormState> {
  final NueipRepository _nueipRepository;

  /// 建構子
  ///
  /// [formType] - 表單類型
  /// [nueipRepository] - NueIP 資料庫操作
  ApplyFormPresenter({
    required FormHistoryType formType,
    required NueipRepository nueipRepository,
  }) : _nueipRepository = nueipRepository,
       // Initialize with the single state factory
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

    final employeeResult = await _nueipRepository.getEmployees().run();

    final leaveRuleResult = await _nueipRepository.getLeaveRules().run();

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

  /// 獲取工時資訊
  ///
  /// 用戶透過表單提供開始與結束日期時，呼叫此方法獲取實際工時
  /// [dates] - 日期列表，格式為 'YYYY-MM-DD'
  /// [employeeId] - 員工編號，預設為當前使用者
  void fetchWorkHours({required List<String> dates, String? employeeId}) {
    // 檢查初始資料是否已載入
    if (state.departmentEmployees.isEmpty || state.leaveRules.isEmpty) {
      // 可選擇顯示訊息或記錄初始資料尚未就緒
      debugPrint('初始資料尚未載入，無法獲取工時。');
      return;
    }

    // 更新狀態以指示工時正在載入
    trickWith((s) => s.copyWith(isLoadingWorkHours: true, hasError: false));

    _nueipRepository
        .getWorkHours(dates: dates, employeeId: employeeId ?? '')
        .run()
        .then((result) {
          result.fold(
            // 處理失敗
            (failure) => trickWith(
              (s) => s.copyWith(
                isLoadingWorkHours: false,
                hasError: true,
                errorMessage: '載入工時失敗: ${failure.message}',
                errorStatus: failure.status,
                workHours: {}, // 失敗時清空工時
              ),
            ),
            // 處理成功
            (workHoursList) {
              // 將 List<WorkHours> 轉換為 Map<String, WorkHours>
              final workHoursMap = {
                for (var workHour in workHoursList) workHour.date: workHour,
              };

              trickWith(
                (s) => s.copyWith(
                  isLoadingWorkHours: false,
                  hasError: false,
                  workHours: workHoursMap,
                  errorMessage: null,
                  errorStatus: null,
                ),
              );
            },
          );
        });
  }

  /// 根據表單選擇的日期範圍獲取工時資訊
  ///
  /// 此方法將開始日期和結束日期轉換為一系列日期，然後傳遞給 API 獲取工時
  /// [startDate] - 開始日期
  /// [endDate] - 結束日期
  /// [employeeId] - 可選的員工 ID
  void fetchWorkHoursByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) {
    // 檢查日期範圍是否有效
    if (startDate.isAfter(endDate)) {
      trickWith(
        (s) => s.copyWith(
          hasError: true,
          errorMessage: '日期範圍無效：開始日期不能晚於結束日期',
          errorStatus: 'invalid_date_range',
        ),
      );
      return;
    }

    // 生成日期範圍內的所有日期
    final dates = <String>[];
    var tempDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    // 日期格式化為 'YYYY-MM-DD'
    while (!tempDate.isAfter(endDateTime)) {
      dates.add(
        '${tempDate.year}-${tempDate.month.toString().padLeft(2, '0')}-${tempDate.day.toString().padLeft(2, '0')}',
      );
      tempDate = tempDate.add(const Duration(days: 1));
    }

    if (dates.isNotEmpty) {
      // 調用 API 獲取工時資訊
      fetchWorkHours(dates: dates, employeeId: employeeId);
    } else {
      // 處理日期列表為空的情況
      trickWith(
        (s) => s.copyWith(
          hasError: true,
          errorMessage: '無法產生有效的日期範圍',
          errorStatus: 'empty_date_range',
        ),
      );
    }
  }

  /// 提交請假表單
  ///
  /// [ruleId] - 假別規則 ID
  /// [startDate] - 開始日期 (格式: 'YYYY-MM-DD')
  /// [endDate] - 結束日期 (格式: 'YYYY-MM-DD')
  /// [startTime] - 開始時間 (格式: 'HH:MM')
  /// [endTime] - 結束時間 (格式: 'HH:MM')
  /// [hours] - 請假小時數
  /// [minutes] - 請假分鐘數
  /// [agentId] - 代理人 ID
  /// [remark] - 備註
  /// [files] - 附件檔案
  /// [cookie] - Cookie
  Future<void> submitLeaveForm({
    required String ruleId,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required int hours,
    required int minutes,
    required String agentId,
    required String remark,
    List<File>? files,
    required String cookie,
  }) async {
    // 更新狀態為提交中
    trickWith((s) => s.copyWith(isSubmitting: true, hasError: false));

    // 直接使用 repository 的 sendLeaveForm 方法
    final result =
        await _nueipRepository
            .sendLeaveForm(
              ruleId: ruleId,
              startDate: startDate,
              endDate: endDate,
              startTime: startTime,
              endTime: endTime,
              hours: hours,
              minutes: minutes,
              agentId: agentId,
              remark: remark,
              files: files,
              cookie: cookie,
            )
            .run();

    result.fold(
      // 處理失敗
      (failure) => trickWith(
        (s) => s.copyWith(
          isSubmitting: false,
          hasError: true,
          errorMessage: '提交請假表單失敗: ${failure.message}',
          errorStatus: failure.status,
        ),
      ),
      // 處理成功
      (response) => trickWith(
        (s) => s.copyWith(
          isSubmitting: false,
          hasError: false,
          errorMessage: null,
          errorStatus: null,
        ),
      ),
    );
  }
}
