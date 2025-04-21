import 'package:equatable/equatable.dart';

/// Failure class for representing API errors and other failures.
/// Use this class to throw and handle API-related exceptions.
class Failure extends Equatable implements Exception {
  /// Error message describing the failure.
  final String message;

  /// Optional error code, such as HTTP status code.
  final int? code;

  /// Optional details for debugging or logging.
  final dynamic details;

  /// Constructor for Failure.
  const Failure({required this.message, this.code, this.details});

  @override
  String toString() =>
      'Failure(message: $message, code: $code, details: $details)';

  @override
  List<Object?> get props => [message, code, details];
}
