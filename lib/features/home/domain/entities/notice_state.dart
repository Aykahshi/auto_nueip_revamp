import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/failure.dart';
import '../../data/models/notice.dart';

part 'notice_state.freezed.dart';

@freezed
sealed class NoticeState with _$NoticeState {
  const factory NoticeState({
    @Default([]) List<Notice> notices,
    @Default(false) bool isLoading,
    Failure? failure,
  }) = _NoticeState;

  factory NoticeState.initial() => const NoticeState(notices: []);
}
