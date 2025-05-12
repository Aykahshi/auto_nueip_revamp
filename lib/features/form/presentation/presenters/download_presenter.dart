import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/utils/auth_utils.dart';
import '../../domain/entities/download_state.dart';

/// 檔案下載 Presenter
class DownloadPresenter extends Presenter<DownloadState> {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;
  String? _savedFilePath;

  final String fileUrl;
  final String fileName;

  DownloadPresenter({required this.fileUrl, required this.fileName})
    : super(const DownloadState.initial());

  @override
  void onDone() {
    _cancelToken?.cancel('使用者取消下載');
    super.onDone();
  }

  /// 開始下載檔案
  Future<void> startDownload() async {
    trick(const DownloadState.downloading(progress: 0.0));
    _cancelToken = CancelToken();

    try {
      // 檢查儲存權限
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('需要儲存權限才能下載檔案');
      }

      // 取得下載目錄
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      // 建立檔案路徑
      final filePath = '${directory.path}/$fileName';

      // 取得認證資訊
      final session = AuthUtils.getAuthSession();
      final Map<String, String> headers = {
        HttpHeaders.cookieHeader: session.cookie ?? '',
        HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
      };

      // 確保 URL 是完整的
      String fullFileUrl = fileUrl;
      if (fileUrl.startsWith('/')) {
        fullFileUrl = '${ApiConfig.BASE_URL}$fileUrl';
      }

      // 開始下載
      await _dio.download(
        fullFileUrl,
        filePath,
        options: Options(headers: headers),
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            trick(DownloadState.downloading(progress: received / total));
          }
        },
      );

      _savedFilePath = filePath;
      trick(DownloadState.completed(filePath: filePath));
    } catch (e) {
      if (!(_cancelToken?.isCancelled ?? false)) {
        trick(
          DownloadState.error(
            message: e.toString().replaceAll('Exception: ', ''),
          ),
        );
        debugPrint('下載檔案失敗: $e');
      }
    }
  }

  /// 取消下載
  void cancelDownload() {
    _cancelToken?.cancel('使用者取消下載');
  }

  /// 重試下載
  void retryDownload() {
    startDownload();
  }

  /// 開啟已下載的檔案
  Future<bool> openDownloadedFile(BuildContext context) async {
    if (_savedFilePath == null) return false;

    try {
      final file = File(_savedFilePath!);
      if (await file.exists()) {
        // 直接使用 OpenFile 開啟檔案
        final result = await OpenFile.open(_savedFilePath!);

        // 檢查開啟結果
        if (result.type == ResultType.done) {
          return true;
        } else {
          debugPrint('開啟檔案失敗: ${result.message}');
          throw Exception(result.message);
        }
      } else {
        throw Exception('檔案不存在');
      }
    } catch (e) {
      debugPrint('開啟檔案失敗: $e');

      // 如果使用 OpenFile 失敗，嘗試使用 url_launcher
      try {
        final uri = Uri.file(_savedFilePath!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
      } catch (e2) {
        debugPrint('使用 url_launcher 開啟檔案也失敗: $e2');
      }

      return false;
    }
  }
}
