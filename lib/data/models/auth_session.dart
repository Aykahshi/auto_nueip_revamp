import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

@freezed
sealed class AuthSession with _$AuthSession {
  const AuthSession._();

  const factory AuthSession({
    final String? accessToken,
    final String? cookie,
    final String? csrfToken,
    final DateTime? expiryTime,
  }) = _AuthSession;

  bool isTokenExpired() {
    if (expiryTime == null) return true;
    return DateTime.now().isAfter(expiryTime!);
  }
}
