import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice.freezed.dart';
part 'notice.g.dart';

@freezed
sealed class Notice with _$Notice {
  const Notice._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Notice({
    required int isRead,
    required String link,
    required String createdAt,
    required String fullMessage,
  }) = _Notice;

  bool get isReaded => isRead == 1;

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);
}
