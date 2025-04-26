import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/extensions/theme_extensions.dart';

/// A reusable row widget for displaying a piece of detail information with an icon.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? labelColor;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final TextStyle? placeholderStyle;
  final int? maxLines;

  const DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelColor,
    this.valueColor,
    this.valueStyle,
    this.labelStyle,
    this.placeholderStyle,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabelStyle =
        labelStyle ??
        context.textTheme.bodyMedium?.copyWith(
          color: labelColor ?? context.colorScheme.onSurfaceVariant,
          fontSize: context.sp(14),
        );
    final effectiveValueStyle =
        valueStyle ??
        context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: valueColor ?? context.colorScheme.onSurface,
          fontSize: context.sp(14),
        );
    final effectivePlaceholderStyle =
        placeholderStyle ??
        effectiveValueStyle?.copyWith(
          color: context.colorScheme.outline.withValues(alpha: 0.6),
        );
    final effectiveIconColor = iconColor ?? context.colorScheme.secondary;

    final bool isPlaceholder = value == '--' || value == 'N/A';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(4)),
      child: Row(
        crossAxisAlignment:
            maxLines == 1
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.r(18), color: effectiveIconColor),
          Gap(context.w(8)),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: effectiveLabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Gap(context.w(8)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style:
                  isPlaceholder
                      ? effectivePlaceholderStyle
                      : effectiveValueStyle,
              textAlign: TextAlign.left,
              maxLines: maxLines,
              overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }
}
