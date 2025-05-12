import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_state.freezed.dart';

/// 檔案下載狀態
@freezed
sealed class DownloadState with _$DownloadState {
  /// 初始狀態
  const factory DownloadState.initial() = Download;

  /// 下載中
  const factory DownloadState.downloading({required double progress}) =
      Downloading;

  /// 下載完成
  const factory DownloadState.completed({required String filePath}) =
      DownloadCompleted;

  /// 下載失敗
  const factory DownloadState.error({required String message}) = DownloadError;
}
