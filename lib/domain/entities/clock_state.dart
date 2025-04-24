import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/daily_clock_detail.dart';

part 'clock_state.freezed.dart';

@freezed
sealed class ClockState with _$ClockState {
  const factory ClockState.initial() = ClockInitial;
  const factory ClockState.loading() = ClockLoading;
  // Success state holding the punch details
  const factory ClockState.success(DailyClockDetail details) = ClockSuccess;
  // Failure state holding the error information
  const factory ClockState.failure(Failure failure) = ClockFailure;
}
