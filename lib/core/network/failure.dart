import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Failure class for representing API errors and other failures.
/// Use this class to throw and handle API-related exceptions.
@freezed
sealed class Failure with _$Failure implements Exception {
  /// Constructor for Failure.
  const factory Failure({
    /// Error message describing the failure.
    required String message,

    /// Optional error code, such as HTTP status code.
    int? code,

    /// Optional details for debugging or logging.
    dynamic details,
  }) = _Failure;
}
