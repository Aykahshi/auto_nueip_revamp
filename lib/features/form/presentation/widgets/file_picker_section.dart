import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A widget section for picking and displaying files.
class FilePickerSection extends StatelessWidget {
  /// The list of currently selected files.
  final List<File> selectedFiles;

  /// Callback function triggered when the user wants to pick files.
  final VoidCallback onPickFiles;

  /// Callback function triggered when a selected file is removed.
  final ValueChanged<File> onRemoveFile;

  /// Creates a file picker section.
  const FilePickerSection({
    required this.selectedFiles,
    required this.onPickFiles,
    required this.onRemoveFile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(14)),
                  child: Icon(
                    Icons.attach_file_outlined,
                    size: context.r(20),
                    color: context.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    '附件 (${selectedFiles.length})', // Show file count
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontSize: context.sp(16),
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: context.r(18),
                  ),
                  label: const Text('選擇檔案'),
                  onPressed: onPickFiles,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(8),
                    ),
                    textStyle: TextStyle(fontSize: context.sp(14)),
                  ),
                ),
              ],
            ),
            // Display selected file names (optional)
            if (selectedFiles.isNotEmpty) ...[
              Wrap(
                // Use Wrap for multiple files
                spacing: context.w(8),
                runSpacing: context.h(4),
                children:
                    selectedFiles.map((file) {
                      final fileName = file.path.split('/').last;
                      return Chip(
                        label: Text(
                          fileName,
                          style: TextStyle(fontSize: context.sp(12)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () => onRemoveFile(file),
                        deleteIconColor: context
                            .colorScheme
                            .onSecondaryContainer
                            .withValues(alpha: 0.7),
                        backgroundColor: context.colorScheme.secondaryContainer
                            .withValues(alpha: 0.3),
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
              ),
            ],
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: context.r(20),
                    color: context.colorScheme.error,
                  ),
                  Gap(context.w(10)),
                  Center(
                    child: Text(
                      '目前僅支援圖片檔案\n需使用表單/文件請至網站申請',
                      style: context.textTheme.displaySmall?.copyWith(
                        fontSize: context.sp(14),
                        color: context.colorScheme.error,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 500.ms)
        .slideX(begin: -0.1); // Keep animation here
  }
}
