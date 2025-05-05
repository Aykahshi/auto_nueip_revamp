import 'package:freezed_annotation/freezed_annotation.dart';

part 'announcement.freezed.dart';
part 'announcement.g.dart';

@freezed
sealed class Announcement with _$Announcement {
  const factory Announcement({
    Content? content,
    int? isRead,
    DateTime? createdAt,
    String? fullMessage,
  }) = _Announcement;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);
}

@freezed
sealed class Content with _$Content {
  const factory Content({String? type, String? event}) = _Content;

  factory Content.fromJson(Map<String, dynamic> json) =>
      _$ContentFromJson(json);
}
