import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:photo_view/photo_view.dart';

import '../../../../core/extensions/context_extension.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/utils/auth_utils.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final session = AuthUtils.getAuthSession();
    final colorScheme = context.colorScheme;

    // Create headers map
    final Map<String, String> httpHeaders = {
      'Cookie': session.cookie ?? '',
      'Authorization': 'Bearer ${session.accessToken}',
    };

    // Create the image provider with headers
    final imageProvider = CachedNetworkImageProvider(
      imageUrl,
      headers: httpHeaders,
    );

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(16)),
      ),
      contentPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.w(20),
        vertical: context.h(24),
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(context.r(16)),
        child: SizedBox(
          width: context.vw * 0.9,
          height: context.vh * 0.75,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PhotoView(
                imageProvider: imageProvider,
                tightMode: true,
                loadingBuilder:
                    (context, event) => Center(
                      child: SizedBox(
                        width: context.r(40), // Slightly larger indicator
                        height: context.r(40),
                        child: CircularProgressIndicator(
                          value:
                              event == null || event.expectedTotalBytes == null
                                  ? null
                                  : event.cumulativeBytesLoaded /
                                      event.expectedTotalBytes!,
                          strokeWidth: 3,
                          color: colorScheme.primary, // Use theme color
                        ),
                      ),
                    ),
                errorBuilder:
                    (context, error, stackTrace) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(
                          context.i(16),
                        ), // Add padding for error text
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize:
                              MainAxisSize
                                  .min, // Prevent column from expanding excessively
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: context.r(48),
                            ),
                            Gap(context.h(10)),
                            Text(
                              '圖片載入失敗',
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                backgroundDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ), // Match dialog bg
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
              ),
              // Close Button
              Positioned(
                top: context.h(8),
                right: context.w(8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ),
                  // Use theme color for icon
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                    size: context.r(22),
                  ),
                  onPressed: () => context.pop(),
                  tooltip: '關閉預覽',
                ),
              ),
            ],
          ),
        ),
      ),
      // No actions needed usually for image preview
      actions: const [],
      actionsPadding: EdgeInsets.zero,
    );
  }
}
