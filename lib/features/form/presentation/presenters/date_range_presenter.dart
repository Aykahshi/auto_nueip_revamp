import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../domain/entities/date_range_state.dart';

/// 用於管理日期範圍選擇的 Presenter
class DateRangePresenter extends Presenter<DateRangeState> {
  /// 建構子
  DateRangePresenter() : super(const DateRangeState());

  /// 設置自訂日期範圍
  void setDateRange(PickerDateRange? range) {
    if (range?.startDate == null) return;

    final startDate = DateUtils.dateOnly(range!.startDate!);
    final endDate =
        range.endDate != null ? DateUtils.dateOnly(range.endDate!) : startDate;

    trickWith(
      (s) => s.copyWith(tempStartDate: startDate, tempEndDate: endDate),
    );
  }

  /// 設置昨天日期範圍
  void setYesterday() {
    final state = DateRangeState.yesterday();
    trickWith((_) => state);
  }

  /// 設置今天日期範圍
  void setToday() {
    final state = DateRangeState.today();
    trickWith((_) => state);
  }

  /// 設置本週日期範圍
  void setThisWeek() {
    final state = DateRangeState.thisWeek();
    trickWith((_) => state);
  }

  /// 設置本月日期範圍
  void setThisMonth() {
    final state = DateRangeState.thisMonth();
    trickWith((_) => state);
  }

  /// 清除日期範圍
  void clearDateRange() {
    final state = DateRangeState.clear();
    trickWith((_) => state);
  }
}
