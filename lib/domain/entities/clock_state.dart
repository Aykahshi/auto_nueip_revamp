import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/clock_action_enum.dart';
import '../../data/models/daily_clock_detail.dart';

part 'clock_state.freezed.dart';

@freezed
sealed class ClockState with _$ClockState {
  const factory ClockState({
    @Default(ClockActionStatus.idle) ClockActionStatus status,
    @Default(ClockTimeStatus.idle) ClockTimeStatus timeStatus,
    @Default(null) ClockAction? activeAction,
    @Default(null) DailyClockDetail? details,
    Failure? failure,
  }) = _ClockState;
}

enum ClockActionStatus { idle, loading, success, failure }

enum ClockTimeStatus { idle, loading, success, failure }
