import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
  final TextStyle? placeholderStyle; // Style for '--' or placeholder
  final int? maxLines; // Add maxLines parameter

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
    this.maxLines = 1, // Default to 1 line
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLabelStyle =
        labelStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: labelColor ?? colorScheme.onSurfaceVariant,
        );
    final effectiveValueStyle =
        valueStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: valueColor ?? colorScheme.onSurface,
        );
    final effectivePlaceholderStyle =
        placeholderStyle ??
        effectiveValueStyle?.copyWith(
          color: colorScheme.outline.withValues(alpha: 0.6),
        );
    final effectiveIconColor = iconColor ?? colorScheme.secondary;

    final bool isPlaceholder = value == '--' || value == 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment:
            maxLines == 1
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: effectiveIconColor),
          const Gap(8),
          Expanded(
            flex: 2, // Give label slightly less space if needed
            child: Text(
              label,
              style: effectiveLabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(8),
          Expanded(
            flex: 3, // Give value more space
            child: Text(
              value,
              style:
                  isPlaceholder
                      ? effectivePlaceholderStyle
                      : effectiveValueStyle,
              textAlign: TextAlign.left,
              maxLines: maxLines, // Use the maxLines parameter
              overflow:
                  maxLines == 1
                      ? TextOverflow.ellipsis
                      : null, // Apply ellipsis only if maxLines is 1
            ),
          ),
        ],
      ),
    );
  }
}
