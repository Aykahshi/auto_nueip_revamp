import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/daily_clock_detail.dart';

part 'clock_state.freezed.dart';

@freezed
sealed class ClockState with _$ClockState {
  const factory ClockState({
    required ClockActionStatus status,
    required ClockTimeStatus timeStatus,
    DailyClockDetail? details,
    Failure? failure,
  }) = _ClockState;
}

enum ClockActionStatus { initial, loading, success, failure }

enum ClockTimeStatus { initial, loading, success, failure }
