import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_editing_state.freezed.dart';

@freezed
sealed class ProfileEditingState with _$ProfileEditingState {
  const factory ProfileEditingState({
    @Default('') String companyCode,
    @Default('') String employeeId,
    @Default('') String password,
    @Default('') String companyAddress,
    @Default(false) bool isEditing,
    @Default(false) bool isPasswordVisible,
    @Default(false) bool isLoading,
    String? error,
  }) = _ProfileEditingState;
}
