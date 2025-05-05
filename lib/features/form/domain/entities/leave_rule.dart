import 'package:freezed_annotation/freezed_annotation.dart';

part 'leave_rule.freezed.dart';

/// Represents a leave rule.
@freezed
sealed class LeaveRule with _$LeaveRule {
  const factory LeaveRule({required String id, required String ruleName}) =
      _LeaveRule;
}
