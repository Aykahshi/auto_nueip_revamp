import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';
import '../../data/models/notice.dart';

class NoticeListTile extends StatelessWidget {
  final Notice notice;

  const NoticeListTile({super.key, required this.notice});

  // Future<void> _launchURL(String url) async {
  //   final uri = Uri.parse(url);
  //   if (await canLaunchUrl(uri)) {
  //     await launchUrl(uri, mode: LaunchMode.externalApplication);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(notice.createdAt);
    return Card(
      elevation: 0.5,
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: InkWell(
        // onTap: () => _launchURL(notice.link),
        borderRadius: BorderRadius.circular(context.r(12)),
        child: Padding(
          padding: EdgeInsets.all(context.r(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notice.isReaded
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
                color:
                    notice.isReaded
                        ? context.colorScheme.outline
                        : context.colorScheme.primary,
                size: context.r(24),
              ),
              Gap(context.w(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.fullMessage,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            notice.isReaded
                                ? FontWeight.normal
                                : FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(context.h(8)),
                    Text(
                      timeAgo,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} 年前';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} 個月前';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} 天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} 小時前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} 分鐘前';
      } else {
        return '剛剛';
      }
    } catch (e) {
      return dateString;
    }
  }
}
