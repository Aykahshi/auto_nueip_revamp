import 'dart:async';
import 'dart:io';

import 'package:joker_state/joker_state.dart';

import '../../../nueip/data/repositories/nueip_repository_impl.dart';
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
  ApplyFormPresenter({required FormHistoryType formType})
    : _nueipRepository = Circus.find<NueipRepositoryImpl>(),
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
