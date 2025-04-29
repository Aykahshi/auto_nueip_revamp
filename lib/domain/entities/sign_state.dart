import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/leave_sign_data.dart'; // Import LeaveSignData

part 'sign_state.freezed.dart';

@freezed
sealed class SignState with _$SignState {
  const factory SignState({
    @Default(false) bool isLoading,
    String? error,
    LeaveSignData? signData,
  }) = _SignState;

  // Factory for initial state
  factory SignState.initial() => const SignState();
}
