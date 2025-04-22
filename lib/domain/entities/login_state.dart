import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/network/failure.dart';
import '../../data/models/login_status_enum.dart';

part 'login_state.freezed.dart';

@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState({
    required LoginStatus status,
    final LoginErrors? errors,
  }) = _LoginState;
}
