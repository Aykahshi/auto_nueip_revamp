import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A reusable row widget for displaying a piece of detail information with an icon.
class DetailInfoRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final TextStyle? labelStyle;
  final String value;
  final TextStyle? valueStyle;
  final Color? labelColor;
  final Color? valueColor;
  final TextStyle? placeholderStyle;
  final int? maxLines;
  final bool useCompactFlex;
  final VoidCallback? onTap;
  final bool isLink;

  const DetailInfoRow({
    this.icon,
    this.iconColor,
    required this.label,
    this.labelStyle,
    required this.value,
    this.valueStyle,
    this.labelColor,
    this.valueColor,
    this.placeholderStyle,
    this.maxLines = 1,
    this.useCompactFlex = false,
    this.onTap,
    this.isLink = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.colorScheme.secondary;
    final effectiveLabelStyle =
        labelStyle ??
        context.textTheme.labelMedium?.copyWith(
          color: labelColor ?? context.colorScheme.outline,
          fontSize: context.sp(13),
        );
    final baseValueColor = valueColor ?? context.colorScheme.onSurface;
    final effectiveValueStyle =
        valueStyle ??
        context.textTheme.bodyMedium?.copyWith(
          fontSize: context.sp(14),
          decoration: isLink ? TextDecoration.underline : null,
          decorationColor: isLink ? context.colorScheme.primary : null,
          color: isLink ? context.colorScheme.primary : baseValueColor,
        );
    final effectivePlaceholderStyle =
        placeholderStyle ??
        context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.outline.withValues(alpha: 0.7),
          fontSize: context.sp(14),
        );

    final bool isPlaceholder = value == '--' || value == 'N/A';

    Widget rowContent = Row(
      crossAxisAlignment:
          maxLines == 1 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Icon(icon!, size: context.r(18), color: effectiveIconColor),
        if (icon != null) Gap(context.w(8)),
        Expanded(
          flex: useCompactFlex ? 1 : 2,
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
                isPlaceholder ? effectivePlaceholderStyle : effectiveValueStyle,
            textAlign: TextAlign.left,
            maxLines: maxLines,
            overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
          ),
        ),
        if (isLink && onTap != null)
          Padding(
            padding: EdgeInsets.only(left: context.w(8)),
            child: Icon(
              Icons.open_in_new,
              size: context.r(16),
              color: context.colorScheme.primary,
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.r(4)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(4)),
          child: rowContent,
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(4)),
        child: rowContent,
      );
    }
  }
}
