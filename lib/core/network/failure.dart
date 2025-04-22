import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';
part 'failure.g.dart';

/// Failure class for representing API errors and other failures.
/// Use this class to throw and handle API-related exceptions.
@freezed
sealed class Failure with _$Failure implements Exception {
  /// Constructor for Failure.
  const factory Failure({
    /// Error message describing the failure.
    required String message,

    /// Status type of the failure.
    required String status,

    /// Optional data for API response.
    dynamic errData,
  }) = _Failure;
}

/// Represents specific failures that can occur during the login process.
/// This class now represents login-specific errors independently.
@freezed
sealed class LoginFailure with _$LoginFailure implements Exception {
  const LoginFailure._();

  /// Specific failure for invalid company during login.
  const factory LoginFailure.invalidCompany({LoginErrors? errData}) =
      CompanyInvalid;

  /// Specific failure for non-existent user during login.
  const factory LoginFailure.userNotFound({LoginErrors? errData}) = UserInvalid;

  /// Specific failure for wrong password during login.
  const factory LoginFailure.wrongPassword({LoginErrors? errData}) =
      PasswordInvalid;

  /// Failure for unknown or network errors during the login process.
  const factory LoginFailure.unknown({
    dynamic errData, // Keep errData generic here for unexpected errors
  }) = UnknownLoginFailure;
}

@freezed
sealed class LoginErrors with _$LoginErrors {
  const factory LoginErrors({
    required String message,
    String? company,
    String? user,
    String? pwd,
  }) = _LoginErrors;

  factory LoginErrors.fromJson(Map<String, dynamic> json) =>
      _$LoginErrorsFromJson(json);
}
