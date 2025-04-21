import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String? accessToken;
  final DateTime? expiryTime;

  const AuthSession({this.accessToken, this.expiryTime});

  bool isTokenExpired() {
    return DateTime.now().isAfter(expiryTime!);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiryTime': expiryTime?.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      expiryTime: DateTime.parse(json['expiryTime']),
    );
  }

  @override
  List<Object?> get props => [accessToken, expiryTime];
}
