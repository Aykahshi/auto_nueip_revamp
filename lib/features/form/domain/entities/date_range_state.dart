import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range_state.freezed.dart';

/// 用於管理日期範圍選擇的狀態
@freezed
sealed class DateRangeState with _$DateRangeState {
  const factory DateRangeState({
    DateTime? tempStartDate,
    DateTime? tempEndDate,
  }) = _DateRangeState;

  /// 工廠方法：建立昨天的日期範圍
  factory DateRangeState.yesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final normalizedDate = DateUtils.dateOnly(yesterday);
    return DateRangeState(
      tempStartDate: normalizedDate,
      tempEndDate: normalizedDate,
    );
  }

  /// 工廠方法：建立今天的日期範圍
  factory DateRangeState.today() {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateRangeState(tempStartDate: today, tempEndDate: today);
  }

  /// 工廠方法：建立本週的日期範圍
  factory DateRangeState.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = DateUtils.dateOnly(
      startOfWeek.add(const Duration(days: 6)),
    );
    return DateRangeState(
      tempStartDate: DateUtils.dateOnly(startOfWeek),
      tempEndDate: endOfWeek,
    );
  }

  /// 工廠方法：建立本月的日期範圍
  factory DateRangeState.thisMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return DateRangeState(
      tempStartDate: DateUtils.dateOnly(firstDay),
      tempEndDate: DateUtils.dateOnly(lastDay),
    );
  }

  /// 工廠方法：清除日期範圍
  factory DateRangeState.clear() {
    return const DateRangeState(tempStartDate: null, tempEndDate: null);
  }
}
