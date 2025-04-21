import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart'; // For JSON serialization

@freezed
sealed class AuthSession with _$AuthSession {
  const AuthSession._(); // Private constructor for instance methods

  const factory AuthSession({String? accessToken, DateTime? expiryTime}) =
      _AuthSession;

  /// Factory constructor for creating a new AuthSession instance from a map.
  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);

  /// Instance method to check if the token is expired.
  bool isTokenExpired() {
    // Handle null expiryTime gracefully
    if (expiryTime == null) return true; // Assume expired if no expiry time
    return DateTime.now().isAfter(expiryTime!);
  }
}
