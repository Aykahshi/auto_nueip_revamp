import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

@freezed
sealed class AuthSession with _$AuthSession {
  const AuthSession._();

  const factory AuthSession({
    final String? accessToken,
    final String? cookie,
    final String? csrfToken,
  }) = _AuthSession;
}
