import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/holiday.dart';

part 'holiday_state.freezed.dart';

@freezed
sealed class HolidayState with _$HolidayState {
  // Initial state
  const factory HolidayState.initial() = HolidayInitial;

  // Loading state
  const factory HolidayState.loading() = HolidayLoading;

  // Success state holding the list of holidays
  const factory HolidayState.success(List<Holiday> holidays) = HolidaySuccess;

  // Error state holding the failure information
  const factory HolidayState.error(Failure failure) = HolidayError;
}
