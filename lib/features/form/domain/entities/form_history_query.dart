import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../presentation/screens/form_screen.dart'; // Import FormHistoryType

part 'form_history_query.freezed.dart';

@freezed
sealed class FormHistoryQuery with _$FormHistoryQuery {
  const factory FormHistoryQuery({
    required FormHistoryType historyType,
    DateTime? startDate,
    DateTime? endDate,
  }) = _FormHistoryQuery;
}
