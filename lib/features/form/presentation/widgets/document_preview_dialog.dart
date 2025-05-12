import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:joker_state/joker_state.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../domain/entities/download_state.dart';
import '../presenters/download_presenter.dart';

/// 文件預覽對話框，支援多種文件類型
class DocumentPreviewDialog extends StatelessWidget {
  final String fileUrl;
  final String fileName;

  const DocumentPreviewDialog({
    super.key,
    required this.fileUrl,
    required this.fileName,
  });

  /// 根據檔案名稱判斷檔案類型
  String _getFileType() {
    final extension = fileName.split('.').last.toLowerCase();

    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'bmp' || 'webp' => 'image',
      'pdf' => 'pdf',
      'doc' || 'docx' => 'word',
      'xls' || 'xlsx' || 'csv' => 'excel',
      'ppt' || 'pptx' => 'powerpoint',
      'txt' || 'rtf' || 'md' => 'text',
      _ => 'other',
    };
  }

  /// 根據檔案類型獲取對應的圖示
  IconData _getFileIcon() {
    final fileType = _getFileType();

    return switch (fileType) {
      'image' => Icons.image,
      'pdf' => Icons.picture_as_pdf,
      'word' => Icons.description,
      'excel' => Icons.table_chart,
      'powerpoint' => Icons.slideshow,
      'text' => Icons.article,
      _ => Icons.insert_drive_file,
    };
  }

  /// 根據檔案類型獲取對應的顏色
  Color _getFileColor(BuildContext context) {
    final fileType = _getFileType();
    final colorScheme = context.colorScheme;

    return switch (fileType) {
      'image' => Colors.blue,
      'pdf' => Colors.red,
      'word' => Colors.blue.shade800,
      'excel' => Colors.green.shade700,
      'powerpoint' => Colors.orange,
      'text' => colorScheme.primary,
      _ => colorScheme.secondary,
    };
  }

  /// 下載檔案到本地
  Future<void> _downloadFile(BuildContext context) async {
    // 關閉當前對話框
    context.pop();

    // 顯示下載進度對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _DownloadProgressDialog(fileName: fileName, fileUrl: fileUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final fileType = _getFileType();
    final fileIcon = _getFileIcon();
    final fileColor = _getFileColor(context);

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      contentPadding: EdgeInsets.all(context.i(24)),
      title: Row(
        children: [
          Icon(fileIcon, color: fileColor, size: context.r(28)),
          Gap(context.w(12)),
          Expanded(
            child: Text(
              '檔案預覽',
              style: context.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
              size: context.sp(22),
            ),
            onPressed: () => context.pop(),
            tooltip: '關閉預覽',
          ),
        ],
      ),
      content: SizedBox(
        width: context.vw * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(context.i(16)),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(context.r(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '檔案名稱',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gap(context.h(4)),
                  Text(
                    fileName,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Gap(context.h(16)),
                  Text(
                    '檔案類型',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Gap(context.h(4)),
                  Text(
                    fileType.toUpperCase(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: fileColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Gap(context.h(24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.download, size: context.sp(18)),
                  label: const Text('下載檔案'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fileColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(12),
                    ),
                  ),
                  onPressed: () => _downloadFile(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 檔案下載進度對話框
class _DownloadProgressDialog extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const _DownloadProgressDialog({
    required this.fileUrl,
    required this.fileName,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  late final DownloadPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = DownloadPresenter(
      fileUrl: widget.fileUrl,
      fileName: widget.fileName,
    );
    _presenter.startDownload();
  }

  @override
  void dispose() {
    _presenter.cancelDownload();
    super.dispose();
  }

  /// 開啟已下載的檔案
  Future<void> _openDownloadedFile() async {
    final success = await _presenter.openDownloadedFile(context);
    if (success && mounted) {
      context.pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('開啟檔案失敗'),
          backgroundColor: context.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      title: _presenter.perform(
        builder: (context, state) {
          return switch (state) {
            DownloadCompleted() => _buildTitleRow(
              context,
              isCompleted: true,
              hasError: false,
            ),
            DownloadError() => _buildTitleRow(
              context,
              isCompleted: false,
              hasError: true,
            ),
            _ => _buildTitleRow(context, isCompleted: false, hasError: false),
          };
        },
      ),
      content: SizedBox(
        width: context.vw * 0.8,
        child: _presenter.perform(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                switch (state) {
                  Download() => const SizedBox.shrink(),
                  Downloading(:final progress) => _buildDownloadingContent(
                    context,
                    progress,
                  ),
                  DownloadCompleted(:final filePath) => _buildCompletedContent(
                    context,
                    filePath,
                  ),
                  DownloadError(:final message) => _buildErrorContent(
                    context,
                    message,
                  ),
                },
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        _presenter.perform(
          builder: (context, state) {
            return switch (state) {
              DownloadError() => _buildActionButtons(
                context,
                onClose: () => context.pop(),
                onRetry: () => _presenter.retryDownload(),
                showRetry: true,
              ),
              DownloadCompleted() => _buildActionButtons(
                context,
                onClose: () => context.pop(),
                onOpen: _openDownloadedFile,
                showOpen: true,
              ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ],
    );
  }

  /// 建立標題列
  Widget _buildTitleRow(
    BuildContext context, {
    required bool isCompleted,
    required bool hasError,
  }) {
    final colorScheme = context.colorScheme;
    final iconColor =
        isCompleted
            ? Colors.green
            : hasError
            ? colorScheme.error
            : colorScheme.primary;
    final title =
        isCompleted
            ? '下載完成'
            : hasError
            ? '下載失敗'
            : '檔案下載中';
    final icon =
        isCompleted
            ? Icons.check_circle
            : hasError
            ? Icons.error
            : Icons.cloud_download_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(16),
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.r(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.r(8)),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: context.r(24)),
          ),
          Gap(context.w(12)),
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          if (!isCompleted && !hasError)
            IconButton(
              icon: Icon(Icons.close, size: context.r(20)),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
              onPressed: () {
                _presenter.cancelDownload();
                context.pop();
              },
              tooltip: '取消下載',
            ),
        ],
      ),
    );
  }

  /// 建立下載中內容
  Widget _buildDownloadingContent(BuildContext context, double progress) {
    final colorScheme = context.colorScheme;
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '正在下載檔案',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontSize: context.sp(14),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
                child: Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: context.sp(12),
                  ),
                ),
              ),
            ],
          ),
          Gap(context.h(16)),
          Stack(
            children: [
              Container(
                height: context.h(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(context.r(4)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: context.h(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(context.r(4)),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Gap(context.h(12)),
          Text(
            '正在下載中，請稍候...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: context.sp(12),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立下載完成內容
  Widget _buildCompletedContent(BuildContext context, String filePath) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.r(10)),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: context.r(32),
                ),
              ),
              Gap(context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '檔案已成功下載',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16),
                        color: Colors.green.shade800,
                      ),
                    ),
                    Gap(context.h(4)),
                    Text(
                      '您現在可以開啟或分享此檔案',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: context.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(context.h(16)),
          Text(
            '檔案資訊',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.sp(14),
              color: colorScheme.onSurface,
            ),
          ),
          Gap(context.h(8)),
          Container(
            padding: EdgeInsets.all(context.r(12)),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(context.r(8)),
              border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: context.r(16),
                      color: colorScheme.onSurfaceVariant,
                    ),
                    Gap(context.w(8)),
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: context.sp(13),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Gap(context.h(8)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.folder,
                      size: context.r(16),
                      color: colorScheme.onSurfaceVariant,
                    ),
                    Gap(context.w(8)),
                    Expanded(
                      child: Text(
                        filePath,
                        style: TextStyle(
                          fontSize: context.sp(12),
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立錯誤內容
  Widget _buildErrorContent(BuildContext context, String errorMessage) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.r(16)),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.r(12)),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.r(10)),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: context.r(32),
                ),
              ),
              Gap(context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '下載失敗',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16),
                        color: colorScheme.error,
                      ),
                    ),
                    Gap(context.h(4)),
                    Text(
                      '請嘗試重新下載或聯絡管理員',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: context.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(context.h(16)),
          Container(
            padding: EdgeInsets.all(context.r(12)),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(context.r(8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: context.r(18),
                  color: colorScheme.onErrorContainer,
                ),
                Gap(context.w(8)),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立操作按鈕
  Widget _buildActionButtons(
    BuildContext context, {
    required VoidCallback onClose,
    VoidCallback? onRetry,
    VoidCallback? onOpen,
    bool showRetry = false,
    bool showOpen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(onPressed: onClose, child: const Text('關閉')),
        Gap(context.w(8)),
        if (showRetry)
          ElevatedButton(onPressed: onRetry, child: const Text('重試'))
        else if (showOpen)
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('開啟檔案'),
            onPressed: onOpen,
          ),
      ],
    );
  }
}
